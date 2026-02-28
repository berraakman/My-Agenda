//
//  CalendarService.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation
import EventKit

// MARK: - CalendarService
/// Apple Calendar (EventKit) entegrasyon servisi.
/// Takvim izni isteme, etkinlik okuma/yazma ve görev-takvim senkronizasyonu sağlar.
@Observable
final class CalendarService {
    
    // MARK: - Properties
    
    /// EventKit store (takvim veritabanı erişimi)
    private let eventStore = EKEventStore()
    
    /// Takvim erişim izni durumu
    var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    /// Mevcut takvim etkinlikleri
    var events: [EKEvent] = []
    
    /// Hata mesajı
    var errorMessage: String?
    
    /// Yükleniyor mu?
    var isLoading = false
    
    // MARK: - Init
    
    init() {
        updateAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Mevcut izin durumunu günceller
    func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    /// Takvim erişim izni ister (macOS 14+ için FullAccess, daha eskiyse Event)
    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            #if os(macOS)
            if #available(macOS 14.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            #else
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            #endif
            await MainActor.run {
                updateAuthorizationStatus()
            }
            return granted
        } catch {
            await MainActor.run {
                errorMessage = "Takvim izni alınamadı: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    /// İzin verilmiş mi?
    var isAuthorized: Bool {
        #if os(macOS)
        if #available(macOS 14.0, *) {
            return authorizationStatus == .fullAccess || authorizationStatus == .authorized
        } else {
            return authorizationStatus == .authorized
        }
        #else
        if #available(iOS 17.0, *) {
            return authorizationStatus == .fullAccess || authorizationStatus == .writeOnly
        } else {
            return authorizationStatus == .authorized
        }
        #endif
    }
    
    // MARK: - Read Events
    
    /// Belirli tarih aralığındaki etkinlikleri getirir
    func fetchEvents(from startDate: Date, to endDate: Date) {
        guard isAuthorized else {
            errorMessage = "Takvim erişim izni gerekli."
            return
        }
        
        isLoading = true
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )
        
        let fetchedEvents = eventStore.events(matching: predicate)
        
        // Ana thread'de güncelle
        events = fetchedEvents.sorted { $0.startDate < $1.startDate }
        isLoading = false
    }
    
    /// Bu haftanın etkinliklerini getirir
    func fetchThisWeekEvents() {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) ?? now
        
        fetchEvents(from: startOfWeek, to: endOfWeek)
    }
    
    /// Bu ayın etkinliklerini getirir
    func fetchThisMonthEvents() {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? now
        
        fetchEvents(from: startOfMonth, to: endOfMonth)
    }
    
    // MARK: - Create Event
    
    /// Yeni bir takvim etkinliği oluşturur
    /// - Returns: Oluşturulan etkinliğin identifier'ı, hata durumunda nil
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date? = nil,
        notes: String? = nil,
        isAllDay: Bool = false,
        recurrenceRule: EKRecurrenceRule? = nil
    ) -> String? {
        guard isAuthorized else {
            errorMessage = "Takvim erişim izni gerekli."
            return nil
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate ?? startDate.addingTimeInterval(3600) // Varsayılan 1 saat
        event.notes = notes
        event.isAllDay = isAllDay
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        if let rule = recurrenceRule {
            event.recurrenceRules = [rule]
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            errorMessage = "Etkinlik oluşturulamadı: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// Bir AgendaTask'ı Apple Calendar etkinliğine dönüştürür
    func createEventFromTask(_ task: AgendaTask) -> String? {
        guard let dueDate = task.combinedDueDateTime ?? task.dueDate else {
            errorMessage = "Görevin bir son tarihi olmalı."
            return nil
        }
        
        let notes = task.taskDescription.isEmpty ? nil : task.taskDescription
        
        var recurrenceRule: EKRecurrenceRule? = nil
        if task.isRecurring, let type = task.recurrenceType {
            let frequency: EKRecurrenceFrequency
            var daysOfTheWeek: [EKRecurrenceDayOfWeek]? = nil
            
            switch type {
            case .daily: frequency = .daily
            case .weekly: frequency = .weekly
            case .monthly: frequency = .monthly
            case .customDays:
                frequency = .weekly
                if let customDays = task.recurringDaysOfWeek, !customDays.isEmpty {
                    daysOfTheWeek = customDays.compactMap { dayInt in
                        if let weekday = EKWeekday(rawValue: dayInt) {
                            return EKRecurrenceDayOfWeek(weekday)
                        }
                        return nil
                    }
                }
            }
            
            recurrenceRule = EKRecurrenceRule(
                recurrenceWith: frequency,
                interval: 1,
                daysOfTheWeek: daysOfTheWeek,
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: nil
            )
        }
        
        // Eğer zaten takvimde varsa güncellemek için eskisini sil
        if let existingId = task.calendarEventId {
            _ = deleteEvent(withIdentifier: existingId)
            task.calendarEventId = nil
        }
        
        let eventId = createEvent(
            title: "📋 \(task.title)",
            startDate: dueDate,
            endDate: dueDate.addingTimeInterval(3600),
            notes: notes,
            isAllDay: task.dueTime == nil,
            recurrenceRule: recurrenceRule
        )
        
        if let eventId = eventId {
            task.calendarEventId = eventId
        }
        
        return eventId
    }
    
    // MARK: - Delete Event
    
    /// Takvimden etkinlik siler
    func deleteEvent(withIdentifier identifier: String) -> Bool {
        guard isAuthorized else { return false }
        
        guard let event = eventStore.event(withIdentifier: identifier) else {
            errorMessage = "Etkinlik bulunamadı."
            return false
        }
        
        do {
            try eventStore.remove(event, span: .futureEvents)
            return true
        } catch {
            errorMessage = "Etkinlik silinemedi: \(error.localizedDescription)"
            return false
        }
    }
}

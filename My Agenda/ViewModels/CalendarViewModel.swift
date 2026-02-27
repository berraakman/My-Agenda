//
//  CalendarViewModel.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation
import EventKit

// MARK: - CalendarViewModel
/// Takvim ekranı için iş mantığı katmanı.
/// CalendarService ile iletişim kurar, UI state'ini yönetir.
@Observable
final class CalendarViewModel {
    
    // MARK: - Properties
    
    private let calendarService: CalendarService
    
    /// Görüntüleme aralığı
    var selectedRange: CalendarRange = .thisWeek
    
    /// Seçili tarih
    var selectedDate: Date = Date()
    
    // MARK: - Init
    
    init(calendarService: CalendarService) {
        self.calendarService = calendarService
    }
    
    // MARK: - Computed
    
    var events: [EKEvent] { calendarService.events }
    var isAuthorized: Bool { calendarService.isAuthorized }
    var isLoading: Bool { calendarService.isLoading }
    var errorMessage: String? { calendarService.errorMessage }
    
    /// Seçili tarihteki etkinlikler
    var eventsForSelectedDate: [EKEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: selectedDate)
        }
    }
    
    // MARK: - Actions
    
    func requestAccess() async {
        _ = await calendarService.requestAccess()
        loadEvents()
    }
    
    func loadEvents() {
        switch selectedRange {
        case .thisWeek:
            calendarService.fetchThisWeekEvents()
        case .thisMonth:
            calendarService.fetchThisMonthEvents()
        case .custom:
            let endDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
            calendarService.fetchEvents(from: selectedDate, to: endDate)
        }
    }
    
    func addTaskToCalendar(_ task: AgendaTask) -> Bool {
        return calendarService.createEventFromTask(task) != nil
    }
}

// MARK: - CalendarRange

enum CalendarRange: String, CaseIterable, Identifiable {
    case thisWeek = "Bu Hafta"
    case thisMonth = "Bu Ay"
    case custom = "Özel"
    
    var id: String { rawValue }
}

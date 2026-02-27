//
//  AgendaTask.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation
import SwiftData

// MARK: - AgendaTask Model
/// Uygulamadaki tek bir görevi temsil eder.
/// Her görev bir Dashboard'a ait olabilir (opsiyonel).
/// Öncelik, son tarih, tekrarlama ve Apple Calendar entegrasyonunu destekler.
@Model
final class AgendaTask {
    
    // MARK: - Core Properties
    
    /// Benzersiz kimlik
    var id: UUID
    
    /// Görev başlığı
    var title: String
    
    /// Görev açıklaması (detaylı not alanı)
    var taskDescription: String
    
    /// Görev öncelik seviyesi
    var priority: Priority
    
    /// Tamamlanma durumu
    var isCompleted: Bool
    
    /// Oluşturulma tarihi
    var createdAt: Date
    
    /// Tamamlanma tarihi (tamamlandığında set edilir)
    var completedAt: Date?
    
    // MARK: - Date & Time
    
    /// Son tarih (görevin yapılması gereken tarih)
    var dueDate: Date?
    
    /// Saat bilgisi (görevin yapılması gereken saat)
    /// dueDate ile birlikte kullanılır.
    var dueTime: Date?
    
    // MARK: - Recurrence (Tekrarlama)
    
    /// Tekrarlayan görev mi?
    var isRecurring: Bool
    
    /// Tekrarlama tipi (günlük / haftalık / aylık)
    /// Sadece isRecurring == true ise anlamlıdır.
    var recurrenceType: RecurrenceType?
    
    // MARK: - Calendar Integration
    
    /// Apple Calendar'daki etkinlik ID'si.
    /// Görev takvime eklendiyse bu değer dolu olur.
    /// CalendarService ile senkronizasyon için kullanılır.
    var calendarEventId: String?
    
    // MARK: - Relationships
    
    /// Görevin ait olduğu dashboard.
    /// nil ise görev herhangi bir dashboard'a atanmamış demektir.
    var dashboard: Dashboard?
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String = "",
        priority: Priority = .medium,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        dueTime: Date? = nil,
        isRecurring: Bool = false,
        recurrenceType: RecurrenceType? = nil,
        calendarEventId: String? = nil,
        dashboard: Dashboard? = nil
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.priority = priority
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.dueTime = dueTime
        self.isRecurring = isRecurring
        self.recurrenceType = recurrenceType
        self.calendarEventId = calendarEventId
        self.dashboard = dashboard
    }
    
    // MARK: - Computed Properties
    
    /// Görevin süresi geçmiş mi?
    /// Tamamlanmamış ve dueDate geçmişte ise true döner.
    var isOverdue: Bool {
        guard !isCompleted, let dueDate = dueDate else { return false }
        return dueDate < Date()
    }
    
    /// Görev bugün mü bitiyor?
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    /// Görev bu hafta mı bitiyor?
    var isDueThisWeek: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDate(dueDate, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// Son tarihe kalan gün sayısı.
    /// Negatif ise süre geçmiştir.
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: dueDate))
        return components.day
    }
    
    /// Birleştirilmiş tarih ve saat bilgisi.
    /// dueDate ve dueTime varsa ikisini birleştirir.
    var combinedDueDateTime: Date? {
        guard let dueDate = dueDate else { return nil }
        guard let dueTime = dueTime else { return dueDate }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: dueTime)
        
        return calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: dueDate
        )
    }
    
    // MARK: - Methods
    
    /// Görevi tamamlandı olarak işaretler ve tamamlanma tarihini set eder.
    func markAsCompleted() {
        isCompleted = true
        completedAt = Date()
    }
    
    /// Görevi tamamlanmadı olarak geri alır.
    func markAsIncomplete() {
        isCompleted = false
        completedAt = nil
    }
    
    /// Tamamlanma durumunu tersine çevirir (toggle).
    func toggleCompletion() {
        if isCompleted {
            markAsIncomplete()
        } else {
            markAsCompleted()
        }
    }
}

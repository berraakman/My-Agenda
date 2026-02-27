//
//  NotificationService.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation
import UserNotifications

// MARK: - NotificationService
/// macOS bildirim servisi.
/// Görev son tarihi yaklaştığında kullanıcıya bildirim gönderir.
/// UserNotifications framework kullanır.
@Observable
final class NotificationService {
    
    // MARK: - Properties
    
    /// Bildirim izni durumu
    var isAuthorized = false
    
    /// Hata mesajı
    var errorMessage: String?
    
    // MARK: - Init
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Mevcut bildirim izni durumunu kontrol eder
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Bildirim izni ister
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            await MainActor.run {
                errorMessage = "Bildirim izni alınamadı: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Schedule Notification
    
    /// Bir görev için bildirim planlar.
    /// Son tarihten belirlenen süre (varsayılan 1 saat) önce bildirim gönderilir.
    func scheduleNotification(for task: AgendaTask) {
        guard isAuthorized else {
            errorMessage = "Bildirim izni gerekli."
            return
        }
        
        guard let dueDate = task.combinedDueDateTime ?? task.dueDate else {
            return
        }
        
        // Mevcut bildirimi iptal et (varsa)
        cancelNotification(for: task)
        
        // Bildirim tarihini hesapla (1 saat önce)
        let notificationDate = dueDate.addingTimeInterval(
            TimeInterval(-AppConstants.notificationHoursBefore * 3600)
        )
        
        // Geçmişteki tarihlere bildirim planlanmaz
        guard notificationDate > Date() else { return }
        
        // Bildirim içeriği
        let content = UNMutableNotificationContent()
        content.title = "⏰ Görev Hatırlatması"
        content.body = "\"\(task.title)\" görevi \(AppConstants.notificationHoursBefore) saat içinde sona erecek."
        content.sound = .default
        content.categoryIdentifier = AppConstants.notificationCategoryId
        
        // Önceliğe göre subtitle
        switch task.priority {
        case .high:
            content.subtitle = "🔴 Yüksek Öncelikli"
        case .medium:
            content.subtitle = "🟠 Orta Öncelikli"
        case .low:
            content.subtitle = "🟢 Düşük Öncelikli"
        }
        
        // Dashboard bilgisi (varsa)
        if let dashboard = task.dashboard {
            content.body += "\n📂 \(dashboard.name)"
        }
        
        // Tetikleyici (trigger)
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // İstek
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: task),
            content: content,
            trigger: trigger
        )
        
        // Planla
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Bildirim planlanamadı: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Bir görev için planlanmış bildirimi iptal eder
    func cancelNotification(for task: AgendaTask) {
        let identifier = notificationIdentifier(for: task)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }
    
    /// Tüm planlanmış bildirimleri iptal eder
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// Planlanmış bildirim sayısını döner
    func pendingNotificationCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.count
    }
    
    // MARK: - Private
    
    /// Görev için benzersiz bildirim identifier'ı oluşturur
    private func notificationIdentifier(for task: AgendaTask) -> String {
        "task_reminder_\(task.id.uuidString)"
    }
}

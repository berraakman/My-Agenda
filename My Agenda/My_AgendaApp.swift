//
//  My_AgendaApp.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import SwiftData

// MARK: - App Entry Point
/// Uygulamanın giriş noktası.
/// SwiftData container'ı, CalendarService ve NotificationService burada oluşturulur
/// ve tüm view hiyerarşisine enjekte edilir (Dependency Injection).
@main
struct My_AgendaApp: App {
    
    // MARK: - Services (Dependency Injection)
    
    /// Apple Calendar entegrasyon servisi
    @State private var calendarService = CalendarService()
    
    /// macOS bildirim servisi
    @State private var notificationService = NotificationService()
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            MainView()
                // Servisleri tüm view hiyerarşisine enjekte et
                .environment(calendarService)
                .environment(notificationService)
                .environment(\.locale, Locale(identifier: "en_GB"))
                .onAppear {
                    setupNotifications()
                }
        }
        // MARK: - SwiftData Container
        // Dashboard ve AgendaTask modellerini register eder.
        // Veriler otomatik olarak disk'e kalıcı olarak kaydedilir.
        .modelContainer(for: [
            Dashboard.self,
            AgendaTask.self,
            DashboardFolder.self
        ])
        // MARK: - Window Settings
        .defaultSize(
            width: AppConstants.minWindowWidth,
            height: AppConstants.minWindowHeight
        )
        .windowResizability(.contentMinSize)
    }
    
    // MARK: - Setup
    
    /// Uygulama açılışında bildirim izni ister
    private func setupNotifications() {
        Task {
            _ = await notificationService.requestAuthorization()
        }
    }
}

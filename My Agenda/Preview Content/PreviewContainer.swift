//
//  PreviewContainer.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation
import SwiftData

// MARK: - Preview Container
/// SwiftUI Preview'lar için örnek veri içeren in-memory ModelContainer.
/// Preview'larda `@Query` çalışabilmesi için gereklidir.
struct PreviewContainer {
    
    /// Örnek verilerle dolu in-memory container
    @MainActor
    static var sample: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Dashboard.self, AgendaTask.self,
            configurations: config
        )
        
        // Örnek dashboard'lar
        let teknofest = Dashboard(name: "Teknofest", icon: "trophy.fill", colorHex: "#FF9500", sortIndex: 0)
        let university = Dashboard(name: "Üniversite", icon: "graduationcap.fill", colorHex: "#007AFF", sortIndex: 1)
        let personal = Dashboard(name: "Kişisel", icon: "heart.fill", colorHex: "#34C759", sortIndex: 2)
        
        container.mainContext.insert(teknofest)
        container.mainContext.insert(university)
        container.mainContext.insert(personal)
        
        // Örnek görevler — Teknofest
        let t1 = AgendaTask(title: "Sunum hazırla", taskDescription: "Yarışma sunumunu tamamla", priority: .high, dueDate: Date().addingTimeInterval(86400 * 2), dashboard: teknofest)
        let t2 = AgendaTask(title: "Prototip testi", priority: .medium, dueDate: Date().addingTimeInterval(86400 * 5), dashboard: teknofest)
        let t3 = AgendaTask(title: "Rapor yaz", priority: .low, isCompleted: true, completedAt: Date().addingTimeInterval(-86400), dashboard: teknofest)
        
        // Örnek görevler — Üniversite
        let t4 = AgendaTask(title: "Ödev teslimi", priority: .high, dueDate: Date().addingTimeInterval(-86400), dashboard: university) // Gecikmiş
        let t5 = AgendaTask(title: "Ders notu çalış", priority: .medium, dueDate: Date(), dashboard: university) // Bugün
        
        // Örnek görevler — Kişisel
        let t6 = AgendaTask(title: "Spor", priority: .low, isRecurring: true, recurrenceType: .daily, dashboard: personal)
        
        [t1, t2, t3, t4, t5, t6].forEach { container.mainContext.insert($0) }
        
        return container
    }
}

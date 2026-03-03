//
//  Dashboard.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation
import SwiftData

// MARK: - Dashboard Model
/// Dashboard, görevleri gruplamak için kullanılan ana kategori modelidir.
/// Kullanıcı istediği kadar dashboard oluşturabilir (örn: "Teknofest", "Üniversite", "Kişisel").
/// Her dashboard'un adı, ikonu ve rengi kullanıcı tarafından belirlenebilir ve düzenlenebilir.
@Model
final class Dashboard {
    
    // MARK: - Properties
    
    /// Benzersiz kimlik
    var id: UUID
    
    /// Dashboard başlığı — kullanıcı tarafından girilebilir ve düzenlenebilir
    var name: String
    
    /// SF Symbol ikon adı (örn: "folder.fill", "book.fill")
    var icon: String
    
    /// Dashboard tema rengi (hex formatında, örn: "#FF5733")
    var colorHex: String
    
    /// Oluşturulma tarihi
    var createdAt: Date
    
    /// Sıralama indeksi — sidebar'da özel sıralama için
    var sortIndex: Int
    
    // MARK: - Relationships
    
    /// Bu dashboard'a ait görevler.
    /// Dashboard silindiğinde tüm görevler de silinir (cascade).
    @Relationship(deleteRule: .cascade, inverse: \AgendaTask.dashboard)
    var tasks: [AgendaTask]
    
    /// Bu dashboard'a ait klasörler.
    /// Dashboard silindiğinde tüm klasörler de silinir (cascade).
    @Relationship(deleteRule: .cascade, inverse: \DashboardFolder.dashboard)
    var folders: [DashboardFolder] = []
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder.fill",
        colorHex: String = "#007AFF",
        createdAt: Date = Date(),
        sortIndex: Int = 0,
        tasks: [AgendaTask] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.sortIndex = sortIndex
        self.tasks = tasks
    }
    
    // MARK: - Computed Properties
    
    /// Toplam görev sayısı
    var totalTaskCount: Int {
        tasks.count
    }
    
    /// Tamamlanan görev sayısı
    var completedTaskCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    /// Tamamlanma yüzdesi (0.0 – 1.0 arası)
    /// Görev yoksa 0 döner.
    var completionPercentage: Double {
        guard totalTaskCount > 0 else { return 0.0 }
        return Double(completedTaskCount) / Double(totalTaskCount)
    }
    
    /// Bekleyen (tamamlanmamış) görev sayısı
    var pendingTaskCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }
    
    /// Süresi geçmiş görev sayısı
    var overdueTaskCount: Int {
        let now = Date()
        return tasks.filter { task in
            !task.isCompleted &&
            task.dueDate != nil &&
            task.dueDate! < now
        }.count
    }
}

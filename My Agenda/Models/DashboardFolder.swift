//
//  DashboardFolder.swift
//  My Agenda
//
//  Created by Berra Akman on 01.03.2026.
//

import Foundation
import SwiftData

// MARK: - DashboardFolder Model
/// Dashboard içindeki görevleri gruplamak için kullanılan klasör modelidir.
/// Örneğin "Okul" dashboard'unda "Matematik", "Fizik", "Türkçe" klasörleri olabilir.
/// Her klasör bir dashboard'a aittir ve içinde birden fazla görev barındırabilir.
@Model
final class DashboardFolder {
    
    // MARK: - Properties
    
    /// Benzersiz kimlik
    var id: UUID
    
    /// Klasör adı — kullanıcı tarafından girilebilir ve düzenlenebilir
    var name: String
    
    /// SF Symbol ikon adı (örn: "folder.fill", "book.fill")
    var icon: String
    
    /// Klasör rengi (hex formatında) — Dashboard renginden bağımsız olabilir
    var colorHex: String
    
    /// Sıralama indeksi — dashboard içinde klasör sıralaması
    var sortIndex: Int = 0
    
    /// Oluşturulma tarihi
    var createdAt: Date
    
    // MARK: - Relationships
    
    /// Bu klasörün ait olduğu dashboard
    var dashboard: Dashboard?
    
    /// Bu klasöre ait görevler
    @Relationship(deleteRule: .nullify, inverse: \AgendaTask.folder)
    var tasks: [AgendaTask] = []
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder.fill",
        colorHex: String = "#007AFF",
        sortIndex: Int = 0,
        createdAt: Date = Date(),
        dashboard: Dashboard? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.dashboard = dashboard
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
    
    /// Bekleyen görev sayısı
    var pendingTaskCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }
    
    /// Tamamlanma yüzdesi (0.0 – 1.0)
    var completionPercentage: Double {
        guard totalTaskCount > 0 else { return 0.0 }
        return Double(completedTaskCount) / Double(totalTaskCount)
    }
}

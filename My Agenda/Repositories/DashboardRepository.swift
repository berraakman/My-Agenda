//
//  DashboardRepository.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation
import SwiftData

// MARK: - DashboardRepository
/// Dashboard modeli için veri erişim katmanı.
/// Tüm SwiftData CRUD operasyonları bu sınıf üzerinden gerçekleştirilir.
/// ViewModel'ler doğrudan ModelContext kullanmaz, Repository üzerinden çalışır.
@Observable
final class DashboardRepository {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    // MARK: - Init
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD Operations
    
    /// Tüm dashboard'ları sıralı olarak getirir
    func fetchAll(sortBy: SortDescriptor<Dashboard> = SortDescriptor(\Dashboard.sortIndex)) -> [Dashboard] {
        let descriptor = FetchDescriptor<Dashboard>(sortBy: [sortBy])
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Dashboard fetch hatası: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Yeni dashboard oluşturur
    func create(name: String, icon: String = "folder.fill", colorHex: String = "#007AFF", sortIndex: Int = 0) -> Dashboard {
        let dashboard = Dashboard(
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortIndex: sortIndex
        )
        modelContext.insert(dashboard)
        save()
        return dashboard
    }
    
    /// Dashboard günceller
    func update(_ dashboard: Dashboard, name: String? = nil, icon: String? = nil, colorHex: String? = nil) {
        if let name = name { dashboard.name = name }
        if let icon = icon { dashboard.icon = icon }
        if let colorHex = colorHex { dashboard.colorHex = colorHex }
        save()
    }
    
    /// Dashboard siler (cascade ile görevler de silinir)
    func delete(_ dashboard: Dashboard) {
        modelContext.delete(dashboard)
        save()
    }
    
    /// ID ile dashboard bulur
    func findById(_ id: UUID) -> Dashboard? {
        let descriptor = FetchDescriptor<Dashboard>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    // MARK: - Private
    
    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("❌ Dashboard save hatası: \(error.localizedDescription)")
        }
    }
}

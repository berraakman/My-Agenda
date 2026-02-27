//
//  DashboardViewModel.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation
import SwiftData

// MARK: - DashboardViewModel
/// Dashboard yönetimi için iş mantığı katmanı.
/// Dashboard CRUD, sıralama ve ilerleme hesaplama işlemlerini yönetir.
@Observable
final class DashboardViewModel {
    
    // MARK: - Properties
    
    private let repository: DashboardRepository
    
    /// Mevcut dashboard listesi
    var dashboards: [Dashboard] = []
    
    // MARK: - Init
    
    init(modelContext: ModelContext) {
        self.repository = DashboardRepository(modelContext: modelContext)
        loadDashboards()
    }
    
    // MARK: - Public Methods
    
    /// Dashboard listesini yeniler
    func loadDashboards() {
        dashboards = repository.fetchAll()
    }
    
    /// Yeni dashboard oluşturur
    @discardableResult
    func createDashboard(name: String, icon: String, colorHex: String) -> Dashboard {
        let dashboard = repository.create(
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortIndex: dashboards.count
        )
        loadDashboards()
        return dashboard
    }
    
    /// Dashboard bilgilerini günceller
    func updateDashboard(_ dashboard: Dashboard, name: String?, icon: String?, colorHex: String?) {
        repository.update(dashboard, name: name, icon: icon, colorHex: colorHex)
        loadDashboards()
    }
    
    /// Dashboard siler
    func deleteDashboard(_ dashboard: Dashboard) {
        repository.delete(dashboard)
        loadDashboards()
    }
    
    /// Dashboard adını değiştirir
    func renameDashboard(_ dashboard: Dashboard, to newName: String) {
        repository.update(dashboard, name: newName)
        loadDashboards()
    }
}

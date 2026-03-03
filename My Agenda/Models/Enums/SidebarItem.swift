//
//  SidebarItem.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation

// MARK: - SidebarItem Enum
/// Sidebar'daki navigasyon seçeneklerini temsil eder.
/// Dashboard'lar dinamik olarak eklenir, geri kalanlar sabit menü öğeleridir.
enum SidebarItem: Hashable {
    
    /// Bugün genel bakış ekranı
    case today
    
    /// Tüm görevlerin listelendiği global görünüm
    case allTasks
    
    /// Belirli bir dashboard'un görevleri
    case dashboard(Dashboard)
    
    /// Belirli bir klasörün görevleri
    case folder(DashboardFolder)
    
    /// Takvim (Haftalık/Aylık/Apple Calendar)
    case calendar
    
    /// İstatistik ve analiz ekranı
    case statistics
    
    // MARK: - Display Properties
    
    /// Menü öğesinin görüntüleme adı
    var displayName: String {
        switch self {
        case .today:
            return "Bugün"
        case .allTasks:
            return "Tüm Görevler"
        case .dashboard(let dashboard):
            return dashboard.name
        case .folder(let folder):
            return folder.name
        case .calendar:
            return "Takvim"
        case .statistics:
            return "İstatistikler"
        }
    }
    
    /// Menü öğesinin SF Symbol ikonu
    var iconName: String {
        switch self {
        case .today:
            return "sun.max.fill"
        case .allTasks:
            return "tray.full.fill"
        case .dashboard(let dashboard):
            return dashboard.icon
        case .folder(let folder):
            return folder.icon
        case .calendar:
            return "calendar"
        case .statistics:
            return "chart.bar.fill"
        }
    }
    
    // MARK: - Hashable Conformance
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .today:
            hasher.combine("today")
        case .allTasks:
            hasher.combine("allTasks")
        case .dashboard(let dashboard):
            hasher.combine("dashboard")
            hasher.combine(dashboard.id)
        case .folder(let folder):
            hasher.combine("folder")
            hasher.combine(folder.id)
        case .calendar:
            hasher.combine("calendar")
        case .statistics:
            hasher.combine("statistics")
        }
    }
    
    static func == (lhs: SidebarItem, rhs: SidebarItem) -> Bool {
        switch (lhs, rhs) {
        case (.today, .today):
            return true
        case (.allTasks, .allTasks):
            return true
        case (.dashboard(let a), .dashboard(let b)):
            return a.id == b.id
        case (.folder(let a), .folder(let b)):
            return a.id == b.id
        case (.calendar, .calendar):
            return true
        case (.statistics, .statistics):
            return true
        default:
            return false
        }
    }
}

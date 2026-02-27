//
//  StatisticsViewModel.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation
import SwiftData

// MARK: - StatisticsViewModel
/// İstatistik ekranı için iş mantığı katmanı.
/// Görev tamamlanma verileri, dashboard bazlı analiz ve grafik verilerini üretir.
@Observable
final class StatisticsViewModel {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    /// Son 7 günün günlük tamamlanma sayıları
    var dailyCompletionData: [DailyCompletion] = []
    
    /// Dashboard bazlı istatistikler
    var dashboardStats: [DashboardStat] = []
    
    /// Genel istatistikler
    var totalTasks: Int = 0
    var completedTasks: Int = 0
    var pendingTasks: Int = 0
    var overdueTasks: Int = 0
    var completionRate: Double = 0.0
    
    // MARK: - Init
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadStatistics()
    }
    
    // MARK: - Load Data
    
    func loadStatistics() {
        loadGeneralStats()
        loadDailyCompletions()
        loadDashboardStats()
    }
    
    // MARK: - General Stats
    
    private func loadGeneralStats() {
        let allDescriptor = FetchDescriptor<AgendaTask>()
        let allTasks = (try? modelContext.fetch(allDescriptor)) ?? []
        
        totalTasks = allTasks.count
        completedTasks = allTasks.filter { $0.isCompleted }.count
        pendingTasks = allTasks.filter { !$0.isCompleted }.count
        overdueTasks = allTasks.filter { $0.isOverdue }.count
        completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
    }
    
    // MARK: - Daily Completions (Last 7 Days)
    
    private func loadDailyCompletions() {
        let calendar = Calendar.current
        var data: [DailyCompletion] = []
        
        for dayOffset in (0...6).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }
            
            let descriptor = FetchDescriptor<AgendaTask>(
                predicate: #Predicate { task in
                    task.isCompleted &&
                    task.completedAt != nil &&
                    task.completedAt! >= startOfDay &&
                    task.completedAt! < endOfDay
                }
            )
            
            let count = (try? modelContext.fetchCount(descriptor)) ?? 0
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "tr_TR")
            formatter.dateFormat = "EEE"
            let dayName = formatter.string(from: date)
            
            data.append(DailyCompletion(
                date: date,
                dayName: dayName,
                count: count
            ))
        }
        
        dailyCompletionData = data
    }
    
    // MARK: - Dashboard Stats
    
    private func loadDashboardStats() {
        let descriptor = FetchDescriptor<Dashboard>(
            sortBy: [SortDescriptor(\Dashboard.sortIndex)]
        )
        
        guard let dashboards = try? modelContext.fetch(descriptor) else { return }
        
        dashboardStats = dashboards.map { dashboard in
            DashboardStat(
                name: dashboard.name,
                colorHex: dashboard.colorHex,
                icon: dashboard.icon,
                totalTasks: dashboard.totalTaskCount,
                completedTasks: dashboard.completedTaskCount,
                pendingTasks: dashboard.pendingTaskCount,
                completionRate: dashboard.completionPercentage
            )
        }
    }
}

// MARK: - Data Models

/// Günlük tamamlanma verisi
struct DailyCompletion: Identifiable {
    let id = UUID()
    let date: Date
    let dayName: String
    let count: Int
}

/// Dashboard istatistik verisi
struct DashboardStat: Identifiable {
    let id = UUID()
    let name: String
    let colorHex: String
    let icon: String
    let totalTasks: Int
    let completedTasks: Int
    let pendingTasks: Int
    let completionRate: Double
}

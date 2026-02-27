//
//  DashboardAnalyticsView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import Charts

// MARK: - DashboardAnalyticsView
/// Dashboard bazlı analiz kartları.
/// Her dashboard'un tamamlanma oranını ve görev dağılımını gösterir.
struct DashboardAnalyticsView: View {
    
    // MARK: - Properties
    
    let stats: [DashboardStat]
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Başlık
            Label("Dashboard Analizi", systemImage: "folder.fill")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            
            if stats.isEmpty {
                Text("Henüz dashboard yok.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Dashboard kartları
                ForEach(stats) { stat in
                    dashboardCard(stat)
                }
                
                // Genel dağılım grafiği
                if !stats.filter({ $0.totalTasks > 0 }).isEmpty {
                    distributionChart
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Dashboard Card
    
    private func dashboardCard(_ stat: DashboardStat) -> some View {
        HStack(spacing: 12) {
            // İkon
            Image(systemName: stat.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: stat.colorHex))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: stat.colorHex).opacity(0.12))
                )
            
            // Ad ve istatistik
            VStack(alignment: .leading, spacing: 2) {
                Text(stat.name)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                
                Text("\(stat.completedTasks)/\(stat.totalTasks) görev tamamlandı")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // İlerleme halkası
            ProgressRingView(
                progress: stat.completionRate,
                color: Color(hex: stat.colorHex),
                lineWidth: 3,
                size: 28,
                showPercentage: false
            )
            
            // Yüzde
            Text("\(Int(stat.completionRate * 100))%")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: stat.colorHex))
                .frame(width: 40, alignment: .trailing)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.smallCornerRadius)
                .fill(.quaternary.opacity(0.5))
        )
    }
    
    // MARK: - Distribution Chart
    
    private var distributionChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Görev Dağılımı")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            
            Chart(stats.filter { $0.totalTasks > 0 }) { stat in
                SectorMark(
                    angle: .value("Görevler", stat.totalTasks),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(Color(hex: stat.colorHex))
                .cornerRadius(4)
                .annotation(position: .overlay) {
                    Text("\(stat.totalTasks)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 160)
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleStats = [
        DashboardStat(name: "Teknofest", colorHex: "#FF9500", icon: "trophy.fill", totalTasks: 12, completedTasks: 8, pendingTasks: 4, completionRate: 0.67),
        DashboardStat(name: "Üniversite", colorHex: "#007AFF", icon: "graduationcap.fill", totalTasks: 20, completedTasks: 15, pendingTasks: 5, completionRate: 0.75),
        DashboardStat(name: "Kişisel", colorHex: "#34C759", icon: "heart.fill", totalTasks: 5, completedTasks: 5, pendingTasks: 0, completionRate: 1.0),
    ]
    
    return DashboardAnalyticsView(stats: sampleStats)
        .frame(width: 500)
        .padding()
}

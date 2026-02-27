//
//  DashboardProgressView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI

// MARK: - DashboardProgressView
/// Dashboard'un üst kısmında gösterilen ilerleme özet kartı.
/// Tamamlanma yüzdesi, toplam/bekleyen/gecikmiş görev sayılarını gösterir.
struct DashboardProgressView: View {
    
    // MARK: - Properties
    
    let dashboard: Dashboard
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 24) {
            // Sol: Büyük ilerleme halkası
            ProgressRingView(
                progress: dashboard.completionPercentage,
                color: Color(hex: dashboard.colorHex),
                lineWidth: 8,
                size: 72,
                showPercentage: true
            )
            
            // Sağ: İstatistik metrikler
            VStack(alignment: .leading, spacing: 8) {
                // Toplam görev
                statRow(
                    icon: "checklist",
                    label: "Toplam",
                    value: "\(dashboard.totalTaskCount)",
                    color: .primary
                )
                
                // Tamamlanan
                statRow(
                    icon: "checkmark.circle.fill",
                    label: "Tamamlanan",
                    value: "\(dashboard.completedTaskCount)",
                    color: .green
                )
                
                // Bekleyen
                statRow(
                    icon: "clock.fill",
                    label: "Bekleyen",
                    value: "\(dashboard.pendingTaskCount)",
                    color: .orange
                )
                
                // Gecikmiş
                if dashboard.overdueTaskCount > 0 {
                    statRow(
                        icon: "exclamationmark.triangle.fill",
                        label: "Gecikmiş",
                        value: "\(dashboard.overdueTaskCount)",
                        color: .red
                    )
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .stroke(Color(hex: dashboard.colorHex).opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Helpers
    
    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 16)
            
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(width: 160)
    }
}

// MARK: - Preview

#Preview {
    let dashboard = Dashboard(name: "Teknofest", icon: "trophy.fill", colorHex: "#FF9500")
    return DashboardProgressView(dashboard: dashboard)
        .padding()
        .frame(width: 400)
}

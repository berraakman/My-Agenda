//
//  SidebarRowView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI

// MARK: - SidebarRowView
/// Sidebar'da tek bir dashboard satırını gösterir.
/// Dashboard ikonu, adı, bekleyen görev sayısı ve ilerleme halkası içerir.
struct SidebarRowView: View {
    
    // MARK: - Properties
    
    let dashboard: Dashboard
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 10) {
            // Dashboard ikonu (renk ile)
            Image(systemName: dashboard.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: dashboard.colorHex))
                .frame(width: 20)
            
            // Dashboard adı
            Text(dashboard.name)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
            
            // Bekleyen görev sayısı badge
            if dashboard.pendingTaskCount > 0 {
                Text("\(dashboard.pendingTaskCount)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.quaternary)
                    )
            }
            
            // Küçük ilerleme halkası
            ProgressRingView(
                progress: dashboard.completionPercentage,
                color: Color(hex: dashboard.colorHex),
                lineWidth: 2.5,
                size: 18
            )
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    let dashboard = Dashboard(
        name: "Teknofest",
        icon: "trophy.fill",
        colorHex: "#FF9500"
    )
    
    return SidebarRowView(dashboard: dashboard)
        .frame(width: 240)
        .padding()
}

//
//  PriorityBadgeView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI

// MARK: - PriorityBadgeView
/// Görev öncelik seviyesini gösteren küçük renkli rozet.
/// Reusable: TaskRowView, TaskDetailView gibi yerlerde kullanılır.
struct PriorityBadgeView: View {
    
    let priority: Priority
    var showLabel: Bool = true
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priority.iconName)
                .font(.system(size: 10, weight: .semibold))
            
            if showLabel {
                Text(priority.displayName)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
            }
        }
        .foregroundStyle(priority.color)
        .padding(.horizontal, showLabel ? 8 : 4)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(priority.color.opacity(0.12))
        )
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        PriorityBadgeView(priority: .low)
        PriorityBadgeView(priority: .medium)
        PriorityBadgeView(priority: .high)
        PriorityBadgeView(priority: .high, showLabel: false)
    }
    .padding()
}

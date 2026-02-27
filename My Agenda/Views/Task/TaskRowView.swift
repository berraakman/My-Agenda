//
//  TaskRowView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI

// MARK: - TaskRowView
/// Görev listesinde tek bir görev satırını gösterir.
/// Tamamlanma checkbox'ı, başlık, öncelik rozeti, son tarih ve dashboard adı.
struct TaskRowView: View {
    
    // MARK: - Properties
    
    let task: AgendaTask
    var onToggle: () -> Void
    
    // MARK: - State
    
    @State private var isHovering = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Tamamlanma checkbox
            Button {
                withAnimation(AppConstants.springAnimation) {
                    onToggle()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            
            // Görev bilgileri
            VStack(alignment: .leading, spacing: 4) {
                // Üst satır: Başlık + Öncelik
                HStack(spacing: 8) {
                    Text(task.title)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .lineLimit(1)
                    
                    PriorityBadgeView(priority: task.priority, showLabel: false)
                    
                    if task.isRecurring {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                }
                
                // Alt satır: Son tarih + Dashboard adı
                HStack(spacing: 12) {
                    // Son tarih
                    if let dueDate = task.dueDate {
                        HStack(spacing: 3) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text(dueDate.relativeFormatted)
                                .font(.system(size: 11, design: .rounded))
                        }
                        .foregroundStyle(task.isOverdue ? .red : .secondary)
                    }
                    
                    // Saat
                    if let dueTime = task.dueTime {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(dueTime.timeFormatted)
                                .font(.system(size: 11, design: .rounded))
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    // Dashboard adı
                    if let dashboard = task.dashboard {
                        HStack(spacing: 3) {
                            Image(systemName: dashboard.icon)
                                .font(.system(size: 10))
                            Text(dashboard.name)
                                .font(.system(size: 11, design: .rounded))
                        }
                        .foregroundStyle(Color(hex: dashboard.colorHex))
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.smallCornerRadius)
                .fill(isHovering ? Color.primary.opacity(0.04) : .clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .opacity(task.isCompleted ? 0.7 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    let dashboard = Dashboard(name: "Teknofest", icon: "trophy.fill", colorHex: "#FF9500")
    let task = AgendaTask(
        title: "Sunum hazırla",
        priority: .high,
        dueDate: Date().addingTimeInterval(86400),
        dueTime: Date(),
        isRecurring: true,
        recurrenceType: .weekly,
        dashboard: dashboard
    )
    
    return TaskRowView(task: task, onToggle: {})
        .frame(width: 400)
        .padding()
}

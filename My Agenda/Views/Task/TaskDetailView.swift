//
//  TaskDetailView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI

// MARK: - TaskDetailView
/// NavigationSplitView'ın sağ panelinde gösterilen görev detay ekranı.
/// Görevin tüm bilgileri, düzenleme ve silme işlemleri burada yapılır.
struct TaskDetailView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let task: AgendaTask
    @Binding var selectedTask: AgendaTask?
    
    // MARK: - State
    
    @State private var isShowingEditSheet = false
    @State private var isShowingDeleteAlert = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header kartı
                headerCard
                
                // Bilgi kartları
                detailCards
                
                // Açıklama
                if !task.taskDescription.isEmpty {
                    descriptionCard
                }
                
                // Tekrarlama bilgisi
                if task.isRecurring, let recurrence = task.recurrenceType {
                    recurrenceCard(recurrence)
                }
                
                // Meta veriler
                metadataCard
                
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: AppConstants.detailMinWidth)
        .navigationTitle(task.title)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Tamamlanma toggle
                Button {
                    withAnimation(AppConstants.springAnimation) {
                        task.toggleCompletion()
                    }
                } label: {
                    Label(
                        task.isCompleted ? "Geri Al" : "Tamamla",
                        systemImage: task.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle"
                    )
                }
                .help(task.isCompleted ? "Tamamlanmadı Olarak İşaretle" : "Tamamlandı Olarak İşaretle")
                
                // Düzenle
                Button {
                    isShowingEditSheet = true
                } label: {
                    Label("Düzenle", systemImage: "pencil")
                }
                .help("Görevi Düzenle")
                
                // Sil
                Button(role: .destructive) {
                    isShowingDeleteAlert = true
                } label: {
                    Label("Sil", systemImage: "trash")
                }
                .help("Görevi Sil")
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            TaskFormView(task: task)
        }
        .alert("Görevi Sil", isPresented: $isShowingDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("'\(task.title)' görevini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.")
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        HStack(spacing: 16) {
            // Tamamlanma ikonu
            Image(systemName: task.isCompleted ? "checkmark.seal.fill" : "circle.dotted")
                .font(.system(size: 36))
                .foregroundStyle(task.isCompleted ? .green : .secondary)
                .symbolEffect(.bounce, value: task.isCompleted)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    PriorityBadgeView(priority: task.priority)
                    
                    if task.isCompleted {
                        Text("Tamamlandı")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(.green.opacity(0.12))
                            )
                    } else if task.isOverdue {
                        Text("Gecikmiş")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(.red.opacity(0.12))
                            )
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Detail Cards
    
    private var detailCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Son tarih
            if let dueDate = task.dueDate {
                detailCard(
                    icon: "calendar",
                    title: "Son Tarih",
                    value: dueDate.longFormatted,
                    subtitle: dueDate.relativeFormatted,
                    color: task.isOverdue ? .red : .blue
                )
            }
            
            // Saat
            if let dueTime = task.dueTime {
                detailCard(
                    icon: "clock.fill",
                    title: "Saat",
                    value: dueTime.timeFormatted,
                    color: .orange
                )
            }
            
            // Dashboard
            if let dashboard = task.dashboard {
                detailCard(
                    icon: dashboard.icon,
                    title: "Dashboard",
                    value: dashboard.name,
                    color: Color(hex: dashboard.colorHex)
                )
            }
            
            // Kalan gün
            if let days = task.daysUntilDue, !task.isCompleted {
                detailCard(
                    icon: days >= 0 ? "hourglass" : "exclamationmark.triangle.fill",
                    title: "Kalan Süre",
                    value: days == 0 ? "Bugün" : (days > 0 ? "\(days) gün" : "\(abs(days)) gün geçti"),
                    color: days < 0 ? .red : (days == 0 ? .orange : .green)
                )
            }
        }
    }
    
    private func detailCard(icon: String, title: String, value: String, subtitle: String? = nil, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.12))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Description Card
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Açıklama", systemImage: "text.alignleft")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            
            Text(task.taskDescription)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Recurrence Card
    
    private func recurrenceCard(_ recurrence: RecurrenceType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: recurrence.iconName)
                .font(.system(size: 18))
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue.opacity(0.12))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Tekrarlama")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(recurrence.displayName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Metadata Card
    
    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Bilgiler", systemImage: "info.circle")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            
            Divider()
            
            metadataRow(label: "Oluşturulma", value: task.createdAt.dateTimeFormatted)
            
            if let completedAt = task.completedAt {
                metadataRow(label: "Tamamlanma", value: completedAt.dateTimeFormatted)
            }
            
            if task.calendarEventId != nil {
                metadataRow(label: "Takvim", value: "Apple Calendar ile senkronize")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - Actions
    
    private func deleteTask() {
        selectedTask = nil
        modelContext.delete(task)
    }
}

// MARK: - Preview

#Preview {
    let dashboard = Dashboard(name: "Teknofest", icon: "trophy.fill", colorHex: "#FF9500")
    let task = AgendaTask(
        title: "Sunum hazırla",
        taskDescription: "Yarışma sunumunu hazırla ve takıma gönder. Slide'ları kontrol et.",
        priority: .high,
        dueDate: Date().addingTimeInterval(86400 * 2),
        dueTime: Date(),
        isRecurring: true,
        recurrenceType: .weekly,
        dashboard: dashboard
    )
    
    return TaskDetailView(task: task, selectedTask: .constant(task))
        .modelContainer(for: [Dashboard.self, AgendaTask.self], inMemory: true)
        .frame(width: 400, height: 600)
}

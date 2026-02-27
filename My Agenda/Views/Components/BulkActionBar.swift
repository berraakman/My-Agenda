//
//  BulkActionBar.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import SwiftData

// MARK: - BulkActionBar
/// Toplu işlem araç çubuğu.
/// Basit, yazılı butonlarla: Tamamlandı işaretle, Taşı, Sil, Kapat.
struct BulkActionBar: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Query
    
    @Query(sort: \Dashboard.sortIndex)
    private var dashboards: [Dashboard]
    
    // MARK: - Bindings
    
    @Binding var selectedTasks: Set<AgendaTask>
    @Binding var isSelectionMode: Bool
    
    /// Silme onay dialog
    @State private var showDeleteConfirmation = false
    
    // MARK: - Body
    
    var body: some View {
        if isSelectionMode && !selectedTasks.isEmpty {
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 16) {
                    // Sol: Seçili sayısı
                    Text("\(selectedTasks.count) görev seçili")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // Tamamlandı / Tamamlanmadı İşaretle
                    if allSelectedCompleted {
                        Button("Tamamlanmadı İşaretle") {
                            bulkMarkIncomplete()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("Tamamlandı İşaretle") {
                            bulkMarkComplete()
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    }
                    
                    // Taşı
                    Menu("Taşı") {
                        ForEach(dashboards) { dashboard in
                            Button(dashboard.name) {
                                bulkMove(to: dashboard)
                            }
                        }
                        
                        Divider()
                        
                        Button("Dashboard'dan Çıkar") {
                            bulkRemoveFromDashboard()
                        }
                    }
                    
                    // Sil
                    Button("Sil") {
                        showDeleteConfirmation = true
                    }
                    .foregroundStyle(.red)
                    
                    // Kapat
                    Button("Kapat") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTasks.removeAll()
                            isSelectionMode = false
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .alert("Görevleri Sil", isPresented: $showDeleteConfirmation) {
                Button("İptal", role: .cancel) { }
                Button("Sil (\(selectedTasks.count))", role: .destructive) {
                    bulkDelete()
                }
            } message: {
                Text("\(selectedTasks.count) görevi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.")
            }
        }
    }
    
    // MARK: - Computed
    
    private var allSelectedCompleted: Bool {
        !selectedTasks.isEmpty && selectedTasks.allSatisfy { $0.isCompleted }
    }
    
    // MARK: - Actions
    
    private func bulkMarkComplete() {
        withAnimation(AppConstants.springAnimation) {
            for task in selectedTasks {
                if !task.isCompleted {
                    task.toggleCompletion()
                }
            }
            selectedTasks.removeAll()
            isSelectionMode = false
        }
    }
    
    private func bulkMarkIncomplete() {
        withAnimation(AppConstants.springAnimation) {
            for task in selectedTasks {
                if task.isCompleted {
                    task.toggleCompletion()
                }
            }
            selectedTasks.removeAll()
            isSelectionMode = false
        }
    }
    
    private func bulkMove(to dashboard: Dashboard) {
        withAnimation(AppConstants.springAnimation) {
            for task in selectedTasks {
                task.dashboard = dashboard
            }
            selectedTasks.removeAll()
            isSelectionMode = false
        }
    }
    
    private func bulkRemoveFromDashboard() {
        withAnimation(AppConstants.springAnimation) {
            for task in selectedTasks {
                task.dashboard = nil
            }
            selectedTasks.removeAll()
            isSelectionMode = false
        }
    }
    
    private func bulkDelete() {
        withAnimation(AppConstants.springAnimation) {
            for task in selectedTasks {
                modelContext.delete(task)
            }
            selectedTasks.removeAll()
            isSelectionMode = false
        }
    }
}

// MARK: - Preview

#Preview {
    BulkActionBar(
        selectedTasks: .constant([]),
        isSelectionMode: .constant(true)
    )
    .modelContainer(for: [Dashboard.self, AgendaTask.self], inMemory: true)
}

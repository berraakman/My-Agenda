//
//  MainView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import SwiftData

// MARK: - MainView
/// Uygulamanın ana görünümü.
/// NavigationSplitView ile 3 sütunlu (sidebar – content – detail) layout sunar.
/// Sidebar seçimine göre content alanında ilgili ekranı gösterir.
struct MainView: View {
    
    // MARK: - State
    
    /// Sidebar'da seçili öğe — varsayılan: Bugün
    @State private var selectedSidebarItem: SidebarItem? = .today
    
    /// Detail panelinde seçili görev
    @State private var selectedTask: AgendaTask?
    
    // MARK: - Body
    
    var body: some View {
        // İki sütunlu yapı: Sol Menü + Ana İçerik
        NavigationSplitView {
            
            // ════════════════════════════════════════
            // SIDEBAR (Sol Panel)
            // ════════════════════════════════════════
            SidebarView(selectedItem: $selectedSidebarItem)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260)
            
        } detail: {
            
            // ════════════════════════════════════════
            // CONTENT (Orta Panel / Ana Alan)
            // ════════════════════════════════════════
            contentView
                // Inspector (Sağ Panel) — Sadece görev seçiliyken görünür
                .inspector(isPresented: Binding(
                    get: { selectedTask != nil },
                    set: { if !$0 { selectedTask = nil } }
                )) {
                    if let task = selectedTask {
                        TaskInlineEditor(task: task, selectedTask: $selectedTask)
                            .inspectorColumnWidth(min: 280, ideal: 300, max: 400)
                    }
                }
        }
        .frame(
            minWidth: AppConstants.minWindowWidth,
            minHeight: AppConstants.minWindowHeight
        )
        // Sidebar seçimi değiştiğinde seçili görevi temizle (ve yan paneli kapat)
        .onChange(of: selectedSidebarItem) { _, _ in
            selectedTask = nil
        }
    }
    
    // MARK: - Content View Builder
    
    /// Sidebar seçimine göre ana alanda gösterilecek view
    @ViewBuilder
    private var contentView: some View {
        switch selectedSidebarItem {
        case .today:
            TodayOverviewView(
                selectedTask: $selectedTask,
                selectedSidebarItem: $selectedSidebarItem
            )
            
        case .allTasks:
            TaskListView(selectedTask: $selectedTask)
            
        case .dashboard(let dashboard):
            DashboardDetailView(dashboard: dashboard, selectedTask: $selectedTask)
            
        case .calendar:
            CalendarView(selectedTask: $selectedTask)
            
        case .statistics:
            StatisticsView()
            
        case .none:
            EmptyStateView(
                icon: "sidebar.leading",
                title: "Bir bölüm seçin",
                message: "Başlamak için sol panelden bir dashboard veya bölüm seçin."
            )
        }
    }
}

// MARK: - Preview

#Preview {
    MainView()
        .environment(CalendarService())
        .environment(NotificationService())
        .modelContainer(for: [Dashboard.self, AgendaTask.self], inMemory: true)
}

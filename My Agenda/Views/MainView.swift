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
    
    /// Sidebar görünürlük kontrolü
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    // MARK: - Body
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            
            // ════════════════════════════════════════
            // SIDEBAR (Sol Panel)
            // ════════════════════════════════════════
            SidebarView(selectedItem: $selectedSidebarItem)
            
        } content: {
            
            // ════════════════════════════════════════
            // CONTENT (Orta Panel)
            // ════════════════════════════════════════
            contentView
            
        } detail: {
            
            // ════════════════════════════════════════
            // DETAIL (Sağ Panel)
            // ════════════════════════════════════════
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .frame(
            minWidth: AppConstants.minWindowWidth,
            minHeight: AppConstants.minWindowHeight
        )
        // Sidebar seçimi değiştiğinde seçili görevi temizle
        .onChange(of: selectedSidebarItem) { _, _ in
            selectedTask = nil
        }
    }
    
    // MARK: - Content View Builder
    
    /// Sidebar seçimine göre orta panelde gösterilecek view
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
            CalendarView()
            
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
    
    // MARK: - Detail View Builder
    
    /// Seçili göreve göre sağ panelde gösterilecek view
    @ViewBuilder
    private var detailView: some View {
        if let task = selectedTask {
            TaskDetailView(task: task, selectedTask: $selectedTask)
        } else {
            EmptyStateView(
                icon: "doc.text.magnifyingglass",
                title: "Görev seçilmedi",
                message: "Detaylarını görüntülemek için listeden bir görev seçin."
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

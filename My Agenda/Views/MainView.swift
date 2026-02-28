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
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    /// Sidebar'da seçili öğe — varsayılan: Bugün
    @State private var selectedSidebarItem: SidebarItem? = .today
    
    /// Sidebar görünürlük durumu
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    /// Detail panelinde seçili görev
    @State private var selectedTask: AgendaTask?
    
    /// iPhone için sidebar kayma durumu
    @State private var isSidebarVisible = false
    
    /// Sürükleme kontrolü için mevcut X konumu
    @State private var sidebarOffset: CGFloat = -280
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if sizeClass == .compact {
                iphoneLayout
            } else {
                desktopLayout
            }
        }
        #if os(macOS)
        .frame(
            minWidth: AppConstants.minWindowWidth,
            minHeight: AppConstants.minWindowHeight
        )
        #endif
        .onChange(of: selectedSidebarItem) { _, _ in
            selectedTask = nil
            if sizeClass == .compact {
                closeSidebar()
            }
        }
    }
    
    // MARK: - Layouts
    
    @ViewBuilder
    private var iphoneLayout: some View {
        ZStack {
            // Ana İçerik
            NavigationStack {
                Group {
                    contentView
                }
                #if os(iOS)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            toggleSidebar()
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                                .foregroundStyle(.primary)
                        }
                    }
                }
                #endif
            }
            
            // Karartma Perdesi
            if isSidebarVisible {
                Color.black.opacity(Double((280 + sidebarOffset) / 280) * 0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        toggleSidebar()
                    }
            }
            
            // Kayar Sidebar
            HStack(spacing: 0) {
                SidebarView(selectedItem: $selectedSidebarItem)
                    .frame(width: 280)
                    .background(Color.primary.colorInvert())
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 5)
                
                Spacer()
            }
            .offset(x: sidebarOffset)
            .zIndex(2)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isSidebarVisible && value.startLocation.x > 50 { return }
                    
                    let newOffset = (isSidebarVisible ? 0 : -280) + value.translation.width
                    sidebarOffset = min(0, max(-280, newOffset))
                }
                .onEnded { value in
                    let velocity = value.predictedEndTranslation.width
                    let currentOffset = sidebarOffset
                    
                    if isSidebarVisible {
                        if currentOffset < -100 || velocity < -500 {
                            closeSidebar()
                        } else {
                            openSidebar()
                        }
                    } else {
                        if value.startLocation.x < 50 {
                            if currentOffset > -180 || velocity > 500 {
                                openSidebar()
                            } else {
                                closeSidebar()
                            }
                        }
                    }
                }
        )
    }
    
    @ViewBuilder
    private var desktopLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedItem: $selectedSidebarItem)
                #if os(macOS)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260)
                #endif
        } detail: {
            NavigationStack {
                contentView
                    // Inspector (Sağ Panel) — Sadece görev seçiliyken görünür
                    .inspector(isPresented: Binding(
                        get: { selectedTask != nil },
                        set: { if !$0 { selectedTask = nil } }
                    )) {
                        if let task = selectedTask {
                            TaskInlineEditor(task: task, selectedTask: $selectedTask)
                                #if os(macOS)
                                .inspectorColumnWidth(min: 280, ideal: 300, max: 400)
                                #endif
                        }
                    }
            }
        }
    }
    
    // MARK: - Content View Builder
    
    /// Sidebar seçimine göre ana alanda gösterilecek view
    @ViewBuilder
    private var contentView: some View {
        destinationView(for: selectedSidebarItem ?? .today)
    }
    
    @ViewBuilder
    private func destinationView(for item: SidebarItem) -> some View {
        switch item {
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
        }
    }
    
    // MARK: - Sidebar Helpers
    
    private func toggleSidebar() {
        if isSidebarVisible {
            closeSidebar()
        } else {
            openSidebar()
        }
    }
    
    private func openSidebar() {
        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.85)) {
            sidebarOffset = 0
            isSidebarVisible = true
        }
    }
    
    private func closeSidebar() {
        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.85)) {
            sidebarOffset = -280
            isSidebarVisible = false
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

//
//  SidebarView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import SwiftData

// MARK: - SidebarView
/// Modern, özel tasarımlı sidebar. Klasik macOS List sidebar yerine
/// koyu gradient arka planlı, büyük ikonlu, hover efektli premium görünüm.
struct SidebarView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - SwiftData Query
    
    @Query(sort: \Dashboard.sortIndex, order: .forward)
    private var dashboards: [Dashboard]
    
    @Query(filter: #Predicate<AgendaTask> { !$0.isCompleted })
    private var pendingTasks: [AgendaTask]
    
    // MARK: - Bindings
    
    @Binding var selectedItem: SidebarItem?
    
    // MARK: - State
    
    @State private var isShowingNewDashboard = false
    @State private var isShowingRenameAlert = false
    @State private var dashboardToRename: Dashboard?
    @State private var renameText = ""
    @State private var hoveredItem: SidebarItem?
    @State private var expandedDashboards: Set<UUID> = []
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // ════════════════════════════════════════
            // LOGO / HEADER
            // ════════════════════════════════════════
            sidebarHeader
            
            Divider().opacity(0.3)
            
            // ════════════════════════════════════════
            // NAVİGASYON ÖĞELERİ
            // ════════════════════════════════════════
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    // ─── Genel ───
                    sectionLabel("GENEL")
                    
                    sidebarButton(
                        item: .today,
                        icon: "sun.max.fill",
                        label: "Bugün",
                        badge: todayTaskCount,
                        iconColor: .orange
                    )
                    
                    sidebarButton(
                        item: .allTasks,
                        icon: "tray.full.fill",
                        label: "Tüm Görevler",
                        badge: pendingTasks.count,
                        iconColor: .blue
                    )
                    
                    // ─── Dashboard'larım ───
                    HStack {
                        sectionLabel("DASHBOARD'LARIM")
                        Spacer()
                        Button {
                            isShowingNewDashboard = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                        .help("Yeni Dashboard Oluştur")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    ForEach(dashboards) { dashboard in
                        VStack(spacing: 2) {
                            dashboardButton(dashboard)
                            
                            // Klasörler (genişletilmişse)
                            if expandedDashboards.contains(dashboard.id) {
                                let sortedFolders = dashboard.folders.sorted { $0.sortIndex < $1.sortIndex }
                                ForEach(sortedFolders) { folder in
                                    folderButton(folder, dashboardColor: Color(hex: dashboard.colorHex))
                                }
                            }
                        }
                    }
                    
                    // ─── Araçlar ───
                    sectionLabel("ARAÇLAR")
                    
                    sidebarButton(
                        item: .calendar,
                        icon: "calendar",
                        label: "Takvim",
                        badge: nil,
                        iconColor: .red
                    )
                    
                    sidebarButton(
                        item: .statistics,
                        icon: "chart.bar.fill",
                        label: "İstatistikler",
                        badge: nil,
                        iconColor: .purple
                    )
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical, 8)
            }
            
            Divider().opacity(0.3)
            
            // ════════════════════════════════════════
            // FOOTER
            // ════════════════════════════════════════
            sidebarFooter
        }
        #if os(macOS)
        .frame(minWidth: AppConstants.sidebarMinWidth)
        .navigationSplitViewColumnWidth(
            min: AppConstants.sidebarMinWidth,
            ideal: AppConstants.sidebarIdealWidth,
            max: 360
        )
        #endif
        .background(sidebarBackground)
        // MARK: - Toolbar
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    isShowingNewDashboard = true
                } label: {
                    Label("Yeni Dashboard", systemImage: "plus")
                }
                .help("Yeni Dashboard Oluştur")
            }
        }
        // MARK: - Sheets & Alerts
        .sheet(isPresented: $isShowingNewDashboard) {
            NewDashboardSheet { name, icon, colorHex in
                createDashboard(name: name, icon: icon, colorHex: colorHex)
            }
        }
        .alert("Dashboard Adını Değiştir", isPresented: $isShowingRenameAlert) {
            TextField("Yeni ad", text: $renameText)
            Button("İptal", role: .cancel) { }
            Button("Kaydet") {
                if let dashboard = dashboardToRename, !renameText.isEmpty {
                    dashboard.name = renameText
                }
            }
        } message: {
            Text("Dashboard için yeni bir ad girin.")
        }
    }
    
    // MARK: - Sidebar Background
    
    private var sidebarBackground: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.08, blue: 0.12),
                        Color(red: 0.06, green: 0.06, blue: 0.10)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.94, green: 0.94, blue: 0.96),
                        Color(red: 0.91, green: 0.91, blue: 0.94)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
    
    // MARK: - Header
    
    private var sidebarHeader: some View {
        HStack(spacing: 12) {
            // App ikonu
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: "book.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text("My Agenda")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                
                Text("Dijital Planlayıcı")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Section Label
    
    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(.secondary.opacity(0.7))
                .kerning(1.2)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 4)
    }
    
    // MARK: - Sidebar Button
    
    private func sidebarButton(
        item: SidebarItem,
        icon: String,
        label: String,
        badge: Int?,
        iconColor: Color
    ) -> some View {
        let isSelected = selectedItem == item
        let isHovered = hoveredItem == item
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedItem = item
            }
        } label: {
            buttonContent(isSelected: isSelected, isHovered: isHovered, icon: icon, label: label, badge: badge, iconColor: iconColor)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                hoveredItem = hovering ? item : nil
            }
        }
    }
    
    private func buttonContent(isSelected: Bool, isHovered: Bool, icon: String, label: String, badge: Int?, iconColor: Color) -> some View {
        HStack(spacing: 12) {
            // İkon
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isSelected ? .white : iconColor)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isSelected ? iconColor : iconColor.opacity(0.12))
                )
            
            // Label
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.8))
            
            Spacer()
            
            // Badge
            if let badge = badge, badge > 0 {
                Text("\(badge)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? .white.opacity(0.2) : .primary.opacity(0.06))
                    )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    isSelected ? iconColor.opacity(0.18) :
                    isHovered ? .primary.opacity(0.04) :
                    .clear
                )
        )
    }
    
    // MARK: - Dashboard Button
    
    private func dashboardButton(_ dashboard: Dashboard) -> some View {
        let item = SidebarItem.dashboard(dashboard)
        let isSelected = selectedItem == item
        let isHovered = hoveredItem == item
        let color = Color(hex: dashboard.colorHex)
        let hasFolders = !dashboard.folders.isEmpty
        let isExpanded = expandedDashboards.contains(dashboard.id)
        
        return HStack(spacing: 0) {
            // Genişletme oku (klasör varsa)
            if hasFolders {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isExpanded {
                            expandedDashboards.remove(dashboard.id)
                        } else {
                            expandedDashboards.insert(dashboard.id)
                        }
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16, height: 16)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
                    .frame(width: 16)
            }
            
            // Dashboard butonu
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedItem = item
                }
            } label: {
                dashboardButtonContent(dashboard: dashboard, isSelected: isSelected, isHovered: isHovered, color: color)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 8)
        .padding(.trailing, 8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                hoveredItem = hovering ? item : nil
            }
        }
        .contextMenu {
            Button {
                dashboardToRename = dashboard
                renameText = dashboard.name
                isShowingRenameAlert = true
            } label: {
                Label("Yeniden Adlandır", systemImage: "pencil")
            }
            
            if hasFolders {
                Button {
                    withAnimation {
                        if isExpanded {
                            expandedDashboards.remove(dashboard.id)
                        } else {
                            expandedDashboards.insert(dashboard.id)
                        }
                    }
                } label: {
                    Label(isExpanded ? "Klasörleri Gizle" : "Klasörleri Göster", systemImage: isExpanded ? "folder.badge.minus" : "folder.badge.plus")
                }
            }
            
            Divider()
            
            Button(role: .destructive) {
                deleteDashboard(dashboard)
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
    }
    
    private func dashboardButtonContent(dashboard: Dashboard, isSelected: Bool, isHovered: Bool, color: Color) -> some View {
        HStack(spacing: 12) {
            // Dashboard ikonu
            Image(systemName: dashboard.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .white : color)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isSelected ? color : color.opacity(0.12))
                )
            
            // Dashboard adı
            Text(dashboard.name)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.8))
                .lineLimit(1)
            
            Spacer()
            
            // Progress + badge
            HStack(spacing: 6) {
                ProgressRingView(
                    progress: dashboard.completionPercentage,
                    color: color,
                    lineWidth: 2,
                    size: 18
                )
                
                if dashboard.pendingTaskCount > 0 {
                    Text("\(dashboard.pendingTaskCount)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white.opacity(0.2) : .primary.opacity(0.06))
                        )
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    isSelected ? color.opacity(0.15) :
                    isHovered ? .primary.opacity(0.04) :
                    .clear
                )
        )
    }
    
    // MARK: - Folder Button
    
    private func folderButton(_ folder: DashboardFolder, dashboardColor: Color) -> some View {
        let item = SidebarItem.folder(folder)
        let isSelected = selectedItem == item
        let isHovered = hoveredItem == item
        let color = Color(hex: folder.colorHex)
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedItem = item
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: folder.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(width: 22, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isSelected ? color : color.opacity(0.12))
                    )
                
                Text(folder.name)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.7))
                    .lineLimit(1)
                
                Spacer()
                
                if folder.pendingTaskCount > 0 {
                    Text("\(folder.pendingTaskCount)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white.opacity(0.2) : .primary.opacity(0.06))
                        )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected ? color.opacity(0.15) :
                        isHovered ? .primary.opacity(0.04) :
                        .clear
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, 36) // Dashboard'un altında girintili
        .padding(.trailing, 8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                hoveredItem = hovering ? item : nil
            }
        }
    }
    
    // MARK: - Footer
    
    private var sidebarFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.green)
            
            Text("\(pendingTasks.count) bekleyen görev")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Computed
    
    private var todayTaskCount: Int {
        pendingTasks.filter { $0.isDueToday }.count
    }
    
    // MARK: - Actions
    
    private func createDashboard(name: String, icon: String, colorHex: String) {
        let dashboard = Dashboard(
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortIndex: dashboards.count
        )
        modelContext.insert(dashboard)
    }
    
    private func deleteDashboard(_ dashboard: Dashboard) {
        if case .dashboard(let selected) = selectedItem, selected.id == dashboard.id {
            selectedItem = .today
        }
        modelContext.delete(dashboard)
    }
}

// MARK: - NewDashboardSheet
/// Yeni dashboard oluşturmak için modal sheet.
struct NewDashboardSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedIcon: String = AppConstants.dashboardIcons[0]
    @State private var selectedColor: String = AppConstants.dashboardColors[0]
    
    let onCreate: (String, String, String) -> Void
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Yeni Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            Form {
                Section("Dashboard Adı") {
                    TextField("Örn: Teknofest, Üniversite, Kişisel...", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .rounded))
                }
                
                Section("İkon") {
                    let columns = [
                        GridItem(.adaptive(minimum: 40, maximum: 40), spacing: 8)
                    ]
                    
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(AppConstants.dashboardIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(
                                        selectedIcon == icon
                                        ? Color(hex: selectedColor)
                                        : .secondary
                                    )
                                    .frame(width: 36, height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.15) : .clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedIcon == icon ? Color(hex: selectedColor) : .clear, lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Renk") {
                    let columns = [
                        GridItem(.adaptive(minimum: 36, maximum: 36), spacing: 8)
                    ]
                    
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(AppConstants.dashboardColors, id: \.self) { colorHex in
                            Button {
                                selectedColor = colorHex
                            } label: {
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == colorHex ? 2 : 0)
                                            .padding(selectedColor == colorHex ? -3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Önizleme") {
                    HStack(spacing: 12) {
                        Image(systemName: selectedIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color(hex: selectedColor))
                        
                        Text(name.isEmpty ? "Dashboard Adı" : name)
                            .font(.system(size: 16, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            HStack {
                Spacer()
                
                Button("İptal") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Oluştur") {
                    onCreate(
                        name.trimmingCharacters(in: .whitespaces),
                        selectedIcon,
                        selectedColor
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid)
            }
            .padding()
        }
        #if os(macOS)
        .frame(width: 480, height: 600)
        #endif
    }
}

// MARK: - Preview

#Preview {
    SidebarView(selectedItem: .constant(.today))
        .modelContainer(for: [Dashboard.self, AgendaTask.self], inMemory: true)
        .frame(width: 280, height: 600)
}

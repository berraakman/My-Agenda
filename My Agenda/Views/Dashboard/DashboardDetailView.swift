//
//  DashboardDetailView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import SwiftData

// MARK: - DashboardDetailView
/// Seçili dashboard'un içeriğini gösterir.
/// Üstte ilerleme kartı, altta görev listesi yer alır.
/// Görev ekleme, filtreleme, toplu işlem ve dashboard düzenleme işlemleri yapılabilir.
struct DashboardDetailView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    // MARK: - Properties
    
    let dashboard: Dashboard
    @Binding var selectedTask: AgendaTask?
    
    @Query(sort: \Dashboard.sortIndex)
    private var dashboards: [Dashboard]
    
    // MARK: - State
    
    @State private var isShowingAddTask = false
    @State private var isShowingEditDashboard = false
    @State private var filterOption: TaskFilterOption = .all
    @State private var sortOption: TaskSortOption = .custom
    @State private var searchText = ""
    
    /// Toplu işlem state
    @State private var isSelectionMode = false
    @State private var selectedTasks: Set<AgendaTask> = []
    @State private var isCompletedExpanded = true
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // İlerleme kartı (seçim modunda gizle daha fazla alan için)
            if !isSelectionMode {
                DashboardProgressView(dashboard: dashboard)
                    .padding()
            }
            
            // Filtre bar
            filterBar
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // Toplu işlem çubuğu (üstte)
            BulkActionBar(
                selectedTasks: $selectedTasks,
                isSelectionMode: $isSelectionMode
            )
            
            Divider()
            
            // Görev listesi
            if filteredTasks.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "Henüz görev yok",
                    message: emptyMessage,
                    buttonTitle: filterOption == .all ? "Görev Ekle" : nil,
                    onAction: filterOption == .all ? { isShowingAddTask = true } : nil
                )
            } else {
                if isSelectionMode {
                    // Seçim modu
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(filteredTasks) { task in
                                selectableTaskRow(task)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                } else {
                    // Normal mod — sectioned list
                    List(selection: $selectedTask) {
                        // ── Bekleyen Görevler ──
                        if !pendingFilteredTasks.isEmpty {
                            Section {
                                ForEach(pendingFilteredTasks) { task in
                                    dashboardTaskRow(task)
                                }
                                .onMove(perform: movePendingTask)
                            }
                        }
                        
                        // ── Tamamlanan Görevler ──
                        if !completedFilteredTasks.isEmpty {
                            Section {
                                ForEach(completedFilteredTasks) { task in
                                    dashboardTaskRow(task)
                                }
                            } header: {
                                completedSectionHeader
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
        }
        .navigationTitle(dashboard.name)
        #if os(macOS)
        .frame(minWidth: AppConstants.contentMinWidth)
        #endif
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Sıralama menüsü
                sortMenu
                
                // Toplu seçim modu toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSelectionMode.toggle()
                        if !isSelectionMode {
                            selectedTasks.removeAll()
                        }
                    }
                } label: {
                    Text(isSelectionMode ? "Seçimi Kapat" : "Görevleri Seç")
                }
                
                if isSelectionMode {
                    Button {
                        selectAll()
                    } label: {
                        Text(allSelected ? "Seçimi Temizle" : "Tümünü Seç")
                    }
                }
                
                Button {
                    isShowingEditDashboard = true
                } label: {
                    Label("Düzenle", systemImage: "pencil")
                }
                .help("Dashboard'u Düzenle")
                
                Button {
                    isShowingAddTask = true
                } label: {
                    Label("Görev Ekle", systemImage: "plus")
                }
                .help("Yeni Görev Ekle")
            }
        }
        .sheet(isPresented: $isShowingAddTask) {
            TaskFormView(dashboard: dashboard)
        }
        .sheet(isPresented: $isShowingEditDashboard) {
            DashboardFormView(dashboard: dashboard) { name, icon, colorHex in
                dashboard.name = name
                dashboard.icon = icon
                dashboard.colorHex = colorHex
            }
        }
        .onChange(of: isSelectionMode) { _, newValue in
            if !newValue {
                selectedTasks.removeAll()
            }
        }
    }
    
    // MARK: - Selectable Task Row
    
    private func selectableTaskRow(_ task: AgendaTask) -> some View {
        let isSelected = selectedTasks.contains(task)
        let color = Color(hex: dashboard.colorHex)
        
        return HStack(spacing: 12) {
            // Checkbox
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if isSelected {
                        selectedTasks.remove(task)
                    } else {
                        selectedTasks.insert(task)
                    }
                }
            } label: {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? color : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            
            // Renk şeridi
            RoundedRectangle(cornerRadius: 2)
                .fill(task.priority.color)
                .frame(width: 4, height: 40)
            
            // Görev bilgileri
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    PriorityBadgeView(priority: task.priority, showLabel: false)
                    
                    if let dueDate = task.dueDate {
                        Label(dueDate.shortFormatted, systemImage: "calendar")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(task.isOverdue ? .red : .secondary)
                    }
                    
                    if task.isCompleted {
                        Label("Tamamlandı", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? color.opacity(0.06) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? color.opacity(0.2) : .clear, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                if isSelected {
                    selectedTasks.remove(task)
                } else {
                    selectedTasks.insert(task)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var allSelected: Bool {
        !filteredTasks.isEmpty && selectedTasks.count == filteredTasks.count
    }
    
    private func selectAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if allSelected {
                selectedTasks.removeAll()
            } else {
                selectedTasks = Set(filteredTasks)
            }
        }
    }
    
    // MARK: - Dashboard Task Row Builder
    
    @ViewBuilder
    private func dashboardTaskRow(_ task: AgendaTask) -> some View {
        TaskRowView(task: task) {
            task.toggleCompletion()
        }
        .tag(task)
        .contextMenu {
            Button {
                task.toggleCompletion()
            } label: {
                Label(
                    task.isCompleted ? "Geri Al" : "Tamamla",
                    systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                )
            }
            
            Button {
                selectedTask = task
            } label: {
                Label("Düzenle", systemImage: "pencil")
            }
            
            Menu {
                Button {
                    task.dashboard = nil
                } label: {
                    Text("Hiçbiri")
                }
                
                ForEach(dashboards) { d in
                    Button {
                        task.dashboard = d
                    } label: {
                        HStack {
                            Image(systemName: d.icon)
                            Text(d.name)
                        }
                    }
                }
            } label: {
                Label("Taşı", systemImage: "folder")
            }
            
            Divider()
            
            Button(role: .destructive) {
                if selectedTask?.id == task.id {
                    selectedTask = nil
                }
                modelContext.delete(task)
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Completed Section Header
    
    private var completedSectionHeader: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isCompletedExpanded.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isCompletedExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                
                Text("Tamamlandı")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                
                Text("\(completedFilteredTasks.count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.green.opacity(0.12))
                    )
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Filtered Tasks
    
    private var filteredTasks: [AgendaTask] {
        var tasks = dashboard.tasks
        
        // Filtre uygula
        switch filterOption {
        case .all:
            break
        case .pending:
            tasks = tasks.filter { !$0.isCompleted }
        case .completed:
            tasks = tasks.filter { $0.isCompleted }
        case .overdue:
            tasks = tasks.filter { $0.isOverdue }
        case .highPriority:
            tasks = tasks.filter { $0.priority == .high }
        }
        
        // Arama filtresi
        if !searchText.isEmpty {
            tasks = tasks.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.taskDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sıralama
        switch sortOption {
        case .custom:
            return tasks.sorted { $0.sortIndex < $1.sortIndex }
        case .dateDesc:
            return tasks.sorted { $0.createdAt > $1.createdAt }
        case .dateAsc:
            return tasks.sorted { $0.createdAt < $1.createdAt }
        case .priorityDesc:
            return tasks.sorted { $0.priority.sortOrder > $1.priority.sortOrder }
        case .priorityAsc:
            return tasks.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
        case .dueDateAsc:
            return tasks.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .alphabetical:
            return tasks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
    
    /// Bekleyen görevler
    private var pendingFilteredTasks: [AgendaTask] {
        filteredTasks.filter { !$0.isCompleted }
    }
    
    /// Tamamlanmış görevler
    private var completedFilteredTasks: [AgendaTask] {
        filteredTasks.filter { $0.isCompleted }
    }
    
    // MARK: - Drag & Drop
    
    /// Bekleyen görevlerin sırasını sürükle-bırak ile değiştirir
    private func movePendingTask(from source: IndexSet, to destination: Int) {
        // Sürükleme yapıldığında otomatik olarak özel sıralamaya geç
        sortOption = .custom
        
        var pending = pendingFilteredTasks
        pending.move(fromOffsets: source, toOffset: destination)
        
        for (index, task) in pending.enumerated() {
            task.sortIndex = index
        }
        
        let completedTasks = completedFilteredTasks
        for (index, task) in completedTasks.enumerated() {
            task.sortIndex = pending.count + index
        }
    }
    
    // MARK: - Sort Menu
    
    private var sortMenu: some View {
        Menu {
            ForEach(TaskSortOption.allCases) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        sortOption = option
                    }
                } label: {
                    HStack {
                        if option == .custom {
                            Image(systemName: "hand.draw")
                        }
                        Text(option.displayName)
                        if sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label(
                sortOption == .custom ? "Özel Sıralama" : "Sırala",
                systemImage: sortOption == .custom ? "hand.draw.fill" : "arrow.up.arrow.down"
            )
            .font(.system(size: 13))
            .foregroundStyle(sortOption == .custom ? Color(hex: dashboard.colorHex) : .primary)
        }
    }
    
    private var emptyMessage: String {
        switch filterOption {
        case .all: return "Bu dashboard'a ilk görevinizi ekleyerek başlayın."
        case .pending: return "Tüm görevler tamamlanmış! 🎉"
        case .completed: return "Henüz tamamlanan görev yok."
        case .overdue: return "Gecikmiş görev yok. Harika! ✨"
        case .highPriority: return "Yüksek öncelikli görev yok."
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        Group {
            if sizeClass == .compact {
                VStack(spacing: 8) {
                    searchField
                        .frame(maxWidth: .infinity)
                    
                    HStack {
                        if isSelectionMode {
                            Text("\(selectedTasks.count)/\(filteredTasks.count) seçili")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: dashboard.colorHex))
                        }
                        
                        Spacer()
                        
                        filterPicker
                    }
                }
            } else {
                HStack(spacing: 8) {
                    searchField
                        .frame(maxWidth: 200)
                    
                    Spacer()
                    
                    if isSelectionMode {
                        Text("\(selectedTasks.count)/\(filteredTasks.count) seçili")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: dashboard.colorHex))
                    }
                    
                    filterPicker
                        .frame(maxWidth: 400)
                }
            }
        }
    }
    
    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            TextField("Görev ara...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.smallCornerRadius)
                .fill(.quaternary)
        )
    }
    
    private var filterPicker: some View {
        Picker("Filtre", selection: $filterOption) {
            ForEach(TaskFilterOption.allCases) { option in
                Text(option.displayName).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - TaskFilterOption

enum TaskFilterOption: String, CaseIterable, Identifiable {
    case all = "Tümü"
    case pending = "Bekleyen"
    case completed = "Tamamlanan"
    case overdue = "Gecikmiş"
    case highPriority = "Yüksek"
    
    var id: String { rawValue }
    var displayName: String { rawValue }
}

// MARK: - Preview

#Preview {
    let dashboard = Dashboard(name: "Teknofest", icon: "trophy.fill", colorHex: "#FF9500")
    return DashboardDetailView(dashboard: dashboard, selectedTask: .constant(nil))
        .modelContainer(for: [Dashboard.self, AgendaTask.self], inMemory: true)
}

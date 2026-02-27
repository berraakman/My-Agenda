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
    
    // MARK: - Properties
    
    let dashboard: Dashboard
    @Binding var selectedTask: AgendaTask?
    
    @Query(sort: \Dashboard.sortIndex)
    private var dashboards: [Dashboard]
    
    // MARK: - State
    
    @State private var isShowingAddTask = false
    @State private var isShowingEditDashboard = false
    @State private var filterOption: TaskFilterOption = .all
    @State private var searchText = ""
    
    /// Toplu işlem state
    @State private var isSelectionMode = false
    @State private var selectedTasks: Set<AgendaTask> = []
    
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
                    // Normal mod
                    List(filteredTasks, selection: $selectedTask) { task in
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
                    .listStyle(.inset)
                }
            }
        }
        .navigationTitle(dashboard.name)
        .frame(minWidth: AppConstants.contentMinWidth)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
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
        
        // Sıralama: önce tamamlanmayanlar, sonra önceliğe göre
        return tasks.sorted { a, b in
            if a.isCompleted != b.isCompleted {
                return !a.isCompleted
            }
            return a.priority.sortOrder > b.priority.sortOrder
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
        HStack(spacing: 8) {
            // Arama alanı
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
            .frame(maxWidth: 200)
            
            Spacer()
            
            if isSelectionMode {
                Text("\(selectedTasks.count)/\(filteredTasks.count) seçili")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: dashboard.colorHex))
            }
            
            // Filtre picker
            Picker("Filtre", selection: $filterOption) {
                ForEach(TaskFilterOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 400)
        }
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

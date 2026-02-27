//
//  TaskListView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import SwiftData

// MARK: - TaskListView
/// Tüm görevlerin listelendiği ana görünüm.
/// Global arama, filtreleme, sıralama ve toplu işlem destekler.
struct TaskListView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - SwiftData Query
    
    @Query(sort: \AgendaTask.createdAt, order: .reverse)
    private var allTasks: [AgendaTask]
    
    // MARK: - Bindings
    
    @Binding var selectedTask: AgendaTask?
    
    // MARK: - State
    
    @State private var searchText = ""
    @State private var filterOption: TaskFilterOption = .all
    @State private var sortOption: TaskSortOption = .dateDesc
    @State private var isShowingAddTask = false
    
    /// Toplu işlem state
    @State private var isSelectionMode = false
    @State private var selectedTasks: Set<AgendaTask> = []
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Üst bar: Arama + Filtre + Sıralama
            topBar
                .padding()
            
            Divider()
            
            // Özet satırı
            summaryBar
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            // Toplu işlem çubuğu (üstte)
            BulkActionBar(
                selectedTasks: $selectedTasks,
                isSelectionMode: $isSelectionMode
            )
            
            // Görev listesi
            if filteredTasks.isEmpty {
                EmptyStateView(
                    icon: emptyStateIcon,
                    title: emptyStateTitle,
                    message: emptyStateMessage,
                    buttonTitle: filterOption == .all ? "Görev Ekle" : nil,
                    onAction: filterOption == .all ? { isShowingAddTask = true } : nil
                )
            } else {
                if isSelectionMode {
                    // Seçim modu — checkbox'lu liste
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
                            withAnimation(AppConstants.springAnimation) {
                                task.toggleCompletion()
                            }
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
        .navigationTitle("Tüm Görevler")
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
                    isShowingAddTask = true
                } label: {
                    Label("Görev Ekle", systemImage: "plus")
                }
                .help("Yeni Görev Ekle")
            }
        }
        .sheet(isPresented: $isShowingAddTask) {
            TaskFormView()
        }
        .onChange(of: isSelectionMode) { _, newValue in
            if !newValue {
                selectedTasks.removeAll()
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(spacing: 12) {
            // Arama
            SearchBarView(text: $searchText)
                .frame(maxWidth: 220)
            
            Spacer()
            
            // Sıralama
            Menu {
                ForEach(TaskSortOption.allCases) { option in
                    Button {
                        sortOption = option
                    } label: {
                        HStack {
                            Text(option.displayName)
                            if sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Sırala", systemImage: "arrow.up.arrow.down")
                    .font(.system(size: 13))
            }
            
            // Filtre
            Picker("Filtre", selection: $filterOption) {
                ForEach(TaskFilterOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 360)
        }
    }
    
    // MARK: - Summary Bar
    
    private var summaryBar: some View {
        HStack(spacing: 16) {
            summaryItem(label: "Toplam", count: allTasks.count, color: .primary)
            summaryItem(label: "Bekleyen", count: allTasks.filter { !$0.isCompleted }.count, color: .orange)
            summaryItem(label: "Bugün", count: allTasks.filter { $0.isDueToday }.count, color: .blue)
            summaryItem(label: "Gecikmiş", count: allTasks.filter { $0.isOverdue }.count, color: .red)
            Spacer()
            
            if isSelectionMode {
                Text("\(selectedTasks.count)/\(filteredTasks.count) seçili")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private func summaryItem(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Selectable Task Row
    
    private func selectableTaskRow(_ task: AgendaTask) -> some View {
        let isSelected = selectedTasks.contains(task)
        let color = task.dashboard.map { Color(hex: $0.colorHex) } ?? task.priority.color
        
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
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            
            // Sol renk şeridi
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
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
                    
                    if let dashboard = task.dashboard {
                        HStack(spacing: 3) {
                            Image(systemName: dashboard.icon)
                                .font(.system(size: 9))
                            Text(dashboard.name)
                                .font(.system(size: 11, design: .rounded))
                        }
                        .foregroundStyle(Color(hex: dashboard.colorHex).opacity(0.7))
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
                .fill(isSelected ? Color.blue.opacity(0.06) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.blue.opacity(0.2) : .clear, lineWidth: 1)
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
        var tasks = allTasks
        
        // Arama filtresi
        if !searchText.isEmpty {
            tasks = tasks.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.taskDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Durum filtresi
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
        
        // Sıralama
        switch sortOption {
        case .dateDesc:
            tasks.sort { $0.createdAt > $1.createdAt }
        case .dateAsc:
            tasks.sort { $0.createdAt < $1.createdAt }
        case .priorityDesc:
            tasks.sort { $0.priority.sortOrder > $1.priority.sortOrder }
        case .priorityAsc:
            tasks.sort { $0.priority.sortOrder < $1.priority.sortOrder }
        case .dueDateAsc:
            tasks.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .alphabetical:
            tasks.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
        
        return tasks
    }
    
    // MARK: - Empty State Helpers
    
    private var emptyStateIcon: String {
        switch filterOption {
        case .all: return "tray"
        case .pending: return "checkmark.seal.fill"
        case .completed: return "tray"
        case .overdue: return "clock.badge.checkmark.fill"
        case .highPriority: return "flag"
        }
    }
    
    private var emptyStateTitle: String {
        switch filterOption {
        case .all: return "Henüz görev yok"
        case .pending: return "Tüm görevler tamamlandı!"
        case .completed: return "Tamamlanan görev yok"
        case .overdue: return "Gecikmiş görev yok"
        case .highPriority: return "Yüksek öncelikli görev yok"
        }
    }
    
    private var emptyStateMessage: String {
        switch filterOption {
        case .all: return "İlk görevinizi ekleyerek başlayın."
        case .pending: return "Harika iş çıkardınız! 🎉"
        case .completed: return "Görevleri tamamladıkça burada görünecek."
        case .overdue: return "Tüm görevleriniz zamanında. ✨"
        case .highPriority: return "Yüksek öncelikli görev bulunmuyor."
        }
    }
}

// MARK: - Preview

#Preview {
    TaskListView(selectedTask: .constant(nil))
        .modelContainer(for: [Dashboard.self, AgendaTask.self], inMemory: true)
}

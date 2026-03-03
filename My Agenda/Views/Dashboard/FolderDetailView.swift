//
//  FolderDetailView.swift
//  My Agenda
//
//  Created by Berra Akman on 01.03.2026.
//

import SwiftUI
import SwiftData

// MARK: - FolderDetailView
/// Sidebar'dan klasöre tıklandığında gösterilen detay sayfası.
/// Sadece o klasöre ait görevleri listeler.
struct FolderDetailView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let folder: DashboardFolder
    @Binding var selectedTask: AgendaTask?
    
    // MARK: - State
    
    @State private var isShowingAddTask = false
    @State private var isShowingEditFolder = false
    @State private var sortOption: TaskSortOption = .custom
    @State private var searchText = ""
    @State private var isCompletedExpanded = true
    
    // MARK: - Computed
    
    private var folderColor: Color {
        Color(hex: folder.colorHex)
    }
    
    private var filteredTasks: [AgendaTask] {
        var tasks = folder.tasks
        
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
    
    private var pendingTasks: [AgendaTask] {
        filteredTasks.filter { !$0.isCompleted }
    }
    
    private var completedTasks: [AgendaTask] {
        filteredTasks.filter { $0.isCompleted }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Klasör başlığı kartı
            folderHeader
                .padding()
            
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
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
            
            // Görev listesi
            if filteredTasks.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: "Klasör boş",
                    message: "Bu klasöre görev ekleyerek başlayın.",
                    buttonTitle: "Görev Ekle",
                    onAction: { isShowingAddTask = true }
                )
            } else {
                List(selection: $selectedTask) {
                    // Bekleyen görevler
                    if !pendingTasks.isEmpty {
                        Section {
                            ForEach(pendingTasks) { task in
                                TaskRowView(task: task) {
                                    task.toggleCompletion()
                                }
                                .tag(task)
                                .draggable(task.id.uuidString)
                                .contextMenu {
                                    taskContextMenu(task)
                                }
                            }
                            .onMove(perform: movePendingTask)
                        }
                    }
                    
                    // Tamamlanan görevler
                    if !completedTasks.isEmpty {
                        Section {
                            if isCompletedExpanded {
                                ForEach(completedTasks) { task in
                                    TaskRowView(task: task) {
                                        task.toggleCompletion()
                                    }
                                    .tag(task)
                                    .contextMenu {
                                        taskContextMenu(task)
                                    }
                                }
                            }
                        } header: {
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
                                    
                                    Text("\(completedTasks.count)")
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
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(folder.name)
        #if os(macOS)
        .frame(minWidth: AppConstants.contentMinWidth)
        #endif
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Sıralama menüsü
                Menu {
                    ForEach(TaskSortOption.allCases) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                sortOption = option
                            }
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
                }
                
                Button {
                    isShowingEditFolder = true
                } label: {
                    Label("Düzenle", systemImage: "pencil")
                }
                .help("Klasörü Düzenle")
                
                Button {
                    isShowingAddTask = true
                } label: {
                    Label("Görev Ekle", systemImage: "plus")
                }
                .help("Yeni Görev Ekle")
            }
        }
        .sheet(isPresented: $isShowingAddTask) {
            TaskFormView(dashboard: folder.dashboard, folder: folder)
        }
        .sheet(isPresented: $isShowingEditFolder) {
            if let dashboard = folder.dashboard {
                FolderFormView(dashboard: dashboard, folder: folder)
            }
        }
    }
    
    // MARK: - Folder Header
    
    private var folderHeader: some View {
        HStack(spacing: 14) {
            // Klasör ikonu
            Image(systemName: folder.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [folderColor, folderColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                HStack(spacing: 12) {
                    Label("\(folder.pendingTaskCount) bekleyen", systemImage: "clock")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    Label("\(folder.completedTaskCount) tamamlanan", systemImage: "checkmark.circle")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.green.opacity(0.8))
                    
                    if let dashboard = folder.dashboard {
                        HStack(spacing: 4) {
                            Image(systemName: dashboard.icon)
                                .font(.system(size: 10))
                            Text(dashboard.name)
                                .font(.system(size: 12, design: .rounded))
                        }
                        .foregroundStyle(Color(hex: dashboard.colorHex).opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            // İlerleme
            if folder.totalTaskCount > 0 {
                VStack(spacing: 4) {
                    ProgressRingView(
                        progress: folder.completionPercentage,
                        color: folderColor,
                        lineWidth: 3,
                        size: 36
                    )
                    Text("\(Int(folder.completionPercentage * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(folderColor.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(folderColor.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func taskContextMenu(_ task: AgendaTask) -> some View {
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
        
        Button {
            task.folder = nil
        } label: {
            Label("Klasörden Çıkar", systemImage: "folder.badge.minus")
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
    
    // MARK: - Drag & Drop
    
    private func movePendingTask(from source: IndexSet, to destination: Int) {
        sortOption = .custom
        
        var pending = pendingTasks
        pending.move(fromOffsets: source, toOffset: destination)
        
        for (index, task) in pending.enumerated() {
            task.sortIndex = index
        }
    }
}

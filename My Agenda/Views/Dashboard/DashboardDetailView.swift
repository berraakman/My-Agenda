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
/// Görev ekleme, filtreleme ve dashboard düzenleme işlemleri yapılabilir.
struct DashboardDetailView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let dashboard: Dashboard
    @Binding var selectedTask: AgendaTask?
    
    // MARK: - State
    
    @State private var isShowingAddTask = false
    @State private var isShowingEditDashboard = false
    @State private var filterOption: TaskFilterOption = .all
    @State private var searchText = ""
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // İlerleme kartı
            DashboardProgressView(dashboard: dashboard)
                .padding()
            
            // Filtre bar
            filterBar
                .padding(.horizontal)
                .padding(.bottom, 8)
            
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
                List(filteredTasks, selection: $selectedTask) { task in
                    TaskRowView(task: task) {
                        task.toggleCompletion()
                    }
                    .tag(task)
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(dashboard.name)
        .frame(minWidth: AppConstants.contentMinWidth)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
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

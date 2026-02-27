//
//  TaskViewModel.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation
import SwiftData

// MARK: - TaskViewModel
/// Görev yönetimi için iş mantığı katmanı.
/// CRUD, filtreleme, arama ve sıralama işlemlerini yönetir.
@Observable
final class TaskViewModel {
    
    // MARK: - Properties
    
    private let repository: TaskRepository
    
    /// Tüm görevler (mevcut filtre/arama sonucu)
    var tasks: [AgendaTask] = []
    
    /// Arama metni
    var searchText: String = "" {
        didSet { applyFilters() }
    }
    
    /// Aktif filtre
    var activeFilter: TaskFilterOption = .all {
        didSet { applyFilters() }
    }
    
    /// Sıralama seçeneği
    var sortOption: TaskSortOption = .dateDesc {
        didSet { applyFilters() }
    }
    
    // MARK: - Init
    
    init(modelContext: ModelContext) {
        self.repository = TaskRepository(modelContext: modelContext)
        loadTasks()
    }
    
    // MARK: - Public Methods
    
    /// Tüm görevleri yükler ve filtre/arama uygular
    func loadTasks() {
        if searchText.isEmpty {
            tasks = repository.fetchAll()
        } else {
            tasks = repository.search(query: searchText)
        }
        applyFilters()
    }
    
    /// Yeni görev oluşturur
    func createTask(
        title: String,
        taskDescription: String = "",
        priority: Priority = .medium,
        dueDate: Date? = nil,
        dueTime: Date? = nil,
        isRecurring: Bool = false,
        recurrenceType: RecurrenceType? = nil,
        dashboard: Dashboard? = nil
    ) {
        repository.create(
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            dueDate: dueDate,
            dueTime: dueTime,
            isRecurring: isRecurring,
            recurrenceType: recurrenceType,
            dashboard: dashboard
        )
        loadTasks()
    }
    
    /// Görevi günceller
    func updateTask(
        _ task: AgendaTask,
        title: String? = nil,
        taskDescription: String? = nil,
        priority: Priority? = nil,
        dueDate: Date?? = nil,
        dueTime: Date?? = nil,
        isRecurring: Bool? = nil,
        recurrenceType: RecurrenceType?? = nil,
        dashboard: Dashboard?? = nil
    ) {
        repository.update(
            task,
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            dueDate: dueDate,
            dueTime: dueTime,
            isRecurring: isRecurring,
            recurrenceType: recurrenceType,
            dashboard: dashboard
        )
        loadTasks()
    }
    
    /// Görev siler
    func deleteTask(_ task: AgendaTask) {
        repository.delete(task)
        loadTasks()
    }
    
    /// Tamamlanma durumunu toggle eder
    func toggleTaskCompletion(_ task: AgendaTask) {
        repository.toggleCompletion(task)
        loadTasks()
    }
    
    /// Bugünün görevlerini getirir
    func todayTasks() -> [AgendaTask] {
        return repository.fetchDueToday()
    }
    
    // MARK: - Private
    
    private func applyFilters() {
        var filtered: [AgendaTask]
        
        if searchText.isEmpty {
            filtered = repository.fetchAll()
        } else {
            filtered = repository.search(query: searchText)
        }
        
        // Filtre uygula
        switch activeFilter {
        case .all:
            break
        case .pending:
            filtered = filtered.filter { !$0.isCompleted }
        case .completed:
            filtered = filtered.filter { $0.isCompleted }
        case .overdue:
            filtered = filtered.filter { $0.isOverdue }
        case .highPriority:
            filtered = filtered.filter { $0.priority == .high }
        }
        
        // Sıralama uygula
        switch sortOption {
        case .dateDesc:
            filtered.sort { $0.createdAt > $1.createdAt }
        case .dateAsc:
            filtered.sort { $0.createdAt < $1.createdAt }
        case .priorityDesc:
            filtered.sort { $0.priority.sortOrder > $1.priority.sortOrder }
        case .priorityAsc:
            filtered.sort { $0.priority.sortOrder < $1.priority.sortOrder }
        case .dueDateAsc:
            filtered.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .alphabetical:
            filtered.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
        
        tasks = filtered
    }
}

// MARK: - TaskSortOption

enum TaskSortOption: String, CaseIterable, Identifiable {
    case dateDesc = "En Yeni"
    case dateAsc = "En Eski"
    case priorityDesc = "Öncelik (Yüksek→Düşük)"
    case priorityAsc = "Öncelik (Düşük→Yüksek)"
    case dueDateAsc = "Son Tarih"
    case alphabetical = "Alfabetik"
    
    var id: String { rawValue }
    var displayName: String { rawValue }
}

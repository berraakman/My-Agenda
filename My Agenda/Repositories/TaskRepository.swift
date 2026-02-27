//
//  TaskRepository.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation
import SwiftData

// MARK: - TaskRepository
/// AgendaTask modeli için veri erişim katmanı.
/// Tüm SwiftData CRUD operasyonları, filtreleme ve arama bu sınıf üzerinden yapılır.
@Observable
final class TaskRepository {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    // MARK: - Init
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch Operations
    
    /// Tüm görevleri getirir (oluşturulma tarihine göre sıralı)
    func fetchAll() -> [AgendaTask] {
        let descriptor = FetchDescriptor<AgendaTask>(
            sortBy: [SortDescriptor(\AgendaTask.createdAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Task fetch hatası: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Belirli bir dashboard'a ait görevleri getirir
    func fetchByDashboard(_ dashboard: Dashboard) -> [AgendaTask] {
        let dashboardId = dashboard.id
        let descriptor = FetchDescriptor<AgendaTask>(
            predicate: #Predicate { task in
                task.dashboard?.id == dashboardId
            },
            sortBy: [SortDescriptor(\AgendaTask.createdAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Dashboard task fetch hatası: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Tamamlanmamış görevleri getirir
    func fetchPending() -> [AgendaTask] {
        let descriptor = FetchDescriptor<AgendaTask>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\AgendaTask.dueDate, order: .forward)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Pending task fetch hatası: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Bugüne ait görevleri getirir
    func fetchDueToday() -> [AgendaTask] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<AgendaTask>(
            predicate: #Predicate { task in
                task.dueDate != nil &&
                task.dueDate! >= startOfDay &&
                task.dueDate! < endOfDay
            },
            sortBy: [SortDescriptor(\AgendaTask.dueDate, order: .forward)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Today task fetch hatası: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Arama sorgusuyla görev arar (başlık ve açıklamada)
    func search(query: String) -> [AgendaTask] {
        guard !query.isEmpty else { return fetchAll() }
        
        let lowercasedQuery = query.lowercased()
        let descriptor = FetchDescriptor<AgendaTask>(
            predicate: #Predicate { task in
                task.title.localizedStandardContains(lowercasedQuery) ||
                task.taskDescription.localizedStandardContains(lowercasedQuery)
            },
            sortBy: [SortDescriptor(\AgendaTask.createdAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Search hatası: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Yeni görev oluşturur
    @discardableResult
    func create(
        title: String,
        taskDescription: String = "",
        priority: Priority = .medium,
        dueDate: Date? = nil,
        dueTime: Date? = nil,
        isRecurring: Bool = false,
        recurrenceType: RecurrenceType? = nil,
        dashboard: Dashboard? = nil
    ) -> AgendaTask {
        let task = AgendaTask(
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            dueDate: dueDate,
            dueTime: dueTime,
            isRecurring: isRecurring,
            recurrenceType: recurrenceType,
            dashboard: dashboard
        )
        modelContext.insert(task)
        save()
        return task
    }
    
    /// Görev günceller
    func update(
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
        if let title = title { task.title = title }
        if let taskDescription = taskDescription { task.taskDescription = taskDescription }
        if let priority = priority { task.priority = priority }
        if let dueDate = dueDate { task.dueDate = dueDate }
        if let dueTime = dueTime { task.dueTime = dueTime }
        if let isRecurring = isRecurring { task.isRecurring = isRecurring }
        if let recurrenceType = recurrenceType { task.recurrenceType = recurrenceType }
        if let dashboard = dashboard { task.dashboard = dashboard }
        save()
    }
    
    /// Görev siler
    func delete(_ task: AgendaTask) {
        modelContext.delete(task)
        save()
    }
    
    /// Görevi tamamlandı/tamamlanmadı olarak işaretler
    func toggleCompletion(_ task: AgendaTask) {
        task.toggleCompletion()
        save()
    }
    
    // MARK: - Statistics
    
    /// Belirli tarih aralığında tamamlanan görev sayısı
    func completedCount(from startDate: Date, to endDate: Date) -> Int {
        let descriptor = FetchDescriptor<AgendaTask>(
            predicate: #Predicate { task in
                task.isCompleted &&
                task.completedAt != nil &&
                task.completedAt! >= startDate &&
                task.completedAt! <= endDate
            }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    /// Toplam görev sayısı
    func totalCount() -> Int {
        let descriptor = FetchDescriptor<AgendaTask>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    // MARK: - Private
    
    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("❌ Task save hatası: \(error.localizedDescription)")
        }
    }
}

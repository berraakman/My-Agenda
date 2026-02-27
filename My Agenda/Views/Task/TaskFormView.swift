//
//  TaskFormView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import SwiftData

// MARK: - TaskFormView
/// Görev oluşturma ve düzenleme for sheet.
/// Yeni görev ekleme veya mevcut görevi düzenleme modunda çalışır.
struct TaskFormView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - SwiftData Query
    
    @Query(sort: \Dashboard.sortIndex)
    private var dashboards: [Dashboard]
    
    // MARK: - Mode
    
    /// Düzenlenecek görev (nil ise yeni görev modu)
    let existingTask: AgendaTask?
    
    /// Varsayılan dashboard (yeni görev eklerken)
    let defaultDashboard: Dashboard?
    
    // MARK: - State
    
    @State private var title: String = ""
    @State private var taskDescription: String = ""
    @State private var priority: Priority = .medium
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var hasDueTime: Bool = false
    @State private var dueTime: Date = Date()
    @State private var isRecurring: Bool = false
    @State private var recurrenceType: RecurrenceType = .daily
    @State private var selectedDashboard: Dashboard?
    
    // MARK: - Computed
    
    private var isEditing: Bool { existingTask != nil }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var formTitle: String {
        isEditing ? "Görevi Düzenle" : "Yeni Görev"
    }
    
    // MARK: - Init
    
    /// Yeni görev modu
    init(dashboard: Dashboard? = nil) {
        self.existingTask = nil
        self.defaultDashboard = dashboard
    }
    
    /// Düzenleme modu
    init(task: AgendaTask) {
        self.existingTask = task
        self.defaultDashboard = task.dashboard
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Form içeriği
            Form {
                // Başlık
                Section("Görev Bilgileri") {
                    TextField("Görev başlığı...", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .rounded))
                    
                    // Açıklama
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Açıklama")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        TextEditor(text: $taskDescription)
                            .font(.system(.body, design: .rounded))
                            .frame(minHeight: 60, maxHeight: 120)
                            .scrollContentBackground(.hidden)
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.quaternary)
                            )
                    }
                }
                
                // Öncelik
                Section("Öncelik") {
                    HStack(spacing: 8) {
                        ForEach(Priority.allCases) { p in
                            Button {
                                priority = p
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: p.iconName)
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(p.displayName)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                .foregroundStyle(priority == p ? .white : p.color)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(priority == p ? p.color : p.color.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(priority == p ? p.color : .clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Tarih & Saat
                Section("Tarih ve Saat") {
                    Toggle("Son tarih belirle", isOn: $hasDueDate.animation())
                    
                    if hasDueDate {
                        DatePicker(
                            "Son tarih",
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        
                        Toggle("Saat belirle", isOn: $hasDueTime.animation())
                        
                        if hasDueTime {
                            DatePicker(
                                "Saat",
                                selection: $dueTime,
                                displayedComponents: .hourAndMinute
                            )
                        }
                    }
                }
                
                // Tekrarlama
                Section("Tekrarlama") {
                    Toggle("Tekrarlayan görev", isOn: $isRecurring.animation())
                    
                    if isRecurring {
                        Picker("Tekrarlama tipi", selection: $recurrenceType) {
                            ForEach(RecurrenceType.allCases) { type in
                                HStack {
                                    Image(systemName: type.iconName)
                                    Text(type.displayName)
                                }
                                .tag(type)
                            }
                        }
                    }
                }
                
                // Dashboard seçimi
                Section("Dashboard") {
                    Picker("Dashboard", selection: $selectedDashboard) {
                        Text("Hiçbiri")
                            .tag(nil as Dashboard?)
                        
                        ForEach(dashboards) { dashboard in
                            HStack {
                                Image(systemName: dashboard.icon)
                                    .foregroundStyle(Color(hex: dashboard.colorHex))
                                Text(dashboard.name)
                            }
                            .tag(dashboard as Dashboard?)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // Footer
            footer
        }
        .frame(width: 480, height: 640)
        .onAppear {
            loadExistingData()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text(formTitle)
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
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            Spacer()
            
            Button("İptal") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            
            Button(isEditing ? "Kaydet" : "Oluştur") {
                saveTask()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(!isFormValid)
        }
        .padding()
    }
    
    // MARK: - Methods
    
    /// Mevcut görev verilerini form'a yükler (düzenleme modu)
    private func loadExistingData() {
        if let task = existingTask {
            title = task.title
            taskDescription = task.taskDescription
            priority = task.priority
            hasDueDate = task.dueDate != nil
            dueDate = task.dueDate ?? Date()
            hasDueTime = task.dueTime != nil
            dueTime = task.dueTime ?? Date()
            isRecurring = task.isRecurring
            recurrenceType = task.recurrenceType ?? .daily
            selectedDashboard = task.dashboard
        } else {
            selectedDashboard = defaultDashboard
        }
    }
    
    /// Görevi kaydeder (yeni oluşturma veya güncelleme)
    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        
        if let task = existingTask {
            // Güncelleme
            task.title = trimmedTitle
            task.taskDescription = taskDescription
            task.priority = priority
            task.dueDate = hasDueDate ? dueDate : nil
            task.dueTime = (hasDueDate && hasDueTime) ? dueTime : nil
            task.isRecurring = isRecurring
            task.recurrenceType = isRecurring ? recurrenceType : nil
            task.dashboard = selectedDashboard
        } else {
            // Yeni görev
            let task = AgendaTask(
                title: trimmedTitle,
                taskDescription: taskDescription,
                priority: priority,
                dueDate: hasDueDate ? dueDate : nil,
                dueTime: (hasDueDate && hasDueTime) ? dueTime : nil,
                isRecurring: isRecurring,
                recurrenceType: isRecurring ? recurrenceType : nil,
                dashboard: selectedDashboard
            )
            modelContext.insert(task)
        }
    }
}

// MARK: - Preview

#Preview("Yeni Görev") {
    TaskFormView()
        .modelContainer(for: [Dashboard.self, AgendaTask.self], inMemory: true)
}

#Preview("Düzenleme") {
    let task = AgendaTask(title: "Test Görevi", priority: .high, dueDate: Date())
    return TaskFormView(task: task)
        .modelContainer(for: [Dashboard.self, AgendaTask.self], inMemory: true)
}

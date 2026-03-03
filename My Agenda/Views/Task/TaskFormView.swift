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
    @Environment(NotificationService.self) private var notificationService
    
    // MARK: - SwiftData Query
    
    @Query(sort: \Dashboard.sortIndex)
    private var dashboards: [Dashboard]
    
    // MARK: - Mode
    
    /// Düzenlenecek görev (nil ise yeni görev modu)
    let existingTask: AgendaTask?
    
    /// Varsayılan dashboard (yeni görev eklerken)
    let defaultDashboard: Dashboard?
    
    /// Varsayılan klasör (yeni görev eklerken)
    let defaultFolder: DashboardFolder?
    
    // MARK: - State
    
    @State private var title: String = ""
    @State private var taskDescription: String = ""
    @State private var priority: Priority = .medium
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var hasDueTime: Bool = false
    @State private var dueTime: Date = Date()
    @State private var addToCalendar: Bool = false
    @State private var isRecurring: Bool = false
    @State private var recurrenceType: RecurrenceType = .daily
    @State private var recurringDaysOfWeek: [Int] = []
    @State private var selectedDashboard: Dashboard?
    @State private var selectedFolder: DashboardFolder?
    
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
    init(dashboard: Dashboard? = nil, folder: DashboardFolder? = nil) {
        self.existingTask = nil
        self.defaultDashboard = dashboard
        self.defaultFolder = folder
    }
    
    /// Düzenleme modu
    init(task: AgendaTask) {
        self.existingTask = task
        self.defaultDashboard = task.dashboard
        self.defaultFolder = task.folder
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
                        
                        if recurrenceType == .customDays {
                            customDaysSelectionView
                        }
                    }
                }
                
                // Anımsatıcı
                Section("Bildirimler") {
                    Toggle("Uygulama İçi Anımsatıcı Ekle", isOn: $addToCalendar.animation())
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
                    
                    // Klasör seçimi (sadece seçili dashboard'un klasörleri varsa)
                    if let dash = selectedDashboard, !dash.folders.isEmpty {
                        Picker("Klasör", selection: $selectedFolder) {
                            Text("Genel (Klasörsüz)")
                                .tag(nil as DashboardFolder?)
                            
                            ForEach(dash.folders.sorted(by: { $0.sortIndex < $1.sortIndex })) { folder in
                                HStack {
                                    Image(systemName: folder.icon)
                                        .foregroundStyle(Color(hex: folder.colorHex))
                                    Text(folder.name)
                                }
                                .tag(folder as DashboardFolder?)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // Footer
            footer
        }
        #if os(macOS)
        .frame(width: 480, height: 640)
        #endif
        .onAppear {
            loadExistingData()
        }
        .onChange(of: selectedDashboard) { _, newDashboard in
            // Dashboard değiştiğinde klasör seçimini sıfırla
            if newDashboard?.id != selectedFolder?.dashboard?.id {
                selectedFolder = nil
            }
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
            addToCalendar = task.addToCalendar
            isRecurring = task.isRecurring
            recurrenceType = task.recurrenceType ?? .daily
            recurringDaysOfWeek = task.recurringDaysOfWeek ?? []
            selectedDashboard = task.dashboard
            selectedFolder = task.folder
        } else {
            selectedDashboard = defaultDashboard
            selectedFolder = defaultFolder
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
            task.addToCalendar = addToCalendar
            task.isRecurring = isRecurring
            task.recurrenceType = isRecurring ? recurrenceType : nil
            task.recurringDaysOfWeek = (isRecurring && recurrenceType == .customDays) ? recurringDaysOfWeek : nil
            task.dashboard = selectedDashboard
            task.folder = selectedDashboard != nil ? selectedFolder : nil
        }
        
        let savedTask = existingTask ?? {
            let newTask = AgendaTask(
                title: trimmedTitle,
                taskDescription: taskDescription,
                priority: priority,
                dueDate: hasDueDate ? dueDate : nil,
                dueTime: (hasDueDate && hasDueTime) ? dueTime : nil,
                isRecurring: isRecurring,
                recurrenceType: isRecurring ? recurrenceType : nil,
                recurringDaysOfWeek: (isRecurring && recurrenceType == .customDays) ? recurringDaysOfWeek : nil,
                addToCalendar: addToCalendar,
                dashboard: selectedDashboard
            )
            newTask.folder = selectedDashboard != nil ? selectedFolder : nil
            modelContext.insert(newTask)
            return newTask
        }()
        
        if addToCalendar {
            notificationService.scheduleNotification(for: savedTask)
        } else {
            notificationService.cancelNotification(for: savedTask)
        }
    }
    
    private var customDaysSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tekrarlanacak Günler")
                .font(.system(size: 13, weight: .medium, design: .rounded))
            
            HStack(spacing: 8) {
                let days = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
                let calendarDays = [2, 3, 4, 5, 6, 7, 1] // Apple Calendar: 1=Pazar, 2=Pazartesi vb.
                
                ForEach(0..<7, id: \.self) { index in
                    let dayInt = calendarDays[index]
                    let isSelected = recurringDaysOfWeek.contains(dayInt)
                    
                    Button {
                        withAnimation {
                            if isSelected {
                                recurringDaysOfWeek.removeAll(where: { $0 == dayInt })
                            } else {
                                recurringDaysOfWeek.append(dayInt)
                            }
                        }
                    } label: {
                        Text(days[index])
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
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

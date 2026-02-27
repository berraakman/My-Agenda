//
//  TaskInlineEditor.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import SwiftData

// MARK: - TaskInlineEditor
/// Seçili görevin hızlı, modern ve şık düzenleme ekranı.
/// Form görünümü yerine özel kartlı tasarım kullanılarak estetik artırılmıştır.
struct TaskInlineEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationService.self) private var notificationService
    
    @Bindable var task: AgendaTask
    @Binding var selectedTask: AgendaTask?
    
    @Query(sort: \Dashboard.sortIndex)
    private var dashboards: [Dashboard]
    
    // Custom states
    @State private var hasDueDate: Bool = false
    @State private var hasDueTime: Bool = false
    @State private var isHoveringCompletion: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header (Başlık & Tamamlanma)
                headerSection
                
                // MARK: - Açıklama
                descriptionSection
                
                // MARK: - Öncelik
                prioritySection
                
                // MARK: - Tarih ve Saat
                dateTimeSection
                
                // MARK: - Detaylar (Takvim & Dashboard)
                detailsSection
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(NSColor.textBackgroundColor).opacity(0.3)) // Hafif transparan zemin
        .navigationTitle("Detaylar")
        .frame(minWidth: AppConstants.detailMinWidth)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(role: .destructive) {
                    selectedTask = nil
                    modelContext.delete(task)
                } label: {
                    Label("Görevi Sil", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                .help("Görevi Sil")
            }
        }
        .onAppear {
            hasDueDate = (task.dueDate != nil)
            hasDueTime = (task.dueTime != nil)
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    task.toggleCompletion()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(task.isCompleted ? Color.green : (isHoveringCompletion ? Color.blue : Color.gray))
                    .symbolEffect(.bounce, value: task.isCompleted)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringCompletion = $0 }
            
            TextField("Görev Başlığı", text: $task.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .textFieldStyle(.plain)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Açıklama", icon: "text.alignleft")
            
            TextEditor(text: $task.taskDescription)
                .font(.system(.body, design: .rounded))
                .frame(minHeight: 80, maxHeight: 150)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Öncelik", icon: "flag.fill")
            
            HStack(spacing: 8) {
                ForEach(Priority.allCases) { p in
                    Button {
                        withAnimation { task.priority = p }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: p.iconName)
                            Text(p.displayName)
                                .fontWeight(.medium)
                        }
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(task.priority == p ? .white : p.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(task.priority == p ? p.color : p.color.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(task.priority == p ? p.color : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Tarih ve Saat", icon: "calendar.badge.clock")
            
            VStack(spacing: 0) {
                // Son Tarih Toggle
                customToggleRow(title: "Zaman Belirle", isOn: $hasDueDate)
                
                if hasDueDate {
                    Divider().padding(.leading, 16)
                    
                    HStack {
                        DatePicker(
                            "Son Tarih",
                            selection: Binding(
                                get: { task.dueDate ?? Date() },
                                set: { task.dueDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        
                        Spacer()
                    }
                    .padding(16)
                    
                    Divider().padding(.leading, 16)
                    
                    customToggleRow(title: "Saat Belirle", isOn: $hasDueTime)
                    
                    if hasDueTime {
                        Divider().padding(.leading, 16)
                        
                        HStack {
                            DatePicker(
                                "Saat",
                                selection: Binding(
                                    get: { task.dueTime ?? Date() },
                                    set: { task.dueTime = $0 }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            Spacer()
                        }
                        .padding(16)
                    }
                }
            }
            .background(cardBackground)
            .onChange(of: hasDueDate) { _, newValue in
                withAnimation {
                    if !newValue {
                        task.dueDate = nil
                        hasDueTime = false
                        task.dueTime = nil
                    } else if task.dueDate == nil {
                        task.dueDate = Date()
                    }
                }
            }
            .onChange(of: hasDueTime) { _, newValue in
                withAnimation {
                    if !newValue {
                        task.dueTime = nil
                    } else if task.dueTime == nil {
                        task.dueTime = Date()
                    }
                }
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Ekstra", icon: "slider.horizontal.3")
            
            VStack(spacing: 0) {
                // Dashboard
                HStack {
                    Text("Dashboard")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                    Spacer()
                    Picker("", selection: $task.dashboard) {
                        Text("Hiçbiri").tag(nil as Dashboard?)
                        ForEach(dashboards) { d in
                            HStack {
                                Image(systemName: d.icon)
                                Text(d.name)
                            }
                            .tag(d as Dashboard?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
                .padding(16)
                
                Divider().padding(.leading, 16)
                
                // Tekrarlama toggle
                customToggleRow(title: "Tekrarlayan Görev", isOn: $task.isRecurring)
                
                if task.isRecurring {
                    Divider().padding(.leading, 16)
                    
                    HStack {
                        Text("Tekrarlama Tipi")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                        Spacer()
                        Picker("", selection: Binding(
                            get: { task.recurrenceType ?? .daily },
                            set: { task.recurrenceType = $0 }
                        )) {
                            ForEach(RecurrenceType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                    .padding(16)
                    
                    if task.recurrenceType == .customDays {
                        Divider().padding(.leading, 16)
                        customDaysSelectionView
                    }
                }
                
                Divider().padding(.leading, 16)
                // Anımsatıcı toggle
                customToggleRow(title: "Uygulama İçi Anımsatıcı Ekle", isOn: $task.addToCalendar)
            }
            .background(cardBackground)
            .onChange(of: task.addToCalendar) { _, _ in
                syncTaskToCalendarIfNeeded()
            }
            .onChange(of: task.isRecurring) { _, newValue in
                withAnimation {
                    if !newValue {
                        task.recurrenceType = nil
                        task.recurringDaysOfWeek = nil
                    } else if task.recurrenceType == nil {
                        task.recurrenceType = .daily
                    }
                }
                syncTaskToCalendarIfNeeded()
            }
            .onChange(of: task.recurrenceType) { _, _ in
                syncTaskToCalendarIfNeeded()
            }
            .onChange(of: task.recurringDaysOfWeek) { _, _ in
                syncTaskToCalendarIfNeeded()
            }
        }
    }
    
    // MARK: - Handlers
    
    private func syncTaskToCalendarIfNeeded() {
        if task.addToCalendar {
            notificationService.scheduleNotification(for: task)
        } else {
            notificationService.cancelNotification(for: task)
        }
    }
    
    // MARK: - UI Helpers
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 4)
    }
    
    private func customToggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(16)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(NSColor.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
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
                    let isSelected = task.recurringDaysOfWeek?.contains(dayInt) ?? false
                    
                    Button {
                        withAnimation {
                            if isSelected {
                                task.recurringDaysOfWeek?.removeAll(where: { $0 == dayInt })
                            } else {
                                if task.recurringDaysOfWeek == nil { task.recurringDaysOfWeek = [] }
                                task.recurringDaysOfWeek?.append(dayInt)
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
        .padding(16)
    }
}

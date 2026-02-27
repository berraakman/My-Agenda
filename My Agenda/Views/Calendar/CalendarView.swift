
//
//  CalendarView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import SwiftData
import EventKit

// MARK: - CalendarView
/// Ana takvim ekranı — 3 sekmeli:
/// 1. Haftalık Ajanda (zaman çizelgeli dijital planlayıcı)
/// 2. Aylık Takvim (grid görünüm)
/// 3. Apple Calendar (EventKit entegrasyonu)
struct CalendarView: View {
    
    // MARK: - Environment
    
    @Environment(CalendarService.self) private var calendarService
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Query
    
    @Query(
        filter: #Predicate<AgendaTask> { !$0.isCompleted },
        sort: \AgendaTask.dueDate
    )
    private var pendingTasks: [AgendaTask]
    
    @Binding var selectedTask: AgendaTask?
    
    // MARK: - State
    
    @State private var selectedTab: CalendarTab = .weekly
    @State private var calendarViewModel: CalendarViewModel?
    @State private var isShowingTaskPicker = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Sekme Seçici
            tabPicker
            
            // İçerik
            switch selectedTab {
            case .weekly:
                WeeklyAgendaView(selectedTask: $selectedTask)
                
            case .monthly:
                MonthlyCalendarView(selectedTask: $selectedTask)
                
            case .appleCalendar:
                appleCalendarContent
            }
        }
        .navigationTitle("Takvim")
        .frame(minWidth: AppConstants.contentMinWidth)
        .onAppear {
            if calendarViewModel == nil {
                calendarViewModel = CalendarViewModel(calendarService: calendarService)
            }
        }
    }
    
    // MARK: - Tab Picker
    
    private var tabPicker: some View {
        HStack {
            Picker("Görünüm", selection: $selectedTab) {
                ForEach(CalendarTab.allCases) { tab in
                    Label(tab.displayName, systemImage: tab.icon).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 400)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }
    
    // MARK: - Apple Calendar Content
    
    private var appleCalendarContent: some View {
        Group {
            AppleCalendarMonthlyView()
        }
        .sheet(isPresented: $isShowingTaskPicker) {
            taskPickerSheet
        }
        .toolbar {
            if calendarService.isAuthorized && selectedTab == .appleCalendar {
                ToolbarItemGroup(placement: .automatic) {
                    Button {
                        isShowingTaskPicker = true
                    } label: {
                        Label("Görevi Takvime Ekle", systemImage: "calendar.badge.plus")
                    }
                    .help("Görevi Takvime Ekle")
                    
                    Button {
                        calendarViewModel?.loadEvents()
                    } label: {
                        Label("Yenile", systemImage: "arrow.clockwise")
                    }
                    .help("Yenile")
                }
            }
        }
    }
    
    // MARK: - Task Picker Sheet
    
    private var taskPickerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Takvime Eklenecek Görevi Seçin")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button { isShowingTaskPicker = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            let eligible = pendingTasks.filter { $0.dueDate != nil }
            
            if eligible.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.exclamationmark",
                    title: "Uygun görev yok",
                    message: "Takvime eklemek için son tarihi olan bekleyen görev gerekli."
                )
            } else {
                List(eligible) { task in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                            if let d = task.dueDate {
                                Text(d.dateTimeFormatted)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if task.calendarEventId != nil {
                            Label("Eklendi", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.green)
                        } else {
                            Button("Ekle") {
                                _ = calendarService.createEventFromTask(task)
                                calendarViewModel?.loadEvents()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(width: 440, height: 380)
    }
}

// MARK: - CalendarTab

enum CalendarTab: String, CaseIterable, Identifiable {
    case weekly = "Haftalık"
    case monthly = "Aylık"
    case appleCalendar = "Apple Calendar"
    
    var id: String { rawValue }
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .weekly: return "calendar.day.timeline.left"
        case .monthly: return "calendar"
        case .appleCalendar: return "apple.logo"
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarView(selectedTask: .constant(nil))
        .environment(CalendarService())
        .modelContainer(for: [Dashboard.self, AgendaTask.self], inMemory: true)
}

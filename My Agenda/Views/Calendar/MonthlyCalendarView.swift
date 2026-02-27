//
//  MonthlyCalendarView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import SwiftData

// MARK: - MonthlyCalendarView
/// Aylık takvim görünümü — standart grid formatında.
/// Her günde görev göstergeleri, aylar arası ileri-geri navigasyon.
/// Bir güne tıklandığında o günün görevleri detaylı listelenir.
struct MonthlyCalendarView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Query
    
    @Query(sort: \AgendaTask.dueDate)
    private var allTasks: [AgendaTask]
    
    @Query(sort: \Dashboard.sortIndex)
    private var dashboards: [Dashboard]
    
    // MARK: - Bindings
    
    @Binding var selectedTask: AgendaTask?
    
    // MARK: - State
    
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var isShowingAddTask = false
    
    // MARK: - Constants
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdaySymbols = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
    
    // MARK: - Computed
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth).capitalized
    }
    
    private var daysInMonth: [DateDay] {
        generateDays(for: currentMonth)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // ════════════════════════════════════════
            // ÜST BAR: Navigasyon
            // ════════════════════════════════════════
            monthNavigationBar
            
            Divider()
            
            // ════════════════════════════════════════
            // İÇERİK: Takvim + Gün Detayı
            // ════════════════════════════════════════
            HSplitView {
                // Sol: Aylık grid
                VStack(spacing: 0) {
                    // Gün adları başlığı
                    weekdayHeader
                    
                    Divider()
                    
                    // Takvim grid'i
                    calendarGrid
                }
                .frame(minWidth: 380)
                
                // Sağ: Seçili günün görevleri
                selectedDayDetail
                    .frame(minWidth: 260, idealWidth: 300)
            }
        }
        .sheet(isPresented: $isShowingAddTask) {
            TaskFormView()
        }
    }
    
    // MARK: - Month Navigation Bar
    
    private var monthNavigationBar: some View {
        HStack(spacing: 16) {
            Text(monthTitle)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            
            Spacer()
            
            HStack(spacing: 4) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        navigateMonth(by: -1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
                }
                .buttonStyle(.plain)
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentMonth = Date()
                        selectedDate = Date()
                    }
                } label: {
                    Text("Bugün")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.blue.opacity(0.12)))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        navigateMonth(by: 1)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
                }
                .buttonStyle(.plain)
            }
            
            Divider().frame(height: 20)
            
            Button {
                isShowingAddTask = true
            } label: {
                Label("Görev Ekle", systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
    
    // MARK: - Weekday Header
    
    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .background(.bar.opacity(0.5))
    }
    
    // MARK: - Calendar Grid
    
    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(daysInMonth) { dateDay in
                dayCellView(dateDay)
            }
        }
        .padding(4)
    }
    
    // MARK: - Day Cell
    
    private func dayCellView(_ dateDay: DateDay) -> some View {
        let isToday = Calendar.current.isDateInToday(dateDay.date)
        let isSelected = Calendar.current.isDate(dateDay.date, inSameDayAs: selectedDate)
        let isCurrentMonth = dateDay.isCurrentMonth
        let tasks = tasksForDay(dateDay.date)
        let completedCount = tasks.filter { $0.isCompleted }.count
        let pendingCount = tasks.count - completedCount
        
        return VStack(spacing: 3) {
            // Gün numarası
            ZStack {
                if isToday {
                    Circle()
                        .fill(.blue)
                        .frame(width: 26, height: 26)
                }
                
                Text("\(Calendar.current.component(.day, from: dateDay.date))")
                    .font(.system(size: 12, weight: isToday || isSelected ? .bold : .regular, design: .rounded))
                    .foregroundStyle(
                        isToday ? .white :
                        !isCurrentMonth ? Color.gray.opacity(0.3) :
                        .primary
                    )
            }
            
            // Görev göstergeleri
            if !tasks.isEmpty && isCurrentMonth {
                VStack(spacing: 2) {
                    // Görev noktaları
                    HStack(spacing: 2) {
                        ForEach(Array(tasks.prefix(3).enumerated()), id: \.offset) { _, task in
                            Circle()
                                .fill(task.isCompleted ? .green : priorityColor(task.priority))
                                .frame(width: 5, height: 5)
                        }
                    }
                    
                    if pendingCount > 0 {
                        Text("\(pendingCount)")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    isSelected ? .blue.opacity(0.08) :
                    isToday ? .blue.opacity(0.03) :
                    .clear
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? .blue.opacity(0.3) : .clear, lineWidth: 1)
                )
        )
        .opacity(isCurrentMonth ? 1 : 0.3)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = dateDay.date
            }
        }
    }
    
    // MARK: - Selected Day Detail
    
    private var selectedDayDetail: some View {
        let tasks = tasksForDay(selectedDate)
        
        return VStack(spacing: 0) {
            // Başlık
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDate.longFormatted)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text(selectedDate.relativeFormatted)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                Text("\(tasks.count) görev")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.quaternary))
            }
            .padding()
            
            Divider()
            
            // Görev listesi
            if tasks.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.quaternary)
                    Text("Bu güne ait görev yok")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(tasks) { task in
                            dayTaskRow(task)
                        }
                    }
                    .padding(8)
                }
            }
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Day Task Row
    
    private func dayTaskRow(_ task: AgendaTask) -> some View {
        let color = task.dashboard.map { Color(hex: $0.colorHex) } ?? priorityColor(task.priority)
        
        return HStack(spacing: 8) {
            // Tamamlanma toggle
            Button {
                withAnimation { task.toggleCompletion() }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // Sol renk şeridi
            RoundedRectangle(cornerRadius: 1.5)
                .fill(color)
                .frame(width: 3, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if let time = task.dueTime {
                        Text(time.timeFormatted)
                            .font(.system(size: 10, design: .monospaced))
                    }
                    
                    PriorityBadgeView(priority: task.priority, showLabel: false)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.05))
        )
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
    
    // MARK: - Helpers
    
    private func tasksForDay(_ day: Date) -> [AgendaTask] {
        return allTasks.filter { task in
            task.isScheduled(for: day)
        }.sorted { a, b in
            (a.dueTime ?? Date.distantFuture) < (b.dueTime ?? Date.distantFuture)
        }
    }
    
    private func navigateMonth(by offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    /// Ayın takvim grid'i için tüm günleri üretir (önceki/sonraki aydan boşluk günleri dahil)
    private func generateDays(for monthDate: Date) -> [DateDay] {
        let calendar = Calendar.current
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else { return [] }
        
        // Pazartesi = 1 offset ayarlaması (Calendar.current default: Pazar = 1)
        let mondayOffset = (firstWeekday + 5) % 7
        
        var days: [DateDay] = []
        
        // Önceki aydan dolgu günleri
        for i in (0..<mondayOffset).reversed() {
            if let day = calendar.date(byAdding: .day, value: -(i + 1), to: monthInterval.start) {
                days.append(DateDay(date: day, isCurrentMonth: false))
            }
        }
        
        // Mevcut ayın günleri
        var date = monthInterval.start
        while date < monthInterval.end {
            days.append(DateDay(date: date, isCurrentMonth: true))
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        // Sonraki aydan dolgu günleri (6 satır tamamlama)
        let remainingDays = 42 - days.count // 6 satır × 7 gün
        for i in 0..<remainingDays {
            if let day = calendar.date(byAdding: .day, value: i, to: monthInterval.end) {
                days.append(DateDay(date: day, isCurrentMonth: false))
            }
        }
        
        return days
    }
}

// MARK: - DateDay Model

struct DateDay: Identifiable {
    let id = UUID()
    let date: Date
    let isCurrentMonth: Bool
}

// MARK: - Preview

#Preview {
    MonthlyCalendarView(selectedTask: .constant(nil))
        .modelContainer(for: [Dashboard.self, AgendaTask.self], inMemory: true)
        .frame(width: 750, height: 500)
}

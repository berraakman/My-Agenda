//
//  WeeklyAgendaView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import SwiftData

// MARK: - WeeklyAgendaView
/// Dijital ajanda haftalık sayfa görünümü.
/// Fiziksel bir ajandadaki gibi 7 günü yan yana gösterir.
/// Her günde o güne ait görevler ve zaman dilimleri yer alır.
/// İleri-geri navigasyon ile haftalar arasında gezinilir.
struct WeeklyAgendaView: View {
    
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
    
    /// Gösterilen haftanın referans tarihi (haftanın pazartesi günü)
    @State private var currentWeekStart: Date = Date().startOfWeek
    @State private var selectedDay: Date = Date()
    @State private var isShowingAddTask = false
    @State private var selectedTaskForDetail: AgendaTask?
    
    // MARK: - Constants
    
    private let hourRange = 6...23 // 06:00 - 23:00
    private let hourHeight: CGFloat = 56
    
    // MARK: - Computed
    
    private var weekDays: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: currentWeekStart) }
    }
    
    private var weekTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM"
        let start = formatter.string(from: currentWeekStart)
        let end = formatter.string(from: weekDays.last ?? currentWeekStart)
        
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        let year = yearFormatter.string(from: currentWeekStart)
        
        return "\(start) – \(end), \(year)"
    }
    
    private var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: currentWeekStart)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // ════════════════════════════════════════
            // ÜST BAR: Navigasyon + Hafta bilgisi
            // ════════════════════════════════════════
            weekNavigationBar
            
            Divider()
            
            // ════════════════════════════════════════
            // GÜN BAŞLIKLARI
            // ════════════════════════════════════════
            dayHeaderBar
            
            Divider()
            
            // ════════════════════════════════════════
            // AJANDA İÇERİĞİ: Zaman çizelgesi + Görevler
            // ════════════════════════════════════════
            ScrollView(.vertical, showsIndicators: true) {
                HStack(spacing: 0) {
                    // Sol: Saat etiketleri
                    timeLabelsColumn
                    
                    // 7 gün sütunları
                    ForEach(weekDays, id: \.self) { day in
                        dayColumn(for: day)
                        
                        if day != weekDays.last {
                            Divider()
                        }
                    }
                }
            }
            .scrollIndicators(.visible)
        }
        .sheet(isPresented: $isShowingAddTask) {
            TaskFormView()
        }
        .sheet(item: $selectedTaskForDetail) { task in
            taskQuickView(task)
        }
    }
    
    // MARK: - Week Navigation Bar
    
    private var weekNavigationBar: some View {
        HStack(spacing: 16) {
            // Hafta numarası badge
            Text("Hafta \(weekNumber)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(.blue.gradient)
                )
            
            // Hafta başlığı
            Text(weekTitle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
            
            Spacer()
            
            // Navigasyon butonları
            HStack(spacing: 4) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        navigateWeek(by: -1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.quaternary)
                        )
                }
                .buttonStyle(.plain)
                .help("Önceki Hafta")
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        goToToday()
                    }
                } label: {
                    Text("Bugün")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.blue.opacity(0.12))
                        )
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        navigateWeek(by: 1)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.quaternary)
                        )
                }
                .buttonStyle(.plain)
                .help("Sonraki Hafta")
            }
            
            Divider().frame(height: 20)
            
            // Yeni görev ekle
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
    
    // MARK: - Day Header Bar
    
    private var dayHeaderBar: some View {
        HStack(spacing: 0) {
            // Boşluk (saat sütunu kadar)
            Color.clear
                .frame(width: 56, height: 1)
            
            ForEach(weekDays, id: \.self) { day in
                let isToday = Calendar.current.isDateInToday(day)
                let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDay)
                
                VStack(spacing: 4) {
                    // Gün adı
                    Text(dayName(for: day))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(isToday ? .blue : .secondary)
                    
                    // Gün numarası
                    ZStack {
                        if isToday {
                            Circle()
                                .fill(.blue)
                                .frame(width: 30, height: 30)
                        } else if isSelected {
                            Circle()
                                .fill(.blue.opacity(0.15))
                                .frame(width: 30, height: 30)
                        }
                        
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.system(size: 14, weight: isToday ? .bold : .medium, design: .rounded))
                            .foregroundStyle(isToday ? .white : .primary)
                    }
                    
                    // Görev sayısı göstergesi
                    let taskCount = tasksForDay(day).count
                    if taskCount > 0 {
                        HStack(spacing: 2) {
                            ForEach(0..<min(taskCount, 3), id: \.self) { _ in
                                Circle()
                                    .fill(.blue.opacity(0.6))
                                    .frame(width: 4, height: 4)
                            }
                            if taskCount > 3 {
                                Text("+\(taskCount - 3)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: 6)
                    } else {
                        Color.clear.frame(height: 6)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected && !isToday ? .blue.opacity(0.05) : .clear)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDay = day
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(.bar.opacity(0.5))
    }
    
    // MARK: - Time Labels Column
    
    private var timeLabelsColumn: some View {
        VStack(spacing: 0) {
            ForEach(Array(hourRange), id: \.self) { hour in
                HStack {
                    Spacer()
                    Text(String(format: "%02d:00", hour))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(width: 56, height: hourHeight)
                .overlay(alignment: .top) {
                    Divider().opacity(0.3)
                }
            }
        }
    }
    
    // MARK: - Day Column
    
    private func dayColumn(for day: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(day)
        let tasks = tasksForDay(day)
        
        return ZStack(alignment: .topLeading) {
            // Arka plan zaman çizgileri
            VStack(spacing: 0) {
                ForEach(Array(hourRange), id: \.self) { hour in
                    Rectangle()
                        .fill(.clear)
                        .frame(height: hourHeight)
                        .overlay(alignment: .top) {
                            Divider().opacity(0.15)
                        }
                        .overlay(alignment: .top) {
                            // Yarım saat çizgisi
                            Divider().opacity(0.07)
                                .padding(.top, hourHeight / 2)
                        }
                }
            }
            .background(isToday ? Color.blue.opacity(0.02) : .clear)
            
            // Şu anki saat çizgisi (bugün ise)
            if isToday {
                currentTimeLine
            }
            
            // Görevler
            ForEach(tasks) { task in
                taskBlock(task, in: day)
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }
    
    // MARK: - Current Time Line
    
    private var currentTimeLine: some View {
        GeometryReader { geometry in
            let now = Date()
            let hour = Calendar.current.component(.hour, from: now)
            let minute = Calendar.current.component(.minute, from: now)
            let hourOffset = CGFloat(hour - hourRange.lowerBound)
            let minuteOffset = CGFloat(minute) / 60.0
            let yPosition = (hourOffset + minuteOffset) * hourHeight
            
            if hour >= hourRange.lowerBound && hour <= hourRange.upperBound {
                HStack(spacing: 0) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .offset(x: -4)
                    
                    Rectangle()
                        .fill(.red)
                        .frame(height: 1.5)
                }
                .offset(y: yPosition)
            }
        }
    }
    
    // MARK: - Task Block
    
    private func taskBlock(_ task: AgendaTask, in day: Date) -> some View {
        let yPos = taskYPosition(for: task)
        let color = task.dashboard.map { Color(hex: $0.colorHex) } ?? priorityColor(task.priority)
        
        return Button {
            selectedTaskForDetail = task
        } label: {
            HStack(spacing: 4) {
                // Sol renk şeridi
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 3)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(task.title)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    if let time = task.dueTime {
                        Text(time.timeFormatted)
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer(minLength: 0)
                
                if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(color.opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2)
        .offset(y: yPos)
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
    
    // MARK: - Task Quick View Sheet
    
    private func taskQuickView(_ task: AgendaTask) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: task.isCompleted ? "checkmark.seal.fill" : "circle.dotted")
                    .font(.system(size: 24))
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.title3)
                        .fontWeight(.bold)
                    PriorityBadgeView(priority: task.priority)
                }
                
                Spacer()
                
                Button {
                    selectedTaskForDetail = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                if let dueDate = task.dueDate {
                    Label(dueDate.longFormatted, systemImage: "calendar")
                        .font(.system(size: 14, design: .rounded))
                }
                if let dueTime = task.dueTime {
                    Label(dueTime.timeFormatted, systemImage: "clock")
                        .font(.system(size: 14, design: .rounded))
                }
                if let dashboard = task.dashboard {
                    Label(dashboard.name, systemImage: dashboard.icon)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(Color(hex: dashboard.colorHex))
                }
                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Spacer()
            
            Divider()
            
            HStack {
                Button {
                    task.toggleCompletion()
                    selectedTaskForDetail = nil
                } label: {
                    Label(task.isCompleted ? "Geri Al" : "Tamamla", systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle")
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding()
        }
        .frame(width: 360, height: 320)
    }
    
    // MARK: - Helpers
    
    private func tasksForDay(_ day: Date) -> [AgendaTask] {
        return allTasks.filter { task in
            task.isScheduled(for: day)
        }
    }
    
    private func taskYPosition(for task: AgendaTask) -> CGFloat {
        guard let dueTime = task.dueTime else {
            // Saat bilgisi yoksa 08:00 gibi göster
            return CGFloat(8 - hourRange.lowerBound) * hourHeight
        }
        let hour = Calendar.current.component(.hour, from: dueTime)
        let minute = Calendar.current.component(.minute, from: dueTime)
        let offset = CGFloat(hour - hourRange.lowerBound) + CGFloat(minute) / 60.0
        return offset * hourHeight
    }
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private func navigateWeek(by offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) {
            currentWeekStart = newDate.startOfWeek
        }
    }
    
    private func goToToday() {
        currentWeekStart = Date().startOfWeek
        selectedDay = Date()
    }
}

// MARK: - Date Extension for Week Start

extension Date {
    /// Haftanın pazartesi gününü döner
    var startOfWeek: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        components.weekday = 2 // Pazartesi
        return calendar.date(from: components) ?? self
    }
}

// MARK: - Preview

#Preview {
    WeeklyAgendaView(selectedTask: .constant(nil))
        .modelContainer(for: [Dashboard.self, AgendaTask.self], inMemory: true)
        .frame(width: 900, height: 600)
}

//
//  AppleCalendarMonthlyView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import EventKit

// MARK: - AppleCalendarMonthlyView
/// Apple Calendar etkinliklerini aylık grid formatında gösterir.
struct AppleCalendarMonthlyView: View {
    
    // MARK: - Environment
    
    @Environment(CalendarService.self) private var calendarService
    
    // MARK: - State
    
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var isShowingTaskPicker = false
    
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
            if !calendarService.isAuthorized {
                 // İzin isteme ekranı
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.secondary)
                    
                    Text("Takvim Erişimi Gerekli")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("Apple Calendar etkinliklerinizi görüntülemek için izin verin.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 350)
                    
                    Button {
                        Task {
                            let _ = await calendarService.requestAccess()
                            calendarService.fetchThisMonthEvents() // Load current month
                        }
                    } label: {
                        Label("İzin Ver", systemImage: "lock.open.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else {
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
                    
                    // Sağ: Seçili günün etkinlikleri
                    selectedDayDetail
                        .frame(minWidth: 260, idealWidth: 300)
                }
            }
        }
        .onAppear {
            if calendarService.isAuthorized {
                loadEventsForCurrentMonth()
            }
        }
        .onChange(of: currentMonth) { _, _ in
            if calendarService.isAuthorized {
                loadEventsForCurrentMonth()
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadEventsForCurrentMonth() {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        
        // Önceki ayın görünür günleri dahil
        let startDay = calendar.component(.weekday, from: startOfMonth) // Pazar=1, Pzt=2...
        let adjustedStartDay = startDay == 1 ? 7 : startDay - 1
        let firstVisibleDate = calendar.date(byAdding: .day, value: -(adjustedStartDay - 1), to: startOfMonth) ?? startOfMonth
        
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? currentMonth
        // Sonraki ayın görünür günleri dahil
        let endDay = calendar.component(.weekday, from: endOfMonth)
        let adjustedEndDay = endDay == 1 ? 7 : endDay - 1
        let lastVisibleDate = calendar.date(byAdding: .day, value: 7 - adjustedEndDay, to: endOfMonth) ?? endOfMonth
        
        calendarService.fetchEvents(from: firstVisibleDate, to: lastVisibleDate)
    }
    
    // MARK: - Month Navigation Bar
    
    private var monthNavigationBar: some View {
        HStack(spacing: 16) {
            Text(monthTitle)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            
            if calendarService.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
            
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
        let events = eventsForDay(dateDay.date)
        
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
            
            // Etkinlik göstergeleri
            if !events.isEmpty && isCurrentMonth {
                VStack(spacing: 2) {
                    // Etkinlik noktaları
                    HStack(spacing: 2) {
                        ForEach(Array(events.prefix(3).enumerated()), id: \.offset) { _, event in
                            Circle()
                                .fill(Color(nsColor: event.calendar.color))
                                .frame(width: 5, height: 5)
                        }
                    }
                    
                    if events.count > 3 {
                        Text("+\(events.count - 3)")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
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
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = dateDay.date
            }
        }
    }
    
    // MARK: - Selected Day Detail
    
    private var selectedDayDetail: some View {
        let events = eventsForDay(selectedDate)
        
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
                
                Text("\(events.count) etkinlik")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.quaternary))
            }
            .padding()
            
            Divider()
            
            // Etkinlik listesi
            if events.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.quaternary)
                    Text("Bu güne ait etkinlik yok")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(events, id: \.eventIdentifier) { event in
                            CalendarEventRow(event: event)
                        }
                    }
                    .padding(8)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func eventsForDay(_ date: Date) -> [EKEvent] {
        calendarService.events.filter { event in
            // Etkinlik başlangıcı o güne düşüyorsa VEYA etkinlik gün boyunca sürüyorsa (startDate ve endDate kapsıyorsa)
            let isSameDay = Calendar.current.isDate(event.startDate, inSameDayAs: date)
            let spansDate = date >= Calendar.current.startOfDay(for: event.startDate) && date <= event.endDate
            return isSameDay || spansDate
        }.sorted { $0.startDate < $1.startDate }
    }
    
    private func navigateMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func generateDays(for date: Date) -> [DateDay] {
        var days: [DateDay] = []
        let calendar = Calendar.current
        
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        
        let startDay = calendar.component(.weekday, from: startOfMonth) // Pazar=1, Pzt=2...
        let adjustedStartDay = startDay == 1 ? 7 : startDay - 1
        
        let prevMonth = calendar.date(byAdding: .month, value: -1, to: date) ?? date
        let daysInPrevMonth = calendar.range(of: .day, in: .month, for: prevMonth)?.count ?? 30
        
        for i in Array(stride(from: adjustedStartDay - 1, to: 0, by: -1)) {
            let dayNum = daysInPrevMonth - i + 1
            if let date = calendar.date(bySetting: .day, value: dayNum, of: prevMonth) {
                days.append(DateDay(date: date, isCurrentMonth: false))
            }
        }
        
        for i in 1...daysInMonth {
            if let date = calendar.date(bySetting: .day, value: i, of: startOfMonth) {
                days.append(DateDay(date: date, isCurrentMonth: true))
            }
        }
        
        let remainingDays = 42 - days.count
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        
        if remainingDays > 0 {
            for i in 1...remainingDays {
                if let date = calendar.date(bySetting: .day, value: i, of: nextMonth) {
                    days.append(DateDay(date: date, isCurrentMonth: false))
                }
            }
        }
        
        return days
    }
}

// MARK: - Preview

#Preview {
    AppleCalendarMonthlyView()
        .environment(CalendarService())
}

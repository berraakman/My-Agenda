//
//  TodayOverviewView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import SwiftData

// MARK: - TodayOverviewView
/// Uygulamanın ana ekranı — "Bugün" genel bakışı.
/// Büyük, ferah, detaylı kartlar ile zengin bir dashboard deneyimi.
struct TodayOverviewView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    @Query(sort: \AgendaTask.dueDate)
    private var allTasks: [AgendaTask]
    
    @Query(sort: \Dashboard.sortIndex)
    private var dashboards: [Dashboard]
    
    // MARK: - Bindings
    
    @Binding var selectedTask: AgendaTask?
    @Binding var selectedSidebarItem: SidebarItem?
    
    // MARK: - State
    
    @State private var isShowingAddTask = false
    @State private var currentTime = Date()
    @State private var hoveredDashboard: Dashboard?
    
    // Timer
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    // MARK: - Computed
    
    private var todayTasks: [AgendaTask] {
        allTasks.filter { $0.isDueToday }
            .sorted { a, b in
                if a.isCompleted != b.isCompleted { return !a.isCompleted }
                return (a.dueTime ?? .distantFuture) < (b.dueTime ?? .distantFuture)
            }
    }
    
    private var upcomingTasks: [AgendaTask] {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: Date())!
        
        return allTasks.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return dueDate >= tomorrow && dueDate <= nextWeek
        }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
    
    private var overdueTasks: [AgendaTask] {
        allTasks.filter { $0.isOverdue }
    }
    
    private var todayCompleted: Int {
        todayTasks.filter { $0.isCompleted }.count
    }
    
    private var totalPending: Int {
        allTasks.filter { !$0.isCompleted }.count
    }
    
    private var totalCompleted: Int {
        allTasks.filter { $0.isCompleted }.count
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Günaydın ☀️"
        case 12..<18: return "İyi Günler 🌤️"
        case 18..<22: return "İyi Akşamlar 🌆"
        default: return "İyi Geceler 🌙"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ════════════════════════════════════════
                // HERO HEADER
                // ════════════════════════════════════════
                heroHeader
                
                // ════════════════════════════════════════
                // İSTATİSTİK KARTLARI
                // ════════════════════════════════════════
                statsRow
                
                // ════════════════════════════════════════
                // GECİKMİŞ GÖREVLER UYARISI
                // ════════════════════════════════════════
                if !overdueTasks.isEmpty {
                    overdueWarning
                }
                
                // ════════════════════════════════════════
                // DASHBOARD KARTLARI (Grid)
                // ════════════════════════════════════════
                dashboardCardsSection
                
                // ════════════════════════════════════════
                // ANA İÇERİK: BUGÜNKÜ + YAKLASAN
                // ════════════════════════════════════════
                HStack(alignment: .top, spacing: 20) {
                    todayTasksCard
                    
                    upcomingTasksCard
                }
            }
            .padding(28)
        }
        .navigationTitle("Genel Bakış")
        .frame(minWidth: AppConstants.contentMinWidth)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    isShowingAddTask = true
                } label: {
                    Label("Yeni Görev", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .sheet(isPresented: $isShowingAddTask) {
            TaskFormView()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - Hero Header
    
    private var heroHeader: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(greeting)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(Date().longFormatted)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                
                // Mini özet
                HStack(spacing: 16) {
                    Label("\(todayTasks.count) görev bugün", systemImage: "sun.max.fill")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.orange)
                    
                    if !overdueTasks.isEmpty {
                        Label("\(overdueTasks.count) gecikmiş", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.red)
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            // Dijital saat
            VStack(alignment: .trailing, spacing: 4) {
                Text(currentTime.timeFormatted)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                    .monospacedDigit()
                
                Text(dayOfWeekFull)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.07), .purple.opacity(0.05), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.blue.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: 16) {
            statCard(
                icon: "sun.max.fill",
                title: "Bugün",
                value: "\(todayTasks.count)",
                subtitle: "\(todayCompleted) tamamlandı",
                color: .orange,
                detail: todayTasks.isEmpty ? "Görev yok" : "\(todayTasks.count - todayCompleted) kalan"
            )
            
            statCard(
                icon: "clock.fill",
                title: "Bekleyen",
                value: "\(totalPending)",
                subtitle: "toplam görev",
                color: .blue,
                detail: "\(allTasks.count) toplam"
            )
            
            statCard(
                icon: "exclamationmark.triangle.fill",
                title: "Gecikmiş",
                value: "\(overdueTasks.count)",
                subtitle: overdueTasks.isEmpty ? "problem yok ✓" : "acil dikkat!",
                color: overdueTasks.isEmpty ? .green : .red,
                detail: overdueTasks.isEmpty ? "Temiz" : overdueTasks.first?.title ?? ""
            )
            
            statCard(
                icon: "checkmark.seal.fill",
                title: "Tamamlanan",
                value: "\(totalCompleted)",
                subtitle: "başarı",
                color: .green,
                detail: allTasks.isEmpty ? "—" : "%\(Int(Double(totalCompleted) / Double(max(allTasks.count, 1)) * 100)) oran"
            )
        }
    }
    
    private func statCard(icon: String, title: String, value: String, subtitle: String, color: Color, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // İkon satırı
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.gradient)
                    )
                
                Spacer()
            }
            
            // Değer
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            // Başlık
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            
            // Alt bilgi
            Text(subtitle)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
            
            // Detay
            Text(detail)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Overdue Warning
    
    private var overdueWarning: some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("⚠️ \(overdueTasks.count) gecikmiş görev var!")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
                
                Text(overdueTasks.prefix(3).map { $0.title }.joined(separator: " • "))
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button {
                selectedSidebarItem = .allTasks
            } label: {
                Text("Tümünü Göster")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.red.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.red.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Today Tasks Card
    
    private var todayTasksCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Başlık
            HStack {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.orange)
                
                Text("Bugünün Görevleri")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                
                Spacer()
                
                Text("\(todayCompleted)/\(todayTasks.count)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(.primary.opacity(0.06))
                    )
            }
            
            // Progress bar
            if !todayTasks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.primary.opacity(0.08))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.green.gradient)
                                .frame(
                                    width: geo.size.width * (todayTasks.isEmpty ? 0 : CGFloat(todayCompleted) / CGFloat(todayTasks.count)),
                                    height: 8
                                )
                                .animation(.easeInOut(duration: 0.5), value: todayCompleted)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("%\(todayTasks.isEmpty ? 0 : Int(Double(todayCompleted) / Double(todayTasks.count) * 100)) tamamlandı")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Divider()
            
            // Görev listesi
            if todayTasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.green.opacity(0.4))
                    Text("Bugün için görev yok")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                    Text("Yeni görev eklemek için sağ üstteki butonu kullanın")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.quaternary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(todayTasks) { task in
                    todayTaskRow(task)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private func todayTaskRow(_ task: AgendaTask) -> some View {
        let color = task.dashboard.map { Color(hex: $0.colorHex) } ?? task.priority.color
        
        return HStack(spacing: 14) {
            // Toggle
            Button {
                withAnimation(AppConstants.springAnimation) {
                    task.toggleCompletion()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            
            // Renk şeridi
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4, height: 36)
            
            // Bilgiler
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let time = task.dueTime {
                        Label(time.timeFormatted, systemImage: "clock")
                            .font(.system(size: 11, design: .rounded))
                    }
                    
                    PriorityBadgeView(priority: task.priority, showLabel: false)
                    
                    if let dashboard = task.dashboard {
                        HStack(spacing: 3) {
                            Image(systemName: dashboard.icon)
                                .font(.system(size: 9))
                            Text(dashboard.name)
                                .font(.system(size: 11, design: .rounded))
                        }
                        .foregroundStyle(Color(hex: dashboard.colorHex).opacity(0.8))
                    }
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Kalan süre
            if !task.isCompleted, let days = task.daysUntilDue {
                if days < 0 {
                    Text("Gecikmiş")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.red.opacity(0.1)))
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(task.isCompleted ? .green.opacity(0.03) : color.opacity(0.03))
        )
    }
    
    // MARK: - Upcoming Tasks Card
    
    private var upcomingTasksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
                
                Text("Yaklaşan Görevler")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                
                Spacer()
                
                Text("7 gün")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(.primary.opacity(0.05))
                    )
            }
            
            Divider()
            
            if upcomingTasks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(.tertiary)
                        Text("Yaklaşan görev yok")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            } else {
                ForEach(upcomingTasks.prefix(6)) { task in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(task.priority.color)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .lineLimit(1)
                            
                            if let dashboard = task.dashboard {
                                Text(dashboard.name)
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(Color(hex: dashboard.colorHex).opacity(0.7))
                            }
                        }
                        
                        Spacer()
                        
                        if let dueDate = task.dueDate {
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(dueDate.relativeFormatted)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                                
                                Text(dueDate.shortFormatted)
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if upcomingTasks.count > 6 {
                    Text("ve \(upcomingTasks.count - 6) görev daha...")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Dashboard Cards Section
    
    private var dashboardCardsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Bölüm başlığı
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.purple)
                
                Text("Dashboard'larım")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                Spacer()
                
                Text("\(dashboards.count) dashboard")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            
            if dashboards.isEmpty {
                // Boş durum
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(.tertiary)
                        Text("Henüz dashboard yok")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.tertiary)
                        Text("Sidebar'daki + butonuyla yeni dashboard oluşturun")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.quaternary)
                    }
                    Spacer()
                }
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(.primary.opacity(0.04), lineWidth: 1)
                        )
                )
            } else {
                // Dashboard kartları grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(dashboards) { dashboard in
                        dashboardCard(dashboard)
                    }
                }
            }
        }
    }
    
    // MARK: - Individual Dashboard Card
    
    private func dashboardCard(_ dashboard: Dashboard) -> some View {
        let color = Color(hex: dashboard.colorHex)
        let isHovered = hoveredDashboard?.id == dashboard.id
        let percentage = Int(dashboard.completionPercentage * 100)
        
        return Button {
            selectedSidebarItem = .dashboard(dashboard)
        } label: {
            VStack(spacing: 0) {
                // Üst kısım: Gradient header
                HStack {
                    // İkon
                    Image(systemName: dashboard.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.2))
                        )
                    
                    Spacer()
                    
                    // Progress ring
                    ProgressRingView(
                        progress: dashboard.completionPercentage,
                        color: .white,
                        lineWidth: 3.5,
                        size: 44,
                        showPercentage: false
                    )
                    .overlay {
                        Text("\(percentage)%")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [color, color.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Alt kısım: Bilgiler
                VStack(alignment: .leading, spacing: 12) {
                    // Dashboard adı
                    Text(dashboard.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    // İstatistikler
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(dashboard.totalTaskCount)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Text("Toplam")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(dashboard.completedTaskCount)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.green)
                            Text("Bitti")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(dashboard.pendingTaskCount)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.orange)
                            Text("Bekleyen")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        
                        if dashboard.overdueTaskCount > 0 {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(dashboard.overdueTaskCount)")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(.red)
                                Text("Gecikmiş")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.primary.opacity(0.06))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(color.gradient)
                                .frame(
                                    width: geo.size.width * CGFloat(dashboard.completionPercentage),
                                    height: 6
                                )
                        }
                    }
                    .frame(height: 6)
                }
                .padding(16)
                .background(.ultraThinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isHovered ? color.opacity(0.4) : .primary.opacity(0.06), lineWidth: isHovered ? 2 : 1)
            )
            .shadow(color: isHovered ? color.opacity(0.15) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredDashboard = hover ? dashboard : nil
            }
        }
    }
    
    // MARK: - Helpers
    
    private var dayOfWeekFull: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date()).capitalized
    }
}

// MARK: - Preview

#Preview {
    TodayOverviewView(
        selectedTask: .constant(nil),
        selectedSidebarItem: .constant(.allTasks)
    )
    .modelContainer(for: [Dashboard.self, AgendaTask.self], inMemory: true)
}

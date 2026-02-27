//
//  StatisticsView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import SwiftData

// MARK: - StatisticsView
/// Ana istatistik sayfası.
/// Genel özet, tamamlanma grafiği ve dashboard bazlı analiz içerir.
struct StatisticsView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var viewModel: StatisticsViewModel?
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Genel özet kartları
                if let vm = viewModel {
                    overviewCards(vm)
                    
                    // Son 7 gün grafiği
                    CompletionChartView(data: vm.dailyCompletionData)
                    
                    // Dashboard analizi
                    DashboardAnalyticsView(stats: vm.dashboardStats)
                }
            }
            .padding()
        }
        .navigationTitle("İstatistikler")
        .frame(minWidth: AppConstants.contentMinWidth)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    viewModel?.loadStatistics()
                } label: {
                    Label("Yenile", systemImage: "arrow.clockwise")
                }
                .help("İstatistikleri Yenile")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = StatisticsViewModel(modelContext: modelContext)
            }
            viewModel?.loadStatistics()
        }
    }
    
    // MARK: - Overview Cards
    
    private func overviewCards(_ vm: StatisticsViewModel) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            overviewCard(
                icon: "checklist",
                title: "Toplam Görev",
                value: "\(vm.totalTasks)",
                color: .blue
            )
            
            overviewCard(
                icon: "checkmark.circle.fill",
                title: "Tamamlanan",
                value: "\(vm.completedTasks)",
                color: .green
            )
            
            overviewCard(
                icon: "clock.fill",
                title: "Bekleyen",
                value: "\(vm.pendingTasks)",
                color: .orange
            )
            
            overviewCard(
                icon: "percent",
                title: "Başarı Oranı",
                value: "\(Int(vm.completionRate * 100))%",
                color: vm.completionRate >= 0.7 ? .green : (vm.completionRate >= 0.4 ? .orange : .red)
            )
        }
    }
    
    private func overviewCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    StatisticsView()
        .modelContainer(for: [Dashboard.self, AgendaTask.self], inMemory: true)
}

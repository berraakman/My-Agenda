//
//  CompletionChartView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import Charts

// MARK: - CompletionChartView
/// Son 7 günün tamamlanan görev grafiği.
/// SwiftUI Charts framework kullanır.
struct CompletionChartView: View {
    
    // MARK: - Properties
    
    let data: [DailyCompletion]
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Başlık
            Label("Son 7 Gün — Tamamlanan Görevler", systemImage: "chart.bar.fill")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            
            // Grafik
            Chart(data) { item in
                BarMark(
                    x: .value("Gün", item.dayName),
                    y: .value("Tamamlanan", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.7), .blue],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
                .annotation(position: .top, spacing: 4) {
                    if item.count > 0 {
                        Text("\(item.count)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 11, design: .rounded))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(.quaternary)
                    AxisValueLabel()
                        .font(.system(size: 11, design: .rounded))
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Preview

#Preview {
    let sampleData = [
        DailyCompletion(date: Date(), dayName: "Pzt", count: 3),
        DailyCompletion(date: Date(), dayName: "Sal", count: 5),
        DailyCompletion(date: Date(), dayName: "Çar", count: 2),
        DailyCompletion(date: Date(), dayName: "Per", count: 7),
        DailyCompletion(date: Date(), dayName: "Cum", count: 4),
        DailyCompletion(date: Date(), dayName: "Cmt", count: 1),
        DailyCompletion(date: Date(), dayName: "Paz", count: 6),
    ]
    
    return CompletionChartView(data: sampleData)
        .frame(width: 500)
        .padding()
}

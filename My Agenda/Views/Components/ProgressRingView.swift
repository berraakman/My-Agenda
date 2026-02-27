//
//  ProgressRingView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI

// MARK: - ProgressRingView
/// Dairesel ilerleme göstergesi.
/// Dashboard tamamlanma yüzdesi ve sidebar istatistikleri için kullanılır.
struct ProgressRingView: View {
    
    // MARK: - Properties
    
    /// İlerleme değeri (0.0 – 1.0 arası)
    let progress: Double
    
    /// Halka rengi
    var color: Color = .accentColor
    
    /// Halka kalınlığı
    var lineWidth: CGFloat = 4
    
    /// Boyut (genişlik & yükseklik)
    var size: CGFloat = 32
    
    /// Yüzde metnini göster/gizle
    var showPercentage: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Arka plan halkası
            Circle()
                .stroke(
                    color.opacity(0.15),
                    lineWidth: lineWidth
                )
            
            // İlerleme halkası
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(AppConstants.standardAnimation, value: progress)
            
            // Yüzde metni (opsiyonel)
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview("Küçük") {
    HStack(spacing: 20) {
        ProgressRingView(progress: 0.0, color: .red)
        ProgressRingView(progress: 0.25, color: .orange)
        ProgressRingView(progress: 0.5, color: .blue)
        ProgressRingView(progress: 0.75, color: .green)
        ProgressRingView(progress: 1.0, color: .purple)
    }
    .padding()
}

#Preview("Büyük + Yüzde") {
    ProgressRingView(
        progress: 0.73,
        color: .blue,
        lineWidth: 8,
        size: 80,
        showPercentage: true
    )
    .padding()
}

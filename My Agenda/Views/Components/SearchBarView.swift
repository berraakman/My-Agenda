//
//  SearchBarView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI

// MARK: - SearchBarView
/// Reusable arama çubuğu bileşeni.
/// Görev listelerinde arama yapmak için kullanılır.
struct SearchBarView: View {
    
    // MARK: - Bindings
    
    @Binding var text: String
    var placeholder: String = "Görev ara..."
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .rounded))
            
            if !text.isEmpty {
                Button {
                    withAnimation(AppConstants.standardAnimation) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.smallCornerRadius)
                .fill(.quaternary)
        )
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var text = ""
    SearchBarView(text: $text)
        .frame(width: 250)
        .padding()
}

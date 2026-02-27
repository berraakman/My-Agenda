//
//  EmptyStateView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI

// MARK: - EmptyStateView
/// Boş durum görünümü — liste boş olduğunda kullanıcıya bilgi ve aksiyon sunar.
/// Reusable: Farklı ekranlarda farklı mesaj ve ikonlarla kullanılabilir.
struct EmptyStateView: View {
    
    // MARK: - Properties
    
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var onAction: (() -> Void)? = nil
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Ikon
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse, options: .repeating)
            
            // Başlık
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            // Mesaj
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            
            // Aksiyon butonu (opsiyonel)
            if let buttonTitle = buttonTitle, let onAction = onAction {
                Button(action: onAction) {
                    Label(buttonTitle, systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.top, 4)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Boş Dashboard") {
    EmptyStateView(
        icon: "tray",
        title: "Henüz görev yok",
        message: "Bu dashboard'a ilk görevinizi ekleyerek başlayın.",
        buttonTitle: "Görev Ekle",
        onAction: { }
    )
}

#Preview("Butonsuz") {
    EmptyStateView(
        icon: "calendar.badge.exclamationmark",
        title: "Takvim erişimi yok",
        message: "Takvim özelliğini kullanmak için Sistem Ayarları'ndan izin verin."
    )
}

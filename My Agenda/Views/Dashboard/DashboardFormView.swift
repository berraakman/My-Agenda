//
//  DashboardFormView.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI

// MARK: - DashboardFormView
/// Mevcut bir dashboard'u düzenlemek için kullanılan sheet.
/// Kullanıcı adı, ikonu ve rengi değiştirebilir.
struct DashboardFormView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    let dashboard: Dashboard
    let onSave: (String, String, String) -> Void
    
    // MARK: - State
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    
    // MARK: - Init
    
    init(dashboard: Dashboard, onSave: @escaping (String, String, String) -> Void) {
        self.dashboard = dashboard
        self.onSave = onSave
        _name = State(initialValue: dashboard.name)
        _selectedIcon = State(initialValue: dashboard.icon)
        _selectedColor = State(initialValue: dashboard.colorHex)
    }
    
    // MARK: - Computed
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var hasChanges: Bool {
        name != dashboard.name ||
        selectedIcon != dashboard.icon ||
        selectedColor != dashboard.colorHex
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Dashboard Düzenle")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Form
            Form {
                // Ad alanı
                Section("Dashboard Adı") {
                    TextField("Dashboard adını girin...", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .rounded))
                }
                
                // Ikon seçici
                Section("İkon") {
                    let columns = [
                        GridItem(.adaptive(minimum: 40, maximum: 40), spacing: 8)
                    ]
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(AppConstants.dashboardIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(
                                        selectedIcon == icon
                                        ? Color(hex: selectedColor)
                                        : .secondary
                                    )
                                    .frame(width: 36, height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.15) : .clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedIcon == icon ? Color(hex: selectedColor) : .clear, lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Renk seçici
                Section("Renk") {
                    let columns = [
                        GridItem(.adaptive(minimum: 36, maximum: 36), spacing: 8)
                    ]
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(AppConstants.dashboardColors, id: \.self) { colorHex in
                            Button {
                                selectedColor = colorHex
                            } label: {
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == colorHex ? 2 : 0)
                                            .padding(selectedColor == colorHex ? -3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Önizleme
                Section("Önizleme") {
                    HStack(spacing: 10) {
                        Image(systemName: selectedIcon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color(hex: selectedColor))
                        
                        Text(name.isEmpty ? "Dashboard Adı" : name)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                
                Button("İptal") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Kaydet") {
                    onSave(
                        name.trimmingCharacters(in: .whitespaces),
                        selectedIcon,
                        selectedColor
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid || !hasChanges)
            }
            .padding()
        }
        #if os(macOS)
        .frame(width: 440, height: 560)
        #endif
    }
}

// MARK: - Preview

#Preview {
    let dashboard = Dashboard(name: "Teknofest", icon: "trophy.fill", colorHex: "#FF9500")
    return DashboardFormView(dashboard: dashboard) { _, _, _ in }
}

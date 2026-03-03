//
//  FolderFormView.swift
//  My Agenda
//
//  Created by Berra Akman on 01.03.2026.
//

import SwiftUI

// MARK: - FolderFormView
/// Dashboard içinde klasör oluşturma ve düzenleme formu.
struct FolderFormView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let dashboard: Dashboard
    let existingFolder: DashboardFolder?
    
    // MARK: - State
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "folder.fill"
    @State private var selectedColor: String = "#007AFF"
    
    // MARK: - Computed
    
    private var isEditing: Bool { existingFolder != nil }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Init
    
    init(dashboard: Dashboard, folder: DashboardFolder? = nil) {
        self.dashboard = dashboard
        self.existingFolder = folder
    }
    
    // MARK: - Icons
    
    private let folderIcons = [
        "folder.fill", "book.fill", "doc.fill", "pencil", "graduationcap.fill",
        "function", "number", "textformat.abc", "globe", "atom",
        "flask.fill", "cpu", "paintbrush.fill", "music.note", "sportscourt.fill",
        "figure.run", "heart.fill", "star.fill", "flag.fill", "bookmark.fill",
        "tag.fill", "tray.fill", "archivebox.fill", "cube.fill", "chart.bar.fill"
    ]
    
    // MARK: - Colors
    
    private let folderColors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#00C7BE", "#30B0C7", "#5856D6", "#AF52DE", "#FF2D55",
        "#A2845E", "#8E8E93"
    ]
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Klasörü Düzenle" : "Yeni Klasör")
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
                Section("Klasör Adı") {
                    TextField("Klasör adını girin...", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .rounded))
                }
                
                // Ikon seçici
                Section("İkon") {
                    let columns = [
                        GridItem(.adaptive(minimum: 40, maximum: 40), spacing: 8)
                    ]
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(folderIcons, id: \.self) { icon in
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
                        ForEach(folderColors, id: \.self) { colorHex in
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
                        
                        Text(name.isEmpty ? "Klasör Adı" : name)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                        
                        Spacer()
                        
                        // Dashboard adı
                        HStack(spacing: 4) {
                            Image(systemName: dashboard.icon)
                                .font(.system(size: 11))
                            Text(dashboard.name)
                                .font(.system(size: 12, design: .rounded))
                        }
                        .foregroundStyle(Color(hex: dashboard.colorHex).opacity(0.7))
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
                
                Button(isEditing ? "Kaydet" : "Oluştur") {
                    saveFolder()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: selectedColor))
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid)
            }
            .padding()
        }
        #if os(macOS)
        .frame(width: 440, height: 520)
        #endif
        .onAppear {
            loadExistingData()
        }
    }
    
    // MARK: - Methods
    
    private func loadExistingData() {
        if let folder = existingFolder {
            name = folder.name
            selectedIcon = folder.icon
            selectedColor = folder.colorHex
        } else {
            // Varsayılan olarak dashboard rengini kullan
            selectedColor = dashboard.colorHex
        }
    }
    
    private func saveFolder() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        
        if let folder = existingFolder {
            // Güncelleme
            folder.name = trimmedName
            folder.icon = selectedIcon
            folder.colorHex = selectedColor
        } else {
            // Yeni oluşturma
            let newFolder = DashboardFolder(
                name: trimmedName,
                icon: selectedIcon,
                colorHex: selectedColor,
                sortIndex: dashboard.folders.count,
                dashboard: dashboard
            )
            modelContext.insert(newFolder)
        }
    }
}

// MARK: - Preview

#Preview {
    let dashboard = Dashboard(name: "Okul", icon: "graduationcap.fill", colorHex: "#5856D6")
    return FolderFormView(dashboard: dashboard)
        .modelContainer(for: [Dashboard.self, AgendaTask.self, DashboardFolder.self], inMemory: true)
}

//
//  Constants.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation
import SwiftUI

// MARK: - App Constants
/// Uygulama genelinde kullanılan sabit değerler.
/// Tüm magic number ve string'ler burada toplanır.
enum AppConstants {
    
    // MARK: - Window
    
    /// Minimum pencere genişliği
    static let minWindowWidth: CGFloat = 1200
    
    /// Minimum pencere yüksekliği
    static let minWindowHeight: CGFloat = 780
    
    /// Sidebar minimum genişliği
    static let sidebarMinWidth: CGFloat = 260
    
    /// Sidebar ideal genişliği
    static let sidebarIdealWidth: CGFloat = 280
    
    /// Content minimum genişliği
    static let contentMinWidth: CGFloat = 420
    
    /// Detail minimum genişliği
    static let detailMinWidth: CGFloat = 380
    
    // MARK: - Animation
    
    /// Standart animasyon süresi
    static let standardAnimation: Animation = .easeInOut(duration: 0.25)
    
    /// Yavaş animasyon süresi
    static let slowAnimation: Animation = .easeInOut(duration: 0.4)
    
    /// Spring animasyon
    static let springAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.7)
    
    // MARK: - UI
    
    /// Standart köşe yuvarlama
    static let cornerRadius: CGFloat = 14
    
    /// Küçük köşe yuvarlama
    static let smallCornerRadius: CGFloat = 8
    
    /// Kart padding
    static let cardPadding: CGFloat = 16
    
    // MARK: - Default Dashboard Colors (Hex)
    
    /// Kullanıcının dashboard oluştururken seçebileceği renk paleti
    static let dashboardColors: [String] = [
        "#007AFF", // Mavi
        "#FF3B30", // Kırmızı
        "#FF9500", // Turuncu
        "#FFCC00", // Sarı
        "#34C759", // Yeşil
        "#00C7BE", // Teal
        "#5856D6", // Mor
        "#AF52DE", // Pembe-Mor
        "#FF2D55", // Pembe
        "#8E8E93", // Gri
    ]
    
    /// Kullanıcının dashboard oluştururken seçebileceği ikon seti
    static let dashboardIcons: [String] = [
        "folder.fill",
        "book.fill",
        "desktopcomputer",
        "graduationcap.fill",
        "briefcase.fill",
        "heart.fill",
        "star.fill",
        "flag.fill",
        "lightbulb.fill",
        "wrench.and.screwdriver.fill",
        "airplane",
        "trophy.fill",
        "music.note",
        "paintbrush.fill",
        "gamecontroller.fill",
        "house.fill",
    ]
    
    // MARK: - Notification
    
    /// Bildirim son tarihten kaç saat önce gönderilecek
    static let notificationHoursBefore: Int = 1
    
    /// Bildirim kategorisi identifier
    static let notificationCategoryId = "TASK_REMINDER"
}

// MARK: - Color Extension
extension Color {
    
    /// Hex string'den Color oluşturur.
    /// Örnek: Color(hex: "#FF5733") veya Color(hex: "FF5733")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255) // Varsayılan mavi
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

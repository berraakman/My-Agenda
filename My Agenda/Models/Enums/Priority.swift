//
//  Priority.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation
import SwiftUI

// MARK: - Priority Enum
/// Görev öncelik seviyesini temsil eder.
/// SwiftData uyumluluğu için Codable, picker desteği için CaseIterable.
enum Priority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { rawValue }
    
    // MARK: - Display Properties
    
    /// Türkçe görüntüleme adı
    var displayName: String {
        switch self {
        case .low:    return "Düşük"
        case .medium: return "Orta"
        case .high:   return "Yüksek"
        }
    }
    
    /// Önceliğe göre renk
    var color: Color {
        switch self {
        case .low:    return .green
        case .medium: return .orange
        case .high:   return .red
        }
    }
    
    /// Önceliğe göre SF Symbol ikonu
    var iconName: String {
        switch self {
        case .low:    return "arrow.down.circle.fill"
        case .medium: return "equal.circle.fill"
        case .high:   return "arrow.up.circle.fill"
        }
    }
    
    /// Sıralama için sayısal değer (yüksek = önce)
    var sortOrder: Int {
        switch self {
        case .low:    return 0
        case .medium: return 1
        case .high:   return 2
        }
    }
}

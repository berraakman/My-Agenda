//
//  RecurrenceType.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation

// MARK: - RecurrenceType Enum
/// Tekrarlayan görevler için tekrarlama tipini temsil eder.
/// SwiftData uyumluluğu için Codable, picker desteği için CaseIterable.
enum RecurrenceType: String, Codable, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    
    var id: String { rawValue }
    
    // MARK: - Display Properties
    
    /// Türkçe görüntüleme adı
    var displayName: String {
        switch self {
        case .daily:   return "Günlük"
        case .weekly:  return "Haftalık"
        case .monthly: return "Aylık"
        }
    }
    
    /// Tekrarlama tipine göre SF Symbol ikonu
    var iconName: String {
        switch self {
        case .daily:   return "arrow.clockwise.circle"
        case .weekly:  return "calendar.badge.clock"
        case .monthly: return "calendar.circle"
        }
    }
    
    // MARK: - Date Calculation
    
    /// Mevcut tarihten bir sonraki tekrarlama tarihini hesaplar.
    /// - Parameter from: Başlangıç tarihi
    /// - Returns: Bir sonraki tekrarlama tarihi
    func nextOccurrence(from date: Date) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        }
    }
}

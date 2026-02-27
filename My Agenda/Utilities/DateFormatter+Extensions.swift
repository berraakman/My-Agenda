//
//  DateFormatter+Extensions.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import Foundation

// MARK: - Date Extensions
extension Date {
    
    /// Türkçe locale ile kısa tarih formatı: "27 Şub 2026"
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Türkçe locale ile tam tarih formatı: "27 Şubat 2026"
    var longFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: self)
    }
    
    /// Saat formatı: "14:30"
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    /// Tam tarih ve saat: "27 Şub 2026, 14:30"
    var dateTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter.string(from: self)
    }
    
    /// Göreceli tarih açıklaması: "Bugün", "Yarın", "3 gün sonra", "2 gün önce"
    var relativeFormatted: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            return "Bugün"
        } else if calendar.isDateInYesterday(self) {
            return "Dün"
        } else if calendar.isDateInTomorrow(self) {
            return "Yarın"
        }
        
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: self))
        
        if let days = components.day {
            if days > 0 {
                return "\(days) gün sonra"
            } else {
                return "\(abs(days)) gün önce"
            }
        }
        
        return shortFormatted
    }
}

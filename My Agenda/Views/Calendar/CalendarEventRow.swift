//
//  CalendarEventRow.swift
//  My Agenda
//
//  Created by Berra Akman on 27.02.2026.
//

import SwiftUI
import EventKit

// MARK: - CalendarEventRow
/// Apple Calendar etkinliğini gösteren tek satır bileşeni.
struct CalendarEventRow: View {
    
    let event: EKEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Renk çubuğu (takvim rengi)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(cgColor: event.calendar.cgColor))
                .frame(width: 4, height: 40)
            
            // Etkinlik bilgileri
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title ?? "Etkinlik")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // Saat aralığı
                    if event.isAllDay {
                        Text("Tüm gün")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("\(event.startDate.timeFormatted) – \(event.endDate.timeFormatted)")
                                .font(.system(size: 12, design: .rounded))
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    // Takvim adı
                    Text(event.calendar.title)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Tarih
            Text(event.startDate.shortFormatted)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

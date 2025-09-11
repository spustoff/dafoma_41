//
//  Extensions.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI
import Foundation

// MARK: - Color Extensions (упрощенные)

extension Color {
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
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Простые цвета приложения
    static let newsEaseBackground = Color.black
    static let newsEasePrimary = Color.green
    static let newsEaseSecondary = Color.red
    static let newsEaseAccent = Color.orange
    
    static let newsCardBackground = Color.gray.opacity(0.2)
    static let newsTextPrimary = Color.white
    static let newsTextSecondary = Color.gray
    static let newsTextTertiary = Color.gray.opacity(0.7)
}

// MARK: - View Extensions (минимальные)

extension View {
    func newsTheme() -> some View {
        self
            .preferredColorScheme(.dark)
            .background(Color.black.ignoresSafeArea())
    }
    
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Date Extensions (упрощенные)

extension Date {
    var timeAgoDisplay: String {
        let interval = Date().timeIntervalSince(self)
        
        if interval < 3600 { // менее часа
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 { // менее дня
            return "\(Int(interval / 3600))h ago"
        } else { // более дня
            return "\(Int(interval / 86400))d ago"
        }
    }
}

// MARK: - Array Extensions (минимальные)

extension Array where Element == NewsArticle {
    var localArticles: [NewsArticle] {
        return self.filter { $0.isLocal }
    }
    
    func bookmarked(using preferences: UserPreferences) -> [NewsArticle] {
        return self.filter { preferences.bookmarkedArticles.contains($0.id) }
    }
}
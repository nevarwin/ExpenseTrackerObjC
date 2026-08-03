//
//  AppTokens.swift
//  ExpenseTrackerSwift
//

import SwiftUI

// MARK: - Spacing Tokens

enum AppSpacing {
    /// 4pt
    static let xs: CGFloat = 4
    /// 8pt
    static let sm: CGFloat = 8
    /// 12pt
    static let md: CGFloat = 12
    /// 16pt
    static let lg: CGFloat = 16
    /// 24pt
    static let xl: CGFloat = 24
}

// MARK: - Radius Tokens

enum AppRadius {
    /// 8pt
    static let small: CGFloat = 8
    /// 12pt
    static let medium: CGFloat = 12
    /// 16pt
    static let card: CGFloat = 16
    /// 999pt
    static let pill: CGFloat = 999
}

// MARK: - Accent Theme Tokens

enum AccentTheme: String, CaseIterable, Identifiable, Codable {
    case defaultTeal = "teal"
    case emerald = "emerald"
    case indigo = "indigo"
    case amber = "amber"
    case coral = "coral"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .defaultTeal: return "Teal Accent"
        case .emerald:     return "Emerald Green"
        case .indigo:      return "Royal Indigo"
        case .amber:       return "Amber Gold"
        case .coral:       return "Sunset Coral"
        }
    }

    var color: Color {
        switch self {
        case .defaultTeal: return Color(red: 0.375, green: 0.602, blue: 0.800)
        case .emerald:     return Color(red: 0.180, green: 0.800, blue: 0.443)
        case .indigo:      return Color(red: 0.388, green: 0.400, blue: 0.965)
        case .amber:       return Color(red: 0.953, green: 0.612, blue: 0.071)
        case .coral:       return Color(red: 0.957, green: 0.447, blue: 0.373)
        }
    }
}

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
    case emerald = "emerald"

    var id: String { rawValue }

    var title: String {
        return "Emerald Green"
    }

    var color: Color {
        return Color.emeraldPrimary
    }
}

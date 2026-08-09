import SwiftUI

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

    static var appCardBackground: Color {
        Color(UIColor.secondarySystemGroupedBackground)
    }

    /// Emerald Green Primary Anchor (#059669 Light / #10B981 Dark)
    static var emeraldPrimary: Color {
        Color("appAccent")
    }

    /// Emerald Gradient for headers, badges, and primary action buttons
    static var emeraldGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Subtle Emerald surface tint for chips, badges, and highlights
    static var emeraldSurface: Color {
        emeraldPrimary.opacity(0.12)
    }

    /// Soft Emerald background tint for cards and borders
    static var emeraldSubtle: Color {
        emeraldPrimary.opacity(0.06)
    }

    static var dynamicAccent: Color {
        emeraldPrimary
    }
}


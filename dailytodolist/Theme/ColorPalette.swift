//
//  ColorPalette.swift
//  Reps
//
//  Purpose: Whoop-inspired color palette for the app
//  Design: Athletic performance tracker aesthetic with bold, clean colors
//

import SwiftUI
import SwiftData

extension Color {
    // MARK: - Primary Colors

    /// Deep black in dark mode / light gray in light mode — app background
    static let brandBlack = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.039, green: 0.039, blue: 0.039, alpha: 1) // #0A0A0A
            : UIColor(red: 0.949, green: 0.949, blue: 0.969, alpha: 1) // #F2F2F7
    })

    /// White in dark mode / black in light mode — primary text
    static let pureWhite = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 1, blue: 1, alpha: 1)             // #FFFFFF
            : UIColor(red: 0, green: 0, blue: 0, alpha: 1)             // #000000
    })

    /// Always dark — for text/icons placed on accent (green) backgrounds
    static let onAccent = Color(hex: "0A0A0A")

    /// Success, completion, positive actions
    static let recoveryGreen = Color(hex: "2DD881")

    /// Alerts, delete actions
    static let strainRed = Color(hex: "FF4444")

    /// Recurring tasks, premium feel
    static let performancePurple = Color(hex: "7B61FF")

    // MARK: - Supporting Colors

    /// Card backgrounds — dark gray in dark mode / white in light mode
    static let darkGray1 = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1) // #1A1A1A
            : UIColor(red: 1, green: 1, blue: 1, alpha: 1)             // #FFFFFF
    })

    /// Elevated surfaces / dividers — darker gray in dark mode / light gray in light mode
    static let darkGray2 = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.165, green: 0.165, blue: 0.165, alpha: 1) // #2A2A2A
            : UIColor(red: 0.898, green: 0.898, blue: 0.918, alpha: 1) // #E5E5EA
    })

    /// Secondary text — adapts between dark and light mode
    static let mediumGray = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.502, green: 0.502, blue: 0.502, alpha: 1) // #808080
            : UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1) // #8E8E93
    })

    /// Borders, dividers — adapts between dark and light mode
    static let lightGray = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.878, green: 0.878, blue: 0.878, alpha: 1) // #E0E0E0
            : UIColor(red: 0.780, green: 0.780, blue: 0.800, alpha: 1) // #C7C7CC
    })

    // MARK: - Category Colors

    /// Work category - Electric Blue
    static let workBlue = Color(hex: "4A90E2")

    /// Personal category - Vibrant Orange
    static let personalOrange = Color(hex: "F5A623")

    /// Health category - Recovery Green (matches completion)
    static let healthGreen = Color(hex: "2DD881")

    /// Shopping category - Magenta
    static let shoppingMagenta = Color(hex: "BD10E0")

    /// Other category - Neutral Gray
    static let otherGray = Color(hex: "808080")

    // MARK: - Helper Methods

    /// Returns the appropriate color for a given category
    static func categoryColor(for category: String?, customCategories: [CustomCategory] = []) -> Color {
        guard let category = category else { return .otherGray }
        switch category.lowercased() {
        case "work": return .workBlue
        case "personal": return .personalOrange
        case "health": return .healthGreen
        case "shopping": return .shoppingMagenta
        default:
            if let custom = customCategories.first(where: { $0.name == category }) {
                return Color(hex: custom.colorHex)
            }
            return .otherGray
        }
    }

    /// Returns the emoji icon for a given category
    static func categoryIcon(for category: String?, customCategories: [CustomCategory] = []) -> String {
        guard let category = category else { return "circle.fill" }
        switch category.lowercased() {
        case "work": return "briefcase.fill"
        case "personal": return "house.fill"
        case "health": return "heart.fill"
        case "shopping": return "cart.fill"
        default:
            if let custom = customCategories.first(where: { $0.name == category }) {
                return custom.iconName
            }
            return "circle.fill"
        }
    }
}

// MARK: - Hex Color Initializer

extension Color {
    /// Creates a Color from a hex string
    /// - Parameter hex: A hex color string (with or without #)
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
            (a, r, g, b) = (255, 0, 0, 0)
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

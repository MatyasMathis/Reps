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

    /// Deep, rich black for backgrounds (dark) / white (light)
    static var brandBlack: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 10/255,  green: 10/255,  blue: 10/255,  alpha: 1) // #0A0A0A
                : UIColor(red: 1.0,     green: 1.0,     blue: 1.0,     alpha: 1) // #FFFFFF
        })
    }

    /// High contrast white for text (dark) / near-black (light)
    static var pureWhite: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 1.0,      green: 1.0,      blue: 1.0,      alpha: 1) // #FFFFFF
                : UIColor(red: 17/255,   green: 17/255,   blue: 17/255,   alpha: 1) // #111111
        })
    }

    /// Success, completion, positive actions
    static let recoveryGreen = Color(hex: "2DD881")

    /// Alerts, delete actions
    static let strainRed = Color(hex: "FF4444")

    /// Recurring tasks, premium feel
    static let performancePurple = Color(hex: "7B61FF")

    // MARK: - Supporting Colors

    /// Card backgrounds (dark) / iOS light card surface (light)
    static var darkGray1: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 26/255,  green: 26/255,  blue: 26/255,  alpha: 1) // #1A1A1A
                : UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1) // #F2F2F7
        })
    }

    /// Elevated surfaces (dark) / secondary surface (light)
    static var darkGray2: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 42/255,  green: 42/255,  blue: 42/255,  alpha: 1) // #2A2A2A
                : UIColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1) // #E5E5EA
        })
    }

    /// Secondary text
    static var mediumGray: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1) // #808080
                : UIColor(red: 99/255,  green: 99/255,  blue: 102/255, alpha: 1) // #636366
        })
    }

    /// Borders, dividers
    static var lightGray: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1) // #E0E0E0
                : UIColor(red: 199/255, green: 199/255, blue: 204/255, alpha: 1) // #C7C7CC
        })
    }

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

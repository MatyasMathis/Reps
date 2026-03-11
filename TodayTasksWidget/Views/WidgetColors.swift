//
//  WidgetColors.swift
//  TodayTasksWidget
//
//  Purpose: Color definitions for the widget matching the main app's design.
//

import SwiftUI
import SwiftData

extension Color {
    // MARK: - Adaptive colors
    // UIColor(dynamicProvider:) does not respond to .preferredColorScheme() in WidgetKit.
    // Use these static functions with @Environment(\.colorScheme) in widget views instead.

    static func widgetDarkGray1(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1A1A1A") : .white
    }
    static func widgetDarkGray2(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "E5E5EA")
    }
    static func widgetPureWhite(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : .black
    }
    static func widgetMediumGray(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "808080") : Color(hex: "8E8E93")
    }

    // MARK: - Accents
    static let widgetRecoveryGreen = Color(hex: "2DD881")
    static let widgetPerformancePurple = Color(hex: "7B61FF")

    // MARK: - Categories
    static let widgetWorkBlue = Color(hex: "4A90E2")
    static let widgetPersonalOrange = Color(hex: "F5A623")
    static let widgetHealthGreen = Color(hex: "2DD881")
    static let widgetShoppingMagenta = Color(hex: "BD10E0")

    static func widgetCategoryColor(for category: String?, customCategories: [CustomCategory] = []) -> Color {
        guard let category = category else { return Color(hex: "8E8E93") }
        switch category.lowercased() {
        case "work": return .widgetWorkBlue
        case "personal": return .widgetPersonalOrange
        case "health": return .widgetHealthGreen
        case "shopping": return .widgetShoppingMagenta
        default:
            if let custom = customCategories.first(where: { $0.name == category }) {
                return Color(hex: custom.colorHex)
            }
            return Color(hex: "8E8E93")
        }
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
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

//
//  WidgetColors.swift
//  TodayTasksWidget
//
//  Purpose: Color definitions for the widget matching the main app's design.
//

import SwiftUI
import SwiftData

extension Color {
    // MARK: - Backgrounds (adaptive — follow system dark/light mode)
    static let widgetBrandBlack = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.039, green: 0.039, blue: 0.039, alpha: 1) // #0A0A0A
            : UIColor(red: 0.949, green: 0.949, blue: 0.969, alpha: 1) // #F2F2F7
    })
    static let widgetDarkGray1 = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1) // #1A1A1A
            : UIColor(red: 1, green: 1, blue: 1, alpha: 1)             // #FFFFFF
    })
    static let widgetDarkGray2 = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.165, green: 0.165, blue: 0.165, alpha: 1) // #2A2A2A
            : UIColor(red: 0.898, green: 0.898, blue: 0.918, alpha: 1) // #E5E5EA
    })

    // MARK: - Text (adaptive)
    static let widgetPureWhite = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 1, blue: 1, alpha: 1)             // #FFFFFF
            : UIColor(red: 0, green: 0, blue: 0, alpha: 1)             // #000000
    })
    static let widgetMediumGray = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.502, green: 0.502, blue: 0.502, alpha: 1) // #808080
            : UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1) // #8E8E93
    })

    // MARK: - Accents
    static let widgetRecoveryGreen = Color(hex: "2DD881")
    static let widgetPerformancePurple = Color(hex: "7B61FF")

    // MARK: - Categories
    static let widgetWorkBlue = Color(hex: "4A90E2")
    static let widgetPersonalOrange = Color(hex: "F5A623")
    static let widgetHealthGreen = Color(hex: "2DD881")
    static let widgetShoppingMagenta = Color(hex: "BD10E0")

    static func widgetCategoryColor(for category: String?, customCategories: [CustomCategory] = []) -> Color {
        guard let category = category else { return .widgetMediumGray }
        switch category.lowercased() {
        case "work": return .widgetWorkBlue
        case "personal": return .widgetPersonalOrange
        case "health": return .widgetHealthGreen
        case "shopping": return .widgetShoppingMagenta
        default:
            if let custom = customCategories.first(where: { $0.name == category }) {
                return Color(hex: custom.colorHex)
            }
            return .widgetMediumGray
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

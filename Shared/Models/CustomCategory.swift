//
//  CustomCategory.swift
//  Shared
//
//  Purpose: Defines a user-created custom category with icon and color.
//  Shared between main app and widget extension.
//

import Foundation
import SwiftData

/// A user-defined category with custom icon and color
@Model
final class CustomCategory {

    // MARK: - Properties

    /// Unique identifier
    var id: UUID = UUID()

    /// Display name (also used as the key in TodoTask.category)
    var name: String = ""

    /// SF Symbol name (e.g. "star.fill")
    var iconName: String = ""

    /// Hex color string without # (e.g. "FF6B6B")
    var colorHex: String = ""

    /// Date when the category was created
    var createdAt: Date = Date()

    /// Sort order for display in the category grid
    var sortOrder: Int = 0

    // MARK: - Initialization

    init(
        name: String,
        iconName: String,
        colorHex: String,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }
}

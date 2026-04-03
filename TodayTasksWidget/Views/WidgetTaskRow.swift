//
//  WidgetTaskRow.swift
//  TodayTasksWidget
//
//  Purpose: Interactive task row for the large widget.
//  Design: Circle toggle button, bold italic title, category pill badge.
//

import SwiftUI
import AppIntents

struct WidgetTaskRow: View {
    let task: WidgetTask

    var body: some View {
        HStack(spacing: 12) {
            // Interactive circle checkbox
            Button(intent: ToggleTaskIntent(taskId: task.id.uuidString)) {
                ZStack {
                    Circle()
                        .stroke(
                            task.isCompletedToday ? Color.widgetRecoveryGreen : Color.widgetMediumGray.opacity(0.5),
                            lineWidth: 1.5
                        )
                        .frame(width: 24, height: 24)

                    if task.isCompletedToday {
                        Circle()
                            .fill(Color.widgetRecoveryGreen)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.black)
                    }
                }
            }
            .buttonStyle(.plain)

            // Task title
            Text(task.title)
                .font(.system(size: 15, weight: .bold))
                .italic()
                .foregroundStyle(task.isCompletedToday ? Color.widgetPureWhite.opacity(0.5) : Color.widgetPureWhite)
                .strikethrough(task.isCompletedToday, color: Color.widgetPureWhite.opacity(0.3))
                .lineLimit(1)

            Spacer(minLength: 0)

            // Category badge
            if !task.isCompletedToday, let category = task.category, !category.isEmpty {
                WidgetCategoryBadge(category: category, customColorHex: task.customCategoryColorHex)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.widgetDarkGray1)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(task.isCompletedToday ? 0.6 : 1.0)
    }
}

// MARK: - Category Badge

struct WidgetCategoryBadge: View {
    let category: String
    var customColorHex: String? = nil

    private var badgeColor: Color {
        if let hex = customColorHex {
            return Color(hex: hex)
        }
        return Color.widgetCategoryColor(for: category)
    }

    var body: some View {
        Text(category.uppercased())
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(badgeColor)
            .tracking(0.5)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

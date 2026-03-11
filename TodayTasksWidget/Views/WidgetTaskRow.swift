//
//  WidgetTaskRow.swift
//  TodayTasksWidget
//
//  Purpose: Interactive task row component for widget views.
//  Tapping the checkbox completes the task without opening the app.
//

import SwiftUI
import AppIntents

struct WidgetTaskRow: View {
    let task: WidgetTask
    let compact: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            // Interactive checkbox button
            Button(intent: ToggleTaskIntent(taskId: task.id.uuidString)) {
                ZStack {
                    Circle()
                        .stroke(task.isCompletedToday ? Color.widgetRecoveryGreen : Color.widgetMediumGray(colorScheme), lineWidth: 2)
                        .frame(width: compact ? 18 : 22, height: compact ? 18 : 22)

                    if task.isCompletedToday {
                        Circle()
                            .fill(Color.widgetRecoveryGreen)
                            .frame(width: compact ? 18 : 22, height: compact ? 18 : 22)

                        Image(systemName: "checkmark")
                            .font(.system(size: compact ? 10 : 12, weight: .bold))
                            .foregroundStyle(Color.widgetPureWhite(colorScheme))
                    }
                }
            }
            .buttonStyle(.plain)

            // Task title
            Text(task.title)
                .font(.system(size: compact ? 14 : 16, weight: .medium))
                .foregroundStyle(task.isCompletedToday ? Color.widgetPureWhite(colorScheme).opacity(0.6) : Color.widgetPureWhite(colorScheme))
                .strikethrough(task.isCompletedToday, color: Color.widgetPureWhite(colorScheme).opacity(0.4))
                .lineLimit(1)

            Spacer()

            // Badges (only show when not completed)
            if !task.isCompletedToday {
                HStack(spacing: 4) {
                    if let category = task.category, !category.isEmpty {
                        WidgetCategoryBadge(category: category, compact: compact, customColorHex: task.customCategoryColorHex)
                    }

                    if task.isRecurring {
                        WidgetRecurringBadge(compact: compact)
                    }
                }
            }
        }
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.vertical, compact ? 8 : 10)
        .background(Color.widgetDarkGray2(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(task.isCompletedToday ? 0.7 : 1.0)
    }
}

// MARK: - Category Badge

struct WidgetCategoryBadge: View {
    let category: String
    let compact: Bool
    var customColorHex: String? = nil

    private var badgeColor: Color {
        if let hex = customColorHex {
            return Color(hex: hex)
        }
        return Color.widgetCategoryColor(for: category)
    }

    var body: some View {
        Text(category.uppercased())
            .font(.system(size: compact ? 9 : 10, weight: .semibold))
            .foregroundStyle(badgeColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.2))
            .clipShape(Capsule())
    }
}

// MARK: - Recurring Badge

struct WidgetRecurringBadge: View {
    let compact: Bool

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "repeat")
                .font(.system(size: compact ? 8 : 9, weight: .bold))
            if !compact {
                Text("DAILY")
                    .font(.system(size: 9, weight: .semibold))
            }
        }
        .foregroundStyle(Color.widgetPerformancePurple)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.widgetPerformancePurple.opacity(0.15))
        .clipShape(Capsule())
    }
}

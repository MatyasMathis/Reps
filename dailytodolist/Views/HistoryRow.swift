//
//  HistoryRow.swift
//  dailytodolist
//
//  Purpose: Individual row component for completed tasks with Whoop-inspired design
//  Design: Dark card styling with green checkmark and time badge
//

import SwiftUI
import SwiftData

/// A row view displaying a single completion record with Whoop-inspired styling
///
/// Features:
/// - Recovery green checkmark icon
/// - Dark card background
/// - Time badge in monospace font
/// - Category and recurring badges
struct HistoryRow: View {

    // MARK: - Properties

    let completion: TaskCompletion

    // MARK: - Computed Properties

    private var formattedTime: String {
        completion.completedAt.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            // MARK: Checkmark Icon
            ZStack {
                Circle()
                    .fill(Color.recoveryGreen)
                    .frame(width: ComponentSize.checkbox, height: ComponentSize.checkbox)

                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.pureWhite)
            }

            // MARK: Task Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let task = completion.task {
                    Text(task.title)
                        .font(.system(size: Typography.h4Size, weight: .medium))
                        .foregroundStyle(Color.pureWhite)

                    // Badges row
                    HStack(spacing: Spacing.sm) {
                        // Time badge
                        TimeBadge(time: formattedTime)

                        // Category badge
                        if let category = task.category, !category.isEmpty {
                            CategoryBadge(category: category)
                        }

                        // Recurring badge
                        if task.recurrenceType != .none {
                            RecurringBadge(task: task)
                        }
                    }
                } else {
                    Text("Completed Task")
                        .font(.system(size: Typography.h4Size, weight: .medium))
                        .foregroundStyle(Color.mediumGray)
                        .italic()
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, 14)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        .shadowLevel1()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.brandBlack.ignoresSafeArea()
        VStack(spacing: Spacing.sm) {
            // Preview would need actual data
            Text("History Row Preview")
                .foregroundStyle(Color.pureWhite)
        }
        .padding(Spacing.lg)
    }
}

//
//  Badges.swift
//  Reps
//
//  Purpose: Reusable badge components with Whoop styling
//

import SwiftUI
import SwiftData

// MARK: - Category Badge

/// Badge displaying the task's category with Whoop-inspired styling
/// Supports both built-in and custom categories
struct CategoryBadge: View {
    let category: String

    @Query(sort: \CustomCategory.sortOrder)
    private var customCategories: [CustomCategory]

    private var categoryColor: Color {
        Color.categoryColor(for: category, customCategories: customCategories)
    }

    var body: some View {
        Text(category.uppercased())
            .font(.system(size: Typography.captionSize, weight: .semibold))
            .foregroundStyle(categoryColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(categoryColor.opacity(0.2))
            .clipShape(Capsule())
    }
}

// MARK: - Recurring Badge

/// Badge indicating a task's recurrence pattern with Whoop-inspired styling
/// Displays the recurrence schedule (e.g., "DAILY", "MON, WED, FRI", "1ST, 15TH")
struct RecurringBadge: View {
    let task: TodoTask

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "repeat")
                .font(.system(size: 10, weight: .bold))
            Text(task.recurrenceDisplayString)
                .font(.system(size: Typography.captionSize, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(Color.performancePurple)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.performancePurple.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Time Badge

/// Badge displaying completion time
struct TimeBadge: View {
    let time: String

    var body: some View {
        Text(time)
            .font(.system(size: Typography.timeSize, weight: .medium, design: .monospaced))
            .foregroundStyle(Color.mediumGray)
    }
}

// MARK: - Streak Badge

/// Badge displaying the current streak count
struct StreakBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(
                    count >= 7 ? Color.strainRed :
                    count >= 3 ? Color.personalOrange :
                    Color.recoveryGreen
                )
            Text("\(count)")
                .font(.system(size: Typography.h4Size, weight: .bold))
                .foregroundStyle(Color.pureWhite)
        }
    }
}

// MARK: - Pro Badge

/// Small badge indicating a premium feature
/// Clean, minimal design that doesn't distract from the main UI
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.onAccent)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                LinearGradient(
                    colors: [Color.recoveryGreen, Color.recoveryGreen.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Badges") {
    ZStack {
        Color.brandBlack.ignoresSafeArea()
        VStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.sm) {
                CategoryBadge(category: "Work")
                CategoryBadge(category: "Personal")
                CategoryBadge(category: "Health")
            }
            HStack(spacing: Spacing.sm) {
                CategoryBadge(category: "Shopping")
                CategoryBadge(category: "Other")
            }

            // Recurring badges with different patterns
            VStack(spacing: Spacing.sm) {
                RecurringBadge(task: TodoTask(title: "Daily", recurrenceType: .daily))
                RecurringBadge(task: TodoTask(title: "Weekly", recurrenceType: .weekly, selectedWeekdays: [2, 4, 6]))
                RecurringBadge(task: TodoTask(title: "Monthly", recurrenceType: .monthly, selectedMonthDays: [1, 15]))
            }

            TimeBadge(time: "2:30 PM")
            HStack(spacing: Spacing.xl) {
                StreakBadge(count: 1)
                StreakBadge(count: 3)
                StreakBadge(count: 7)
            }

            ProBadge()
        }
    }
}

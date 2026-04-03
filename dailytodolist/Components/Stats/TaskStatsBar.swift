//
//  TaskStatsBar.swift
//  dailytodolist
//
//  Purpose: Compact stats bar showing key metrics for a task
//

import SwiftUI
import SwiftData

/// Displays key statistics for a task: total completions and completion rate
struct TaskStatsBar: View {

    // MARK: - Properties

    let task: TodoTask

    // MARK: - Private Properties

    private let calendar = Calendar.current

    // MARK: - Computed Properties

    private var totalCompletions: Int {
        task.completions?.count ?? 0
    }

    private var completionRate: Double? {
        guard task.recurrenceType != .none else { return nil }

        let scheduledDays = countScheduledDays()
        guard scheduledDays > 0 else { return nil }

        let completionDays = Set(task.completions?.map { calendar.startOfDay(for: $0.completedAt) } ?? []).count
        return min(Double(completionDays) / Double(scheduledDays), 1.0)
    }

    /// Counts scheduled days based on recurrence type
    private func countScheduledDays() -> Int {
        let startDate = calendar.startOfDay(for: task.createdAt)
        let today = calendar.startOfDay(for: Date())

        switch task.recurrenceType {
        case .daily:
            return max((calendar.dateComponents([.day], from: startDate, to: today).day ?? 0) + 1, 1)

        case .weekly:
            let weekdaySet = Set(task.selectedWeekdays)
            guard !weekdaySet.isEmpty else { return 1 }
            let totalDays = max((calendar.dateComponents([.day], from: startDate, to: today).day ?? 0) + 1, 1)
            let fullWeeks = totalDays / 7
            let remainingDays = totalDays % 7
            var count = fullWeeks * weekdaySet.count
            let startWeekday = calendar.component(.weekday, from: startDate)
            for i in 0..<remainingDays {
                let wd = ((startWeekday - 1 + i) % 7) + 1
                if weekdaySet.contains(wd) { count += 1 }
            }
            return max(count, 1)

        case .monthly:
            let daySet = Set(task.selectedMonthDays)
            guard !daySet.isEmpty else { return 1 }
            var count = 0
            var current = calendar.date(from: calendar.dateComponents([.year, .month], from: startDate)) ?? startDate
            let todayMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
            while current <= todayMonth {
                let daysInMonth = calendar.range(of: .day, in: .month, for: current)?.count ?? 30
                for day in daySet {
                    guard day <= daysInMonth else { continue }
                    if let date = calendar.date(bySetting: .day, value: day, of: current),
                       calendar.startOfDay(for: date) >= startDate && calendar.startOfDay(for: date) <= today {
                        count += 1
                    }
                }
                guard let next = calendar.date(byAdding: .month, value: 1, to: current) else { break }
                current = next
            }
            return max(count, 1)

        case .none:
            return 1
        }
    }

    private var firstCompletionDate: Date? {
        task.completions?.min(by: { $0.completedAt < $1.completedAt })?.completedAt
    }

    // MARK: - Body

    var body: some View {
        if totalCompletions == 0 {
            noCompletionsView
        } else if task.recurrenceType != .none {
            recurringTaskStats
        } else {
            oneTimeTaskStats
        }
    }

    // MARK: - Subviews

    private var recurringTaskStats: some View {
        HStack(spacing: 0) {
            // Total
            StatItem(
                label: "TOTAL",
                value: "\(totalCompletions)",
                color: .pureWhite
            )

            Divider()
                .frame(height: 40)
                .background(Color.darkGray2)

            // Rate
            StatItem(
                label: "RATE",
                value: completionRate.map { "\(Int($0 * 100))%" } ?? "—",
                color: rateColor
            )
        }
        .padding(.vertical, Spacing.md)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
    }

    private var oneTimeTaskStats: some View {
        HStack(spacing: 0) {
            // Total
            StatItem(
                label: "TOTAL",
                value: "\(totalCompletions)",
                color: .pureWhite
            )

            Divider()
                .frame(height: 40)
                .background(Color.darkGray2)

            // First completed
            StatItem(
                label: "FIRST",
                value: firstCompletionDate.map { formatDate($0) } ?? "—",
                color: .mediumGray
            )
        }
        .padding(.vertical, Spacing.md)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
    }

    private var noCompletionsView: some View {
        HStack {
            Spacer()
            VStack(spacing: Spacing.xs) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.mediumGray)
                Text("No completions yet")
                    .font(.system(size: Typography.bodySize, weight: .medium))
                    .foregroundStyle(Color.mediumGray)
            }
            Spacer()
        }
        .padding(.vertical, Spacing.lg)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
    }

    // MARK: - Helpers

    private var rateColor: Color {
        guard let rate = completionRate else { return .mediumGray }
        if rate >= 0.8 {
            return .recoveryGreen
        } else if rate >= 0.5 {
            return .personalOrange
        } else {
            return .strainRed
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(label)
                .font(.system(size: Typography.captionSize, weight: .semibold))
                .foregroundStyle(Color.mediumGray)

            Text(value)
                .font(.system(size: Typography.h4Size, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stat Grid Card

/// Individual card for the 2x2 stats grid in StatsView
struct StatGridCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .font(.system(size: Typography.captionSize, weight: .bold))
                .foregroundStyle(Color.mediumGray)
                .tracking(1.0)

            Text(value)
                .font(.system(size: 44, weight: .black))
                .italic()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.lg)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }
}

// MARK: - Preview

#Preview("Task Stats Bar") {
    struct PreviewWrapper: View {
        var body: some View {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: TodoTask.self, TaskCompletion.self, CustomCategory.self, configurations: config)

            // Recurring task with good stats
            let recurringTask = TodoTask(title: "Morning Exercise", category: "Health", recurrenceType: .daily)
            container.mainContext.insert(recurringTask)

            // Add completions for streak
            let calendar = Calendar.current
            for daysAgo in [0, 1, 2, 3, 4] {
                if let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) {
                    let completion = TaskCompletion(task: recurringTask, completedAt: date)
                    container.mainContext.insert(completion)
                }
            }

            // One-time task
            let oneTimeTask = TodoTask(title: "Buy groceries", category: "Shopping")
            container.mainContext.insert(oneTimeTask)
            let completion = TaskCompletion(task: oneTimeTask, completedAt: Date().addingTimeInterval(-86400 * 5))
            container.mainContext.insert(completion)

            // Empty task
            let emptyTask = TodoTask(title: "New task", category: "Work")
            container.mainContext.insert(emptyTask)

            return ZStack {
                Color.brandBlack.ignoresSafeArea()
                VStack(spacing: Spacing.lg) {
                    TaskStatsBar(task: recurringTask)
                    TaskStatsBar(task: oneTimeTask)
                    TaskStatsBar(task: emptyTask)
                }
                .padding(Spacing.lg)
            }
        }
    }

    return PreviewWrapper()
}

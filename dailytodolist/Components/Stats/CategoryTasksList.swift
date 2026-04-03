//
//  CategoryTasksList.swift
//  Reps
//
//  Purpose: Shows tasks within a category with per-task streaks and rates
//  Design: Compact list with inline streak badges and progress indicators
//

import SwiftUI
import SwiftData

/// Displays tasks within a category, each with its own streak and completion rate
struct CategoryTasksList: View {

    // MARK: - Properties

    let tasks: [TodoTask]

    // MARK: - State

    /// Task selected via context menu to show its completion calendar
    @State private var selectedTask: TodoTask?

    // MARK: - Computed Properties

    /// Pre-computed task stats sorted by most active (completion count) first, then alphabetically.
    /// Computes streak, rate, and count once per task — avoids duplicate calculations.
    private var taskStats: [(task: TodoTask, completionCount: Int, streak: Int, rate: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return tasks.map { task in
            let completions = task.completions ?? []
            let completionCount = completions.count
            let completionDates = Set(completions.map { calendar.startOfDay(for: $0.completedAt) })

            // Streak
            var streak = 0
            if !completionDates.isEmpty {
                var checkDate = today
                if !completionDates.contains(checkDate) {
                    if let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate),
                       completionDates.contains(yesterday) {
                        checkDate = yesterday
                    }
                }
                if completionDates.contains(checkDate) {
                    while completionDates.contains(checkDate) {
                        streak += 1
                        guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                        checkDate = prev
                    }
                }
            }

            // Rate
            var rate: Double = 0
            if !completions.isEmpty {
                if task.recurrenceType == .none {
                    rate = 1.0
                } else {
                    let scheduledDays = Self.countScheduledDays(for: task, calendar: calendar, today: today)
                    rate = min(Double(completionDates.count) / Double(scheduledDays), 1.0)
                }
            }

            return (task: task, completionCount: completionCount, streak: streak, rate: rate)
        }
        .sorted { a, b in
            if a.completionCount != b.completionCount { return a.completionCount > b.completionCount }
            return a.task.title < b.task.title
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Section label
            Text("TASK MASTERY")
                .font(.system(size: Typography.captionSize, weight: .black))
                .italic()
                .foregroundStyle(Color.mediumGray)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)

            let stats = taskStats

            if stats.isEmpty {
                emptyView
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(stats.enumerated()), id: \.element.task.id) { index, entry in
                        Button {
                            selectedTask = entry.task
                        } label: {
                            CategoryTaskRow(
                                task: entry.task,
                                completionCount: entry.completionCount,
                                streak: entry.streak,
                                rate: entry.rate
                            )
                        }
                        .buttonStyle(.plain)

                        if index < stats.count - 1 {
                            Divider()
                                .background(Color.darkGray2)
                        }
                    }
                }
                .background(Color.darkGray1)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskCalendarSheet(task: task)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Subviews

    private var emptyView: some View {
        HStack {
            Spacer()
            Text("No tasks in this category")
                .font(.system(size: Typography.bodySize, weight: .medium))
                .foregroundStyle(Color.mediumGray)
            Spacer()
        }
        .padding(.vertical, Spacing.lg)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }

    // MARK: - Helpers

    /// Counts scheduled days for a task based on its recurrence type
    static func countScheduledDays(for task: TodoTask, calendar: Calendar, today: Date) -> Int {
        let startDate = calendar.startOfDay(for: task.createdAt)

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
}

// MARK: - Category Task Row

struct CategoryTaskRow: View {

    let task: TodoTask
    let completionCount: Int
    let streak: Int
    let rate: Double

    private var rateColor: Color {
        if rate >= 0.8 { return .recoveryGreen }
        if rate >= 0.5 { return .personalOrange }
        return .strainRed
    }

    private var streakColor: Color {
        if streak >= 7 { return .strainRed }
        if streak >= 3 { return .personalOrange }
        return .recoveryGreen
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Left: title + subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: Typography.bodySize, weight: .bold))
                    .italic()
                    .foregroundStyle(Color.pureWhite)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if task.recurrenceType != .none {
                        Text(task.recurrenceDisplayString.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.performancePurple)
                    }
                    if let category = task.category, !category.isEmpty {
                        if task.recurrenceType != .none {
                            Text("•")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.mediumGray.opacity(0.4))
                        }
                        Text(category.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.mediumGray)
                    }
                }
            }

            Spacer()

            // Right: stat chips
            HStack(spacing: Spacing.sm) {
                // Streak chip
                if streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(streakColor)
                        Text("\(streak)")
                            .font(.system(size: Typography.captionSize, weight: .bold))
                            .foregroundStyle(streakColor)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(streakColor.opacity(0.12))
                    .clipShape(Capsule())
                }

                // Rate chip (recurring only)
                if task.recurrenceType != .none {
                    Text("\(Int(rate * 100))%")
                        .font(.system(size: Typography.captionSize, weight: .bold))
                        .foregroundStyle(rateColor)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(rateColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                // Reps count
                Text(String(format: "%02d", completionCount))
                    .font(.system(size: Typography.bodySize, weight: .bold))
                    .italic()
                    .foregroundStyle(Color.pureWhite)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md + 2)
    }
}

// MARK: - Task Calendar Sheet

/// Sheet showing a completion calendar for a specific task
struct TaskCalendarSheet: View {

    let task: TodoTask
    @Environment(\.dismiss) private var dismiss
    @State private var displayedMonth = Date()
    @State private var showShare = false

    private var completionCount: Int {
        task.completions?.count ?? 0
    }

    private var completionDates: Set<Date> {
        let calendar = Calendar.current
        guard let completions = task.completions else { return [] }
        return Set(completions.map { calendar.startOfDay(for: $0.completedAt) })
    }

    private var taskStreak: Int {
        let calendar = Calendar.current
        let dates = completionDates
        guard !dates.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        if !dates.contains(checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            if !dates.contains(yesterday) { return 0 }
            checkDate = yesterday
        }

        while dates.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        return streak
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Task info header
                        VStack(spacing: Spacing.sm) {
                            Text(task.title)
                                .font(.system(size: Typography.h4Size, weight: .bold))
                                .foregroundStyle(Color.pureWhite)

                            if task.recurrenceType != .none {
                                Text(task.recurrenceDisplayString)
                                    .font(.system(size: Typography.captionSize, weight: .semibold))
                                    .foregroundStyle(Color.mediumGray)
                            }

                            Text("\(completionCount) completion\(completionCount == 1 ? "" : "s")")
                                .font(.system(size: Typography.bodySize, weight: .medium))
                                .foregroundStyle(Color.recoveryGreen)
                        }
                        .padding(.top, Spacing.md)

                        // Completion calendar
                        CompletionCalendar(
                            task: task,
                            displayedMonth: $displayedMonth
                        )

                        // Share button
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showShare = true
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Share Calendar")
                                    .font(.system(size: Typography.bodySize, weight: .bold))
                            }
                            .foregroundStyle(Color.brandBlack)
                            .frame(maxWidth: .infinity)
                            .frame(height: ComponentSize.buttonHeight)
                            .background(Color.recoveryGreen)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.pureWhite)
                    }
                }
            }
            .toolbarBackground(Color.brandBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showShare) {
                CalendarShareSheet(
                    categoryName: task.title,
                    categoryIcon: "checkmark.circle.fill",
                    categoryColorHex: "2DD881",
                    completionDates: completionDates,
                    displayedMonth: displayedMonth,
                    streak: taskStreak,
                    completionCount: completionCount
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Preview

#Preview("Category Tasks List") {
    struct PreviewWrapper: View {
        var body: some View {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: TodoTask.self, TaskCompletion.self, CustomCategory.self, configurations: config)

            let task1 = TodoTask(title: "Morning Workout", category: "Health", recurrenceType: .daily)
            let task2 = TodoTask(title: "Evening Walk", category: "Health", recurrenceType: .daily)
            let task3 = TodoTask(title: "Take Vitamins", category: "Health", recurrenceType: .daily)

            container.mainContext.insert(task1)
            container.mainContext.insert(task2)
            container.mainContext.insert(task3)

            let calendar = Calendar.current
            for daysAgo in 0..<8 {
                if let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) {
                    container.mainContext.insert(TaskCompletion(task: task1, completedAt: date))
                }
            }
            for daysAgo in 0..<3 {
                if let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) {
                    container.mainContext.insert(TaskCompletion(task: task2, completedAt: date))
                }
            }

            return ZStack {
                Color.brandBlack.ignoresSafeArea()
                CategoryTasksList(tasks: [task1, task2, task3])
                    .padding(Spacing.lg)
            }
            .modelContainer(container)
        }
    }

    return PreviewWrapper()
}

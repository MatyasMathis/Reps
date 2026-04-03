//
//  StatsView.swift
//  dailytodolist
//
//  Purpose: Category-centric statistics view showing completion patterns
//  Design: Category pill selector with overview stats, weekly rhythm, trends, and per-task breakdown
//

import SwiftUI
import UIKit
import SwiftData

/// Statistics view filtered by category
///
/// Features:
/// - Horizontal scrollable category pills (All + each category)
/// - Quick numbers bar (total reps, rate, streak, best streak)
/// - Weekly rhythm bar chart
/// - This month vs last month trend
/// - Per-task list with streaks and completion rates
/// - Monthly completion calendar
struct StatsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Pro Gate

    @ObservedObject private var store = StoreKitService.shared

    // MARK: - Queries

    @Query(filter: #Predicate<TodoTask> { $0.isActive }, sort: \TodoTask.title)
    private var allTasks: [TodoTask]

    @Query(sort: \TaskCompletion.completedAt, order: .reverse)
    private var allCompletions: [TaskCompletion]

    @Query(sort: \CustomCategory.sortOrder)
    private var customCategories: [CustomCategory]

    // MARK: - State

    @State private var selectedCategory: String? = nil // nil means "All"
    @State private var displayedMonth: Date = Date()
    @State private var showCalendarShare = false

    // Cached stats — recomputed on category/data change, not on every body evaluation
    @State private var cachedFilteredTasks: [TodoTask] = []
    @State private var cachedCompletionDates: [Date] = []
    @State private var cachedCompletionDateSet: Set<Date> = []
    @State private var cachedTotalReps: Int = 0
    @State private var cachedCompletionRate: Int? = nil
    @State private var cachedCurrentStreak: Int = 0
    @State private var cachedBestStreak: Int = 0

    // New cached stats
    @State private var cachedConsistencyScore: Int = 0
    @State private var cachedThisMonthCount: Int = 0
    @State private var cachedLastMonthCount: Int = 0

    // MARK: - Computed Properties

    /// All unique categories from active tasks
    private var categories: [String] {
        let builtIn = ["Work", "Personal", "Health", "Shopping", "Other"]
        let custom = customCategories.map { $0.name }
        let all = builtIn + custom

        let taskCategories = Set(allTasks.compactMap { $0.category })
        return all.filter { taskCategories.contains($0) }
    }

    /// Color for the selected category
    private var categoryColor: Color {
        guard let category = selectedCategory else { return .recoveryGreen }
        return Color.categoryColor(for: category, customCategories: customCategories)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Category pill selector — always interactive (teaser)
                        categoryPills

                        // Stats content — gated behind Pro with blurred sneak peek
                        ProFeatureOverlay(
                            icon: "chart.bar.fill",
                            title: "Statistics",
                            subtitle: "Unlock detailed stats, trends,\nand completion analytics"
                        ) {
                            statsContent
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xxl * 2)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.pureWhite)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Statistics")
                        .font(.system(size: Typography.h4Size, weight: .bold))
                        .foregroundStyle(Color.pureWhite)
                }
            }
            .toolbarBackground(Color.brandBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showCalendarShare) {
                CalendarShareSheet(
                    categoryName: selectedCategory ?? "All Tasks",
                    categoryIcon: selectedCategory.map { Color.categoryIcon(for: $0, customCategories: customCategories) } ?? "checkmark.circle.fill",
                    categoryColorHex: selectedCategory.map { colorHex(for: $0) } ?? "2DD881",
                    completionDates: cachedCompletionDateSet,
                    displayedMonth: displayedMonth,
                    streak: cachedCurrentStreak,
                    completionCount: completionCountForMonth
                )
            }
            .onAppear { recomputeStats() }
            .onChange(of: selectedCategory) { recomputeStats() }
            .onChange(of: allCompletions.count) { recomputeStats() }
            .onChange(of: allTasks.count) { recomputeStats() }
        }
    }

    /// Completion count for the displayed month
    private var completionCountForMonth: Int {
        let cal = Calendar.current
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth)),
              let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) else { return 0 }
        return cachedCompletionDateSet.filter { $0 >= monthStart && $0 < nextMonth }.count
    }

    /// Returns hex color string for a category
    private func colorHex(for category: String) -> String {
        switch category.lowercased() {
        case "work": return "4A90E2"
        case "personal": return "F5A623"
        case "health": return "2DD881"
        case "shopping": return "BD10E0"
        default:
            if let custom = customCategories.first(where: { $0.name == category }) {
                return custom.colorHex
            }
            return "808080"
        }
    }

    // MARK: - Subviews

    /// Stats content — everything below category pills
    @ViewBuilder
    private var statsContent: some View {
        if cachedCompletionDates.isEmpty && cachedFilteredTasks.isEmpty {
            emptyState
        } else {
            VStack(spacing: Spacing.xl) {
                // Quick numbers
                quickNumbers

                // Consistency score — the primary conversion hook
                if cachedTotalReps > 0 {
                    ConsistencyScoreCard(
                        score: cachedConsistencyScore,
                        accentColor: categoryColor
                    )
                }

                // Weekly rhythm
                if !cachedCompletionDates.isEmpty {
                    WeeklyRhythmChart(
                        completions: cachedCompletionDates,
                        accentColor: categoryColor
                    )
                }

                // Peak hours — uses exact timestamps
                if !cachedCompletionDates.isEmpty {
                    PeakHoursChart(
                        completions: cachedCompletionDates,
                        accentColor: categoryColor
                    )
                }

                // Monthly trend
                if !cachedCompletionDates.isEmpty {
                    MonthlyTrendCard(
                        completions: cachedCompletionDates,
                        accentColor: categoryColor
                    )
                }

                // 8-week rolling trend
                if !cachedCompletionDates.isEmpty {
                    WeeklyTrendChart(
                        completions: cachedCompletionDates,
                        accentColor: categoryColor
                    )
                }

                // Personal records
                if cachedTotalReps > 0 {
                    PersonalRecordsCard(
                        completions: cachedCompletionDates,
                        accentColor: categoryColor
                    )
                }

                // Tasks in category
                if !cachedFilteredTasks.isEmpty {
                    CategoryTasksList(tasks: cachedFilteredTasks)
                }

                // Completion calendar with share option
                VStack(spacing: Spacing.sm) {
                    CategoryCompletionCalendar(
                        completionDates: cachedCompletionDateSet,
                        displayedMonth: $displayedMonth,
                        accentColor: categoryColor
                    )

                    // Share calendar button (pro feature)
                    if store.isProUnlocked {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showCalendarShare = true
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
                            .background(categoryColor)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
                        }
                    }
                }
            }
        }
    }

    /// Horizontal scrollable category pills
    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                // "All" pill
                categoryPill(label: "All", category: nil, color: .recoveryGreen)

                // Category pills
                ForEach(categories, id: \.self) { category in
                    categoryPill(
                        label: category,
                        category: category,
                        color: Color.categoryColor(for: category, customCategories: customCategories)
                    )
                }
            }
            .padding(.horizontal, Spacing.xs)
        }
    }

    private func categoryPill(label: String, category: String?, color: Color) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
            }
        } label: {
            Text(label.uppercased())
                .font(.system(size: Typography.captionSize, weight: .bold))
                .foregroundStyle(isSelected ? Color.brandBlack : color)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }

    /// Quick numbers bar
    private var quickNumbers: some View {
        HStack(spacing: 0) {
            StatItem(
                label: "TOTAL REPS",
                value: "\(cachedTotalReps)",
                color: categoryColor
            )

            if let rate = cachedCompletionRate {
                StatItem(
                    label: "RATE",
                    value: "\(rate)%",
                    color: rateColor(for: rate)
                )
            }

            StatItem(
                label: "STREAK",
                value: "\(cachedCurrentStreak)",
                color: cachedCurrentStreak > 0 ? categoryColor : .mediumGray
            )

            StatItem(
                label: "BEST",
                value: "\(cachedBestStreak)",
                color: cachedBestStreak > 0 ? categoryColor : .mediumGray
            )
        }
        .padding(.vertical, Spacing.md)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }

    /// Empty state
    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(Color.mediumGray)

            VStack(spacing: Spacing.sm) {
                Text("No data yet")
                    .font(.system(size: Typography.h3Size, weight: .bold))
                    .foregroundStyle(Color.pureWhite)

                Text("Complete tasks to see your stats here.")
                    .font(.system(size: Typography.bodySize, weight: .regular))
                    .foregroundStyle(Color.mediumGray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, Spacing.xxl * 2)
    }

    // MARK: - Stats Computation

    /// Recomputes all cached stats in a single pass.
    /// Called on appear and when category/data changes.
    private func recomputeStats() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Filter tasks
        let tasks: [TodoTask]
        if let category = selectedCategory {
            tasks = allTasks.filter { $0.category == category }
        } else {
            tasks = allTasks
        }
        cachedFilteredTasks = tasks

        // Filter completions and build date sets in one pass
        let completions: [TaskCompletion]
        if let category = selectedCategory {
            completions = allCompletions.filter { $0.task?.category == category }
        } else {
            completions = allCompletions
        }

        var dates: [Date] = []
        var dateSet: Set<Date> = []
        dates.reserveCapacity(completions.count)

        for completion in completions {
            dates.append(completion.completedAt)
            dateSet.insert(calendar.startOfDay(for: completion.completedAt))
        }

        cachedCompletionDates = dates
        cachedCompletionDateSet = dateSet
        cachedTotalReps = completions.count

        // This month / last month counts (used for consistency score)
        if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
           let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: monthStart) {
            cachedThisMonthCount = completions.filter { $0.completedAt >= monthStart }.count
            cachedLastMonthCount = completions.filter { $0.completedAt >= lastMonthStart && $0.completedAt < monthStart }.count
        }

        // Completion rate for recurring tasks
        let recurringTasks = tasks.filter { $0.recurrenceType != .none }
        if recurringTasks.isEmpty {
            cachedCompletionRate = nil
        } else {
            var totalScheduledDays = 0
            var totalCompletionDays = 0
            for task in recurringTasks {
                let scheduledDays = CategoryTasksList.countScheduledDays(for: task, calendar: calendar, today: today)
                let completionDays = Set(task.completions?.map { calendar.startOfDay(for: $0.completedAt) } ?? []).count
                totalScheduledDays += scheduledDays
                totalCompletionDays += min(completionDays, scheduledDays)
            }
            if totalScheduledDays > 0 {
                cachedCompletionRate = min(Int(Double(totalCompletionDays) / Double(totalScheduledDays) * 100), 100)
            } else {
                cachedCompletionRate = nil
            }
        }

        // Current streak
        if dateSet.isEmpty {
            cachedCurrentStreak = 0
        } else {
            var streak = 0
            var checkDate = today
            if !dateSet.contains(checkDate) {
                if let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate),
                   dateSet.contains(yesterday) {
                    checkDate = yesterday
                }
            }
            if dateSet.contains(checkDate) {
                while dateSet.contains(checkDate) {
                    streak += 1
                    guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prev
                }
            }
            cachedCurrentStreak = streak
        }

        // Consistency score (computed after streak and rate are known)
        cachedConsistencyScore = ConsistencyScoreCard.compute(
            completionRate: cachedCompletionRate,
            currentStreak: cachedCurrentStreak,
            thisMonthCount: cachedThisMonthCount,
            lastMonthCount: cachedLastMonthCount
        )

        // Best streak
        let sortedDates = dateSet.sorted()
        if sortedDates.isEmpty {
            cachedBestStreak = 0
        } else {
            var maxStreak = 1
            var current = 1
            for i in 1..<sortedDates.count {
                if let expected = calendar.date(byAdding: .day, value: 1, to: sortedDates[i - 1]),
                   calendar.isDate(expected, inSameDayAs: sortedDates[i]) {
                    current += 1
                    maxStreak = max(maxStreak, current)
                } else {
                    current = 1
                }
            }
            cachedBestStreak = maxStreak
        }
    }

    // MARK: - Helpers

    private func rateColor(for rate: Int) -> Color {
        if rate >= 80 { return .recoveryGreen }
        if rate >= 50 { return .personalOrange }
        return .strainRed
    }
}

// MARK: - Preview

#Preview("Stats View") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TodoTask.self, TaskCompletion.self, CustomCategory.self, configurations: config)

    let task1 = TodoTask(title: "Morning Exercise", category: "Health", recurrenceType: .daily)
    let task2 = TodoTask(title: "Evening Walk", category: "Health", recurrenceType: .daily)
    let task3 = TodoTask(title: "Team standup", category: "Work", recurrenceType: .weekly, selectedWeekdays: [2, 3, 4, 5, 6])
    let task4 = TodoTask(title: "Read for 30 minutes", category: "Personal", recurrenceType: .daily)
    let task5 = TodoTask(title: "Buy groceries", category: "Shopping")

    container.mainContext.insert(task1)
    container.mainContext.insert(task2)
    container.mainContext.insert(task3)
    container.mainContext.insert(task4)
    container.mainContext.insert(task5)

    let calendar = Calendar.current
    for daysAgo in [0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20] {
        if let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()),
           let time = calendar.date(bySettingHour: 9, minute: Int.random(in: 0...59), second: 0, of: date) {
            container.mainContext.insert(TaskCompletion(task: task1, completedAt: time))
        }
    }
    for daysAgo in [0, 1, 2, 5, 8] {
        if let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()),
           let time = calendar.date(bySettingHour: 18, minute: 30, second: 0, of: date) {
            container.mainContext.insert(TaskCompletion(task: task2, completedAt: time))
        }
    }
    for daysAgo in [0, 1, 3, 4, 7, 8] {
        if let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()),
           let time = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date) {
            container.mainContext.insert(TaskCompletion(task: task3, completedAt: time))
        }
    }

    return StatsView()
        .modelContainer(container)
}

#Preview("Stats View - Empty") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TodoTask.self, TaskCompletion.self, CustomCategory.self, configurations: config)

    return StatsView()
        .modelContainer(container)
}

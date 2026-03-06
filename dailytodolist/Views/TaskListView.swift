//
//  TaskListView.swift
//  Reps
//
//  Purpose: Main view displaying today's tasks with Whoop-inspired design
//  Design: Dark theme with Daily Progress Card, Streak Counter, and FAB
//

import SwiftUI
import SwiftData
import WidgetKit

/// Main view for displaying and managing today's tasks
///
/// Features:
/// - Daily Progress Card showing completion percentage
/// - Streak counter in navigation bar
/// - Floating Action Button for adding tasks
/// - Dark theme with card-based task list
/// - Swipe to delete and drag to reorder
struct TaskListView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State

    @State private var isShowingAddSheet = false
    @State private var taskToEdit: TodoTask?
    @State private var todayTasks: [TodoTask] = []
    @State private var editMode: EditMode = .inactive
    @State private var refreshID = UUID()

    // Celebration overlay state
    @State private var showCelebration = false
    @State private var celebrationMessage = ""

    // Year in Pixels sheet — opened from MainTabView toolbar
    // @State private var showYearInPixels removed (owned by MainTabView)

    // Settings sheet — opened from MainTabView toolbar
    // @State private var showSettings removed (owned by MainTabView)

    // Pro paywall (for gated share features)
    @ObservedObject private var storeService = StoreKitService.shared
    @State private var showSharePaywall = false

    // Pro glimpse nudge
    @State private var showProGlimpse = false
    @State private var proGlimpseVariant: ProGlimpseVariant = .allTasksDone

    // MARK: - Preferences

    @AppStorage("soundEnabled") private var soundEnabled: Bool = true

    // Category share sheet
    @State private var showCategoryShare = false
    @State private var completedCategoryName: String = ""
    @State private var completedCategoryIcon: String = ""
    @State private var completedCategoryColorHex: String = ""
    @State private var completedCategoryCount: Int = 0
    @State private var completedCategoryTotal: Int = 0
    @State private var completedCategoryStreak: Int = 0
    @State private var completedCategorySubtitle: String = ""

    // Share toast (non-intrusive nudge)
    @State private var showShareToast = false

    // MARK: - Queries

    @Query(
        filter: #Predicate<TodoTask> { task in
            task.isActive == true
        },
        sort: \TodoTask.sortOrder
    )
    private var allActiveTasks: [TodoTask]

    @Query(sort: \TaskCompletion.completedAt, order: .reverse)
    private var allCompletions: [TaskCompletion]

    @Query(sort: \CustomCategory.sortOrder)
    private var customCategories: [CustomCategory]

    // MARK: - Computed Properties

    /// Number of tasks completed today (from todayTasks list)
    private var completedTodayCount: Int {
        todayTasks.filter { $0.isCompletedToday() }.count
    }

    /// Total tasks for today (all tasks in todayTasks, both completed and incomplete)
    private var totalTodayCount: Int {
        todayTasks.count
    }

    // MARK: - Body
    // NOTE: No NavigationStack here — MainTabView owns the single NavigationStack.
    //       Toolbar items (Today title, streak badge, settings, date) live in MainTabView.

    var body: some View {
        ZStack {
                // Background
                Color.brandBlack.ignoresSafeArea()

                if todayTasks.isEmpty && completedTodayCount == 0 {
                    // Empty state
                    emptyStateView
                } else {
                    // Task list with progress card
                    taskListContent
                }

                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton {
                            isShowingAddSheet = true
                        }
                        .padding(.trailing, Spacing.xxl)
                        .padding(.bottom, 80)
                    }
                }

                // Share toast — non-intrusive, tappable, auto-dismisses
                if showShareToast {
                    VStack {
                        Spacer()
                        ShareToastBanner(
                            categoryName: completedCategoryName,
                            categoryColorHex: completedCategoryColorHex,
                            categoryIcon: completedCategoryIcon,
                            onTap: {
                                withAnimation { showShareToast = false }
                                if storeService.isProUnlocked {
                                    showCategoryShare = true
                                } else {
                                    showSharePaywall = true
                                }
                            },
                            onDismiss: {
                                withAnimation { showShareToast = false }
                            }
                        )
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, 140) // Above FAB + tab bar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(1)
                }

                // Celebration overlay for task completion
                CelebrationOverlay(message: celebrationMessage, isShowing: $showCelebration)

                // Pro glimpse nudge — slides up after key moments
                if showProGlimpse {
                    VStack {
                        Spacer()
                        ProGlimpseCard(
                            variant: proGlimpseVariant,
                            onUnlock: {
                                withAnimation { showProGlimpse = false }
                                showSharePaywall = true
                            },
                            onDismiss: {
                                withAnimation { showProGlimpse = false }
                            }
                        )
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, 140)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(2)
                }
            }
            .sheet(isPresented: $isShowingAddSheet, onDismiss: {
                // Refresh tasks after adding or editing via autocomplete
                withAnimation {
                    updateTodayTasks()
                }
            }) {
                AddTaskSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $taskToEdit, onDismiss: {
                // Refresh tasks after editing
                withAnimation {
                    updateTodayTasks()
                }
            }) { task in
                EditTaskSheet(task: task) {
                    // On delete callback
                    withAnimation {
                        updateTodayTasks()
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showCategoryShare) {
                CategoryShareSheet(
                    categoryName: completedCategoryName,
                    categoryIcon: completedCategoryIcon,
                    categoryColorHex: completedCategoryColorHex,
                    completedCount: completedCategoryCount,
                    totalCount: completedCategoryTotal,
                    streak: completedCategoryStreak,
                    subtitle: completedCategorySubtitle
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showSharePaywall) {
                PaywallView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                OnboardingService.createStarterTasksIfNeeded(modelContext: modelContext)
                updateTodayTasks()
            }
            .onChange(of: allActiveTasks) {
                updateTodayTasks()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                // Refresh data when app comes to foreground (e.g., after widget interaction)
                if newPhase == .active {
                    // Force view refresh by changing the ID, which re-triggers @Query
                    refreshID = UUID()
                    refreshFromDatabase()
                }
            }
            .id(refreshID)
            .environment(\.editMode, $editMode)
    }

    // MARK: - Subviews

    /// Main content with progress card and task list
    private var taskListContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Daily Progress Card
                DailyProgressCard(
                    completed: completedTodayCount,
                    total: max(totalTodayCount, 1)
                )
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)

                // Task list with drag to reorder
                ReorderableTaskList(
                    tasks: $todayTasks,
                    onComplete: { task in
                        completeTask(task)
                    },
                    onDelete: { task in
                        deleteTask(task)
                    },
                    onReorder: { tasks in
                        reorderTasks(tasks)
                    },
                    onEdit: { task in
                        editTask(task)
                    }
                )
                .padding(.horizontal, Spacing.lg)

                // Bottom padding for FAB
                Color.clear.frame(height: 80)
            }
        }
        .refreshable {
            await refreshTasks()
        }
    }

    /// Empty state view with contextual nudge
    private var emptyStateView: some View {
        EmptyStateCard(
            icon: "checkmark.circle",
            title: "Nothing on the board.",
            subtitle: "Tap + to add your first task. Keep it simple.",
            actionTitle: "Add Task"
        ) {
            isShowingAddSheet = true
        }
    }

    // MARK: - Methods

    private func completeTask(_ task: TodoTask) {
        let taskService = TaskService(modelContext: modelContext)
        let isNowCompleted = taskService.toggleTaskCompletion(task)

        if isNowCompleted {
            // Haptic feedback
            HapticService.success()

            // Check for streak milestone message first, then fall back to random
            let streak = calculateStreak()
            if let milestoneMsg = EncouragingMessages.milestoneMessage(for: streak) {
                celebrationMessage = milestoneMsg
            } else {
                celebrationMessage = EncouragingMessages.random()
            }
            showCelebration = true

            // Check if all tasks in this category are now completed
            checkCategoryCompletion(for: task)

            // Pro glimpse nudges — check after state updates
            DispatchQueue.main.async {
                checkAllTasksDoneNudge()
                checkStreakMilestoneNudge()
            }
        }

        // Update immediately - completed tasks stay in list but move to end
        withAnimation {
            updateTodayTasks()
        }
    }

    // MARK: - Category Completion Detection

    /// Checks two triggers after completing a task:
    /// 1. All today-tasks in category done (3+ tasks)
    /// 2. Weekly milestone: all planned recurring sessions for the week done
    private func checkCategoryCompletion(for task: TodoTask) {
        guard let category = task.category else { return }

        // Trigger 1: All of today's tasks in this category are done
        let categoryTasks = todayTasks.filter { $0.category == category }
        let allTodayDone = categoryTasks.count >= 3 && categoryTasks.allSatisfy { $0.isCompletedToday() }

        if allTodayDone {
            let dedupKey = "share_today_\(category)_\(todayDateString)"
            if !UserDefaults.standard.bool(forKey: dedupKey) {
                UserDefaults.standard.set(true, forKey: dedupKey)
                showSharePrompt(
                    category: category,
                    completed: categoryTasks.count,
                    total: categoryTasks.count,
                    subtitle: "completed today"
                )
                return
            }
        }

        // Trigger 2: Weekly milestone — all planned recurring sessions this week are done
        checkWeeklyMilestone(for: category)
    }

    /// Checks if all recurring tasks in a category have been completed for every
    /// scheduled day this week (Mon–today). E.g. 4 gym sessions planned, 4 done.
    private func checkWeeklyMilestone(for category: String) {
        let calendar = Calendar.current
        let today = Date()

        // Get all active recurring tasks in this category
        let recurringTasks = allActiveTasks.filter {
            $0.category == category && $0.recurrenceType != .none && $0.isActive
        }
        guard recurringTasks.count >= 1 else { return }

        // Calculate week range: Monday through today
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7 // Mon=0, Tue=1, ... Sun=6
        guard let weekStart = calendar.date(byAdding: .day, value: -daysSinceMonday, to: calendar.startOfDay(for: today)) else { return }

        var totalScheduled = 0
        var totalCompleted = 0

        for task in recurringTasks {
            for dayOffset in 0...daysSinceMonday {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }

                if isTaskScheduled(task, on: date, calendar: calendar) {
                    totalScheduled += 1
                    if isTaskCompleted(task, on: date, calendar: calendar) {
                        totalCompleted += 1
                    }
                }
            }
        }

        guard totalScheduled >= 3 && totalCompleted == totalScheduled else { return }

        // Dedup: only fire once per category per week
        let weekNumber = calendar.component(.weekOfYear, from: today)
        let year = calendar.component(.year, from: today)
        let dedupKey = "share_week_\(category)_\(year)_w\(weekNumber)"
        guard !UserDefaults.standard.bool(forKey: dedupKey) else { return }
        UserDefaults.standard.set(true, forKey: dedupKey)

        showSharePrompt(
            category: category,
            completed: totalCompleted,
            total: totalScheduled,
            subtitle: "this week"
        )
    }

    /// Shows the share toast (non-intrusive banner, not a sheet)
    private func showSharePrompt(category: String, completed: Int, total: Int, subtitle: String) {
        completedCategoryName = category
        completedCategoryIcon = Color.categoryIcon(for: category, customCategories: customCategories)
        completedCategoryColorHex = categoryColorHex(for: category)
        completedCategoryCount = completed
        completedCategoryTotal = total
        completedCategoryStreak = categoryStreak(for: category)
        completedCategorySubtitle = subtitle

        // Delay so celebration overlay plays first
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showShareToast = true
            }
            // Auto-dismiss after 5 seconds if user doesn't interact
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation { showShareToast = false }
            }
        }
    }

    // MARK: - Category Helpers

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func isTaskScheduled(_ task: TodoTask, on date: Date, calendar: Calendar) -> Bool {
        if let startDate = task.startDate {
            if calendar.startOfDay(for: startDate) > calendar.startOfDay(for: date) { return false }
        }
        switch task.recurrenceType {
        case .none: return false
        case .daily: return true
        case .weekly:
            let weekday = calendar.component(.weekday, from: date)
            return task.selectedWeekdays.isEmpty || task.selectedWeekdays.contains(weekday)
        case .monthly:
            let day = calendar.component(.day, from: date)
            return task.selectedMonthDays.isEmpty || task.selectedMonthDays.contains(day)
        }
    }

    private func isTaskCompleted(_ task: TodoTask, on date: Date, calendar: Calendar) -> Bool {
        guard let completions = task.completions else { return false }
        let targetDay = calendar.startOfDay(for: date)
        return completions.contains { calendar.startOfDay(for: $0.completedAt) == targetDay }
    }

    private func categoryColorHex(for category: String) -> String {
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

    private func categoryStreak(for category: String) -> Int {
        let calendar = Calendar.current
        let categoryCompletions = allCompletions.filter { $0.task?.category == category }
        let dates = Set(categoryCompletions.map { calendar.startOfDay(for: $0.completedAt) })

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

    // MARK: - Pro Glimpse Triggers

    /// Shows the pro glimpse card after a short delay (so celebration plays first).
    private func presentProGlimpse(_ variant: ProGlimpseVariant) {
        guard ProNudgeService.shared.canShow else { return }
        ProNudgeService.shared.markShown()
        proGlimpseVariant = variant
        // Delay so the celebration overlay finishes first
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showProGlimpse = true
            }
            // Auto-dismiss after 8 seconds if the user doesn't interact
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                withAnimation { showProGlimpse = false }
            }
        }
    }

    /// Fires when all of today's tasks are completed — highest-value nudge moment.
    private func checkAllTasksDoneNudge() {
        guard !storeService.isProUnlocked else { return }
        guard !ProNudgeService.shared.hasShownAllTasksDoneNudgeToday else { return }
        guard totalTodayCount > 0 && completedTodayCount == totalTodayCount else { return }

        ProNudgeService.shared.hasShownAllTasksDoneNudgeToday = true
        presentProGlimpse(.allTasksDone)
    }

    /// Fires when the user hits a streak milestone (7, 14, 30 days) for the first time.
    private func checkStreakMilestoneNudge() {
        guard !storeService.isProUnlocked else { return }
        let milestones = [7, 14, 30]
        let streak = calculateStreak()
        guard milestones.contains(streak) else { return }
        guard !ProNudgeService.shared.hasShownStreakNudge(for: streak) else { return }

        ProNudgeService.shared.markStreakNudgeShown(for: streak)
        presentProGlimpse(.streakMilestone(streak))
    }

    private func refreshTasks() async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        refreshFromDatabase()
    }

    /// Force refresh all data from the database (needed after widget updates)
    private func refreshFromDatabase() {
        // Force SwiftData to re-read from disk by invalidating cached data
        // This is needed because the widget writes directly to the shared database
        do {
            // Manually fetch fresh data from database
            let taskDescriptor = FetchDescriptor<TodoTask>(
                predicate: #Predicate { $0.isActive == true },
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            let freshTasks = try modelContext.fetch(taskDescriptor)

            // Touch each task to ensure relationships are loaded fresh
            for task in freshTasks {
                _ = task.completions?.count
            }
        } catch {
            print("Error refreshing from database: \(error)")
        }

        updateTodayTasks()
    }

    private func updateTodayTasks() {
        // Filter tasks that belong to today's list based on recurrence pattern:
        // - One-time tasks: show if never completed OR completed today
        // - Daily tasks: always show (completed today or not)
        // - Weekly tasks: show only on selected weekdays
        // - Monthly tasks: show only on selected dates
        let filteredTasks = allActiveTasks.filter { task in
            if task.recurrenceType != .none {
                // Recurring tasks: show if scheduled for today OR already completed today
                // This handles the case where user edits recurrence after completing
                return task.shouldShowToday() || task.isCompletedToday()
            } else {
                // One-time tasks: must pass recurrence check (handles startDate)
                guard task.shouldShowToday() else { return false }
                // Show non-recurring if: never completed, or completed today
                guard let completions = task.completions, !completions.isEmpty else {
                    return true  // Never completed
                }
                // Has completions - only show if one is from today
                return task.isCompletedToday()
            }
        }

        // Sort: incomplete tasks first (by sortOrder), then completed tasks at the end
        todayTasks = filteredTasks.sorted { task1, task2 in
            let completed1 = task1.isCompletedToday()
            let completed2 = task2.isCompletedToday()

            if completed1 == completed2 {
                // Both same completion status - sort by sortOrder
                return task1.sortOrder < task2.sortOrder
            }
            // Incomplete tasks come first
            return !completed1 && completed2
        }
    }

    private func hasEverBeenCompleted(_ task: TodoTask) -> Bool {
        guard let completions = task.completions else { return false }
        return !completions.isEmpty
    }

    private func deleteTask(_ task: TodoTask) {
        withAnimation {
            TaskService(modelContext: modelContext).deleteTask(task)
            updateTodayTasks()
        }
    }

    private func editTask(_ task: TodoTask) {
        taskToEdit = task
    }

    private func reorderTasks(_ tasks: [TodoTask]) {
        let taskService = TaskService(modelContext: modelContext)
        // Only update sortOrder for incomplete tasks
        let incompleteTasks = tasks.filter { !$0.isCompletedToday() }
        taskService.reorderTasks(incompleteTasks)
        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error saving task reorder: \(error)")
        }
    }

    /// Calculates the current streak of consecutive days with completions
    private func calculateStreak() -> Int {
        guard !allCompletions.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // Get unique completion dates
        let completionDates = Set(allCompletions.map { calendar.startOfDay(for: $0.completedAt) })

        // Check if there are completions today
        if !completionDates.contains(checkDate) {
            // Check yesterday - if no completions yesterday, streak is 0
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                return 0
            }
            if !completionDates.contains(yesterday) {
                return 0
            }
            checkDate = yesterday
        }

        // Count consecutive days
        while completionDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }

        return streak
    }
}

// MARK: - Preview

#Preview("With Tasks") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TodoTask.self, TaskCompletion.self, CustomCategory.self, configurations: config)

    let task1 = TodoTask(title: "Morning Workout", category: "Health", sortOrder: 1)
    let task2 = TodoTask(title: "Team Meeting", category: "Work", recurrenceType: .daily, sortOrder: 2)
    let task3 = TodoTask(title: "Buy groceries", category: "Shopping", sortOrder: 3)
    container.mainContext.insert(task1)
    container.mainContext.insert(task2)
    container.mainContext.insert(task3)

    return TaskListView()
        .modelContainer(container)
}

#Preview("Empty State") {
    TaskListView()
        .modelContainer(for: [TodoTask.self, TaskCompletion.self, CustomCategory.self], inMemory: true)
}

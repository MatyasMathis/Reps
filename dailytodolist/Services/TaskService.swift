//
//  TaskService.swift
//  Reps
//
//  Purpose: Business logic layer for task operations
//  Key responsibilities:
//  - Create, read, update, and delete tasks
//  - Filter tasks for today's list (recurring vs non-recurring logic)
//  - Manage task ordering
//

import Foundation
import SwiftData
import WidgetKit

/// Service class providing business logic for task management
///
/// This class separates data operations from views, making the code
/// more testable and maintainable. All database operations go through
/// the ModelContext provided by SwiftData.
///
/// Key filtering logic:
/// - Recurring tasks: Show if NOT completed today (will reappear tomorrow)
/// - Non-recurring tasks: Show if NEVER completed (one-time tasks)
@MainActor
class TaskService {

    // MARK: - Properties

    /// SwiftData model context for database operations
    private var modelContext: ModelContext

    // MARK: - Initialization

    /// Creates a new TaskService with the given model context
    ///
    /// - Parameter modelContext: SwiftData context for database operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Widget Refresh

    /// Refreshes all widgets to reflect current task state
    /// Saves the model context first to ensure data is persisted
    private func refreshWidgets() {
        // Save changes to disk before refreshing widget
        do {
            try modelContext.save()
        } catch {
            print("Error saving context before widget refresh: \(error)")
        }

        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Create Operations

    /// Creates a new task with the specified properties
    ///
    /// The new task is automatically assigned a sort order that places it
    /// at the end of the current task list.
    ///
    /// - Parameters:
    ///   - title: The display title for the task (required, non-empty)
    ///   - category: Optional category for organization
    ///   - recurrenceType: The type of recurrence pattern (default: .none)
    ///   - selectedWeekdays: Weekdays for weekly recurrence (1=Sun, 7=Sat)
    ///   - selectedMonthDays: Days for monthly recurrence (1-31)
    ///   - startDate: Optional start date for scheduling future tasks
    /// - Returns: The newly created task
    @discardableResult
    func createTask(
        title: String,
        category: String? = nil,
        recurrenceType: RecurrenceType = .none,
        selectedWeekdays: [Int] = [],
        selectedMonthDays: [Int] = [],
        startDate: Date? = nil
    ) -> TodoTask {
        // Get the current maximum sort order to place new task at end
        let maxSortOrder = fetchMaxSortOrder()

        let task = TodoTask(
            title: title,
            category: category,
            recurrenceType: recurrenceType,
            selectedWeekdays: selectedWeekdays,
            selectedMonthDays: selectedMonthDays,
            sortOrder: maxSortOrder + 1,
            startDate: startDate
        )

        modelContext.insert(task)
        refreshWidgets()
        return task
    }

    // MARK: - Update Operations

    /// Updates an existing task with new properties
    ///
    /// - Parameters:
    ///   - task: The task to update
    ///   - title: New title for the task
    ///   - category: New category (nil to remove)
    ///   - recurrenceType: New recurrence pattern
    ///   - selectedWeekdays: New weekdays for weekly recurrence
    ///   - selectedMonthDays: New days for monthly recurrence
    ///   - startDate: New start date (nil for immediate)
    func updateTask(
        _ task: TodoTask,
        title: String,
        category: String?,
        recurrenceType: RecurrenceType,
        selectedWeekdays: [Int],
        selectedMonthDays: [Int],
        startDate: Date? = nil
    ) {
        // If a non-recurring task that was previously completed is being
        // updated to start today (no future startDate), clear its completion
        // records so it reappears in today's list.
        if recurrenceType == .none && startDate == nil && hasEverBeenCompleted(task) {
            clearCompletions(for: task)
        }

        task.title = title
        task.category = category
        task.recurrenceType = recurrenceType
        task.selectedWeekdays = selectedWeekdays
        task.selectedMonthDays = selectedMonthDays
        task.startDate = startDate
        refreshWidgets()
    }

    // MARK: - Read Operations

    /// Fetches all active tasks sorted by sort order
    ///
    /// Returns tasks that have not been soft-deleted (isActive = true).
    /// Use this for getting all tasks without date-based filtering.
    ///
    /// - Returns: Array of active tasks sorted by sortOrder
    func fetchActiveTasks() -> [TodoTask] {
        let descriptor = FetchDescriptor<TodoTask>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching active tasks: \(error)")
            return []
        }
    }

    /// Fetches tasks that should appear in today's list
    ///
    /// This is the core filtering logic for the app:
    /// - One-time tasks: Show if NEVER completed
    /// - Daily tasks: Show if NOT completed today
    /// - Weekly tasks: Show if today is a selected weekday AND NOT completed today
    /// - Monthly tasks: Show if today is a selected date AND NOT completed today
    ///
    /// - Returns: Array of tasks for today's list, sorted by sortOrder
    func fetchTodayTasks() -> [TodoTask] {
        let allActiveTasks = fetchActiveTasks()

        // MARK: - Task Filtering Logic
        return allActiveTasks.filter { task in
            // First check if the task should show based on recurrence pattern
            guard task.shouldShowToday() else { return false }

            if task.recurrenceType != .none {
                // Recurring: show if not completed today
                return !task.isCompletedToday()
            } else {
                // Non-recurring: show if never completed
                return !hasEverBeenCompleted(task)
            }
        }
    }

    /// Checks if a task has ever been completed
    ///
    /// Used for non-recurring tasks to determine if they should
    /// still appear in today's list.
    ///
    /// - Parameter task: The task to check
    /// - Returns: true if the task has at least one completion record
    private func hasEverBeenCompleted(_ task: TodoTask) -> Bool {
        guard let completions = task.completions else { return false }
        return !completions.isEmpty
    }

    /// Gets the current maximum sort order among all tasks
    ///
    /// Used when creating new tasks to place them at the end of the list.
    ///
    /// - Returns: The highest sortOrder value, or 0 if no tasks exist
    private func fetchMaxSortOrder() -> Int {
        let descriptor = FetchDescriptor<TodoTask>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )

        do {
            let tasks = try modelContext.fetch(descriptor)
            return tasks.first?.sortOrder ?? 0
        } catch {
            print("Error fetching max sort order: \(error)")
            return 0
        }
    }

    // MARK: - Completion Operations

    /// Toggles the completion status of a task for today
    ///
    /// This is the main method for handling task completion from the UI.
    /// It checks if the task is already completed today:
    /// - If completed today: removes today's completion (uncomplete)
    /// - If not completed today: creates a new completion record
    ///
    /// For recurring tasks, this affects only today's status - the task
    /// will reappear tomorrow regardless.
    ///
    /// For non-recurring tasks, completing them effectively "finishes" them
    /// forever (they won't appear in today's list again).
    ///
    /// - Parameter task: The task to toggle completion for
    /// - Returns: true if task is now completed, false if uncompleted
    @discardableResult
    func toggleTaskCompletion(_ task: TodoTask) -> Bool {
        let result: Bool
        if task.isCompletedToday() {
            uncompleteTask(task)
            result = false
        } else {
            completeTask(task)
            result = true
        }
        refreshWidgets()
        return result
    }

    /// Marks a task as completed for today
    ///
    /// Creates a new TaskCompletion record with the current timestamp.
    /// This record is added to the task's completions relationship.
    ///
    /// After completion:
    /// - Recurring tasks: Will disappear from today but reappear tomorrow
    /// - Non-recurring tasks: Will disappear permanently from today's list
    ///
    /// - Parameter task: The task to complete
    func completeTask(_ task: TodoTask) {
        let completion = TaskCompletion(task: task)
        modelContext.insert(completion)

        // Ensure the completions array exists and add the new completion
        if task.completions == nil {
            task.completions = []
        }
        task.completions?.append(completion)

        // Explicit save so CloudKit uploads the completion record without delay.
        try? modelContext.save()
    }

    /// Removes all completion records for a task
    ///
    /// Used when reactivating a previously completed one-time task so that
    /// it passes the `hasEverBeenCompleted` check and reappears in today's list.
    ///
    /// - Parameter task: The task whose completions should be cleared
    private func clearCompletions(for task: TodoTask) {
        guard let completions = task.completions else { return }
        for completion in completions {
            modelContext.delete(completion)
        }
        task.completions = []
    }

    /// Removes today's completion record for a task (uncomplete)
    ///
    /// Finds and deletes the completion record for today, if one exists.
    /// This effectively "unchecks" a task that was completed today.
    ///
    /// Note: This only affects today's completion. Historical completions
    /// on other days are preserved.
    ///
    /// - Parameter task: The task to uncomplete
    func uncompleteTask(_ task: TodoTask) {
        guard let completions = task.completions else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Find today's completion record
        if let todayCompletion = completions.first(where: { completion in
            calendar.startOfDay(for: completion.completedAt) == today
        }) {
            // Remove from task's completions array
            task.completions?.removeAll { $0.id == todayCompletion.id }
            // Delete from database
            modelContext.delete(todayCompletion)
            // Explicit save so CloudKit removes the completion record without delay.
            try? modelContext.save()
        }
    }

    // MARK: - History Operations

    /// Fetches all completion records sorted by date (newest first)
    ///
    /// Returns all TaskCompletion records in the database, ordered by
    /// completion date with the most recent completions first.
    ///
    /// - Returns: Array of all completions sorted by completedAt descending
    func fetchAllCompletions() -> [TaskCompletion] {
        let descriptor = FetchDescriptor<TaskCompletion>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching completions: \(error)")
            return []
        }
    }

    /// Fetches completions for a specific date
    ///
    /// Returns all TaskCompletion records where the completion date
    /// falls on the specified day. Uses Calendar.startOfDay for
    /// proper date comparison that handles timezones correctly.
    ///
    /// - Parameter date: The date to fetch completions for
    /// - Returns: Array of completions for that date, sorted by time
    func fetchCompletions(for date: Date) -> [TaskCompletion] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }

        let descriptor = FetchDescriptor<TaskCompletion>(
            predicate: #Predicate { completion in
                completion.completedAt >= startOfDay && completion.completedAt < endOfDay
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching completions for date: \(error)")
            return []
        }
    }

    /// Fetches completions grouped by date
    ///
    /// Returns a dictionary where keys are dates (normalized to start of day)
    /// and values are arrays of completions for that date. This is the primary
    /// method used by HistoryView to display grouped completion history.
    ///
    /// The grouping uses Calendar.startOfDay to normalize dates, ensuring
    /// proper handling of timezones and daylight saving time transitions.
    ///
    /// - Returns: Dictionary mapping dates to their completions
    func fetchCompletionsGroupedByDate() -> [Date: [TaskCompletion]] {
        let allCompletions = fetchAllCompletions()
        let calendar = Calendar.current

        // Group completions by the start of day they were completed
        // This ensures all completions on the same calendar day are grouped together
        var grouped: [Date: [TaskCompletion]] = [:]

        for completion in allCompletions {
            let dayKey = calendar.startOfDay(for: completion.completedAt)
            if grouped[dayKey] == nil {
                grouped[dayKey] = []
            }
            grouped[dayKey]?.append(completion)
        }

        return grouped
    }

    /// Gets sorted array of dates that have completions
    ///
    /// Returns dates in descending order (newest first) for displaying
    /// in the history view. Only dates with at least one completion
    /// are included.
    ///
    /// - Returns: Array of dates sorted newest to oldest
    func fetchCompletionDates() -> [Date] {
        let grouped = fetchCompletionsGroupedByDate()
        return grouped.keys.sorted(by: >)
    }

    // MARK: - Delete Operations

    /// Deletes a task permanently
    ///
    /// This performs a hard delete, removing the task and all its
    /// completion records from the database. The cascade delete rule
    /// on the relationship handles removing completions automatically.
    ///
    /// - Parameter task: The task to delete
    func deleteTask(_ task: TodoTask) {
        modelContext.delete(task)
        refreshWidgets()
    }

    /// Soft deletes a task by marking it as inactive
    ///
    /// This hides the task from the active list while preserving
    /// its history. Use this when you want to keep completion records.
    ///
    /// - Parameter task: The task to soft delete
    func softDeleteTask(_ task: TodoTask) {
        task.isActive = false
        refreshWidgets()
    }

    // MARK: - Reordering Operations

    /// Reorders tasks by updating their sortOrder values
    ///
    /// Called when the user drags tasks to reorder them in the list.
    /// Updates the sortOrder property of each task to reflect the new
    /// order. Tasks are assigned sequential sortOrder values starting from 0.
    ///
    /// This method performs a bulk update - all tasks in the provided array
    /// have their sortOrder updated to match their array index. The view
    /// should perform the array move operation first, then call this method
    /// to persist the new order.
    ///
    /// - Parameter tasks: Array of tasks in their new order
    func reorderTasks(_ tasks: [TodoTask]) {
        // Update sortOrder for each task based on its position in the array
        // Using enumerated() to get both index and task
        for (index, task) in tasks.enumerated() {
            task.sortOrder = index
        }
    }
}

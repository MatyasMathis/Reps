//
//  TodoTaskTests.swift
//  dailytodolistTests
//
//  Unit tests for TodoTask model logic:
//  - Recurrence type parsing and display
//  - Weekday / month-day serialisation
//  - shouldShowToday() visibility rules
//  - isCompletedToday() completion detection
//

import XCTest
import SwiftData

final class TodoTaskTests: XCTestCase {

    // MARK: - Recurrence Type

    func testDefaultRecurrenceTypeIsNone() {
        let task = TodoTask(title: "Task")
        XCTAssertEqual(task.recurrenceType, .none)
    }

    func testDailyRecurrenceType() {
        let task = TodoTask(title: "Task", recurrenceType: .daily)
        XCTAssertEqual(task.recurrenceType, .daily)
    }

    func testWeeklyRecurrenceType() {
        let task = TodoTask(title: "Task", recurrenceType: .weekly)
        XCTAssertEqual(task.recurrenceType, .weekly)
    }

    func testMonthlyRecurrenceType() {
        let task = TodoTask(title: "Task", recurrenceType: .monthly)
        XCTAssertEqual(task.recurrenceType, .monthly)
    }

    func testLegacyIsRecurringFlagMapsToDaily() {
        let task = TodoTask(title: "Task", isRecurring: true)
        XCTAssertEqual(task.recurrenceType, .daily,
            "isRecurring=true (legacy flag) should map to .daily recurrence")
    }

    func testInvalidRecurrenceTypeRawDefaultsToNone() {
        let task = TodoTask(title: "Task")
        task.recurrenceTypeRaw = "totally_invalid"
        XCTAssertEqual(task.recurrenceType, .none,
            "Unrecognised raw value should fall back to .none")
    }

    func testRecurrenceTypeSetsIsRecurringSideEffect() {
        let task = TodoTask(title: "Task", recurrenceType: .weekly)
        XCTAssertTrue(task.isRecurring,
            "isRecurring must be true when recurrenceType != .none (backward compat)")

        let oneTimeTask = TodoTask(title: "Task", recurrenceType: .none)
        XCTAssertFalse(oneTimeTask.isRecurring,
            "isRecurring must be false for one-time tasks")
    }

    // MARK: - RecurrenceType Display Names

    func testNoneDisplayName() {
        XCTAssertEqual(RecurrenceType.none.displayName, "One Time")
    }

    func testDailyDisplayName() {
        XCTAssertEqual(RecurrenceType.daily.displayName, "Daily")
    }

    func testWeeklyDisplayName() {
        XCTAssertEqual(RecurrenceType.weekly.displayName, "Weekly")
    }

    func testMonthlyDisplayName() {
        XCTAssertEqual(RecurrenceType.monthly.displayName, "Monthly")
    }

    // MARK: - Selected Weekdays

    func testEmptyWeekdaysReturnsEmptyArray() {
        let task = TodoTask(title: "Task", recurrenceType: .weekly)
        XCTAssertTrue(task.selectedWeekdays.isEmpty)
    }

    func testSingleWeekdayRoundTrip() {
        let task = TodoTask(title: "Task", recurrenceType: .weekly, selectedWeekdays: [2])
        XCTAssertEqual(task.selectedWeekdays, [2],
            "A single weekday should survive a raw-string round-trip")
    }

    func testMultipleWeekdaysRoundTrip() {
        let task = TodoTask(title: "Task", recurrenceType: .weekly, selectedWeekdays: [2, 4, 6])
        XCTAssertEqual(task.selectedWeekdays.sorted(), [2, 4, 6])
    }

    func testAllWeekdaysCanBeStored() {
        let allDays = [1, 2, 3, 4, 5, 6, 7] // Sun–Sat
        let task = TodoTask(title: "Task", recurrenceType: .weekly, selectedWeekdays: allDays)
        XCTAssertEqual(task.selectedWeekdays.sorted(), allDays)
    }

    // MARK: - Selected Month Days

    func testEmptyMonthDaysReturnsEmptyArray() {
        let task = TodoTask(title: "Task", recurrenceType: .monthly)
        XCTAssertTrue(task.selectedMonthDays.isEmpty)
    }

    func testSingleMonthDayRoundTrip() {
        let task = TodoTask(title: "Task", recurrenceType: .monthly, selectedMonthDays: [1])
        XCTAssertEqual(task.selectedMonthDays, [1])
    }

    func testMultipleMonthDaysRoundTrip() {
        let task = TodoTask(title: "Task", recurrenceType: .monthly, selectedMonthDays: [1, 15, 30])
        XCTAssertEqual(task.selectedMonthDays.sorted(), [1, 15, 30])
    }

    // MARK: - shouldShowToday()

    func testOneTimeTaskAlwaysShowsToday() {
        let task = TodoTask(title: "Task", recurrenceType: .none)
        XCTAssertTrue(task.shouldShowToday())
    }

    func testDailyTaskAlwaysShowsToday() {
        let task = TodoTask(title: "Task", recurrenceType: .daily)
        XCTAssertTrue(task.shouldShowToday())
    }

    func testFutureStartDateHidesTask() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let task = TodoTask(title: "Task", recurrenceType: .daily, startDate: tomorrow)
        XCTAssertFalse(task.shouldShowToday(),
            "Tasks with a future startDate must not appear until that date")
    }

    func testPastStartDateShowsTask() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let task = TodoTask(title: "Task", recurrenceType: .daily, startDate: yesterday)
        XCTAssertTrue(task.shouldShowToday(),
            "Tasks whose startDate has already passed must be visible today")
    }

    func testTodayStartDateShowsTask() {
        let task = TodoTask(title: "Task", recurrenceType: .daily, startDate: Date())
        XCTAssertTrue(task.shouldShowToday(),
            "Tasks starting today must be visible today")
    }

    func testWeeklyTaskWithNoSelectedDaysShowsEveryDay() {
        let task = TodoTask(title: "Task", recurrenceType: .weekly, selectedWeekdays: [])
        XCTAssertTrue(task.shouldShowToday(),
            "Weekly task with no specific days selected should show every day")
    }

    func testMonthlyTaskWithNoSelectedDaysShowsEveryDay() {
        let task = TodoTask(title: "Task", recurrenceType: .monthly, selectedMonthDays: [])
        XCTAssertTrue(task.shouldShowToday(),
            "Monthly task with no specific dates selected should show every day")
    }

    func testWeeklyTaskShowsOnCorrectWeekday() {
        let allWeekdays = [1, 2, 3, 4, 5, 6, 7]
        let task = TodoTask(title: "Task", recurrenceType: .weekly, selectedWeekdays: allWeekdays)
        // Selecting all days means it always shows.
        XCTAssertTrue(task.shouldShowToday())
    }

    // MARK: - isCompletedToday()

    func testNewTaskIsNotCompletedToday() throws {
        let schema = Schema([TodoTask.self, TaskCompletion.self, CustomCategory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let task = TodoTask(title: "Task")
        context.insert(task)
        try context.save()

        XCTAssertFalse(task.isCompletedToday(),
            "A newly created task must not be completed")
    }

    func testTaskIsCompletedTodayAfterAddingTodayCompletion() throws {
        let schema = Schema([TodoTask.self, TaskCompletion.self, CustomCategory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let task = TodoTask(title: "Task")
        context.insert(task)

        let completion = TaskCompletion(task: task, completedAt: Date())
        context.insert(completion)
        try context.save()

        XCTAssertTrue(task.isCompletedToday(),
            "Task must report completed today after a same-day TaskCompletion is added")
    }

    func testTaskNotCompletedTodayIfCompletionIsYesterday() throws {
        let schema = Schema([TodoTask.self, TaskCompletion.self, CustomCategory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let task = TodoTask(title: "Task")
        context.insert(task)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let completion = TaskCompletion(task: task, completedAt: yesterday)
        context.insert(completion)
        try context.save()

        XCTAssertFalse(task.isCompletedToday(),
            "A completion from yesterday must not count as completed today")
    }

    // MARK: - Recurrence Display String

    func testNoneRecurrenceDisplayStringIsEmpty() {
        let task = TodoTask(title: "Task", recurrenceType: .none)
        XCTAssertEqual(task.recurrenceDisplayString, "")
    }

    func testDailyRecurrenceDisplayString() {
        let task = TodoTask(title: "Task", recurrenceType: .daily)
        XCTAssertEqual(task.recurrenceDisplayString, "DAILY")
    }

    func testWeeklyNoSelectedDaysDisplayString() {
        let task = TodoTask(title: "Task", recurrenceType: .weekly, selectedWeekdays: [])
        XCTAssertEqual(task.recurrenceDisplayString, "WEEKLY")
    }

    func testMonthlyNoSelectedDatesDisplayString() {
        let task = TodoTask(title: "Task", recurrenceType: .monthly, selectedMonthDays: [])
        XCTAssertEqual(task.recurrenceDisplayString, "MONTHLY")
    }

    func testWeeklyWithSelectedDaysDisplaysAbbreviatedNames() {
        // 2=Mon, 4=Wed, 6=Fri
        let task = TodoTask(title: "Task", recurrenceType: .weekly, selectedWeekdays: [2, 4, 6])
        let display = task.recurrenceDisplayString
        XCTAssertTrue(display.contains("MON"), "Display string should contain MON for weekday 2")
        XCTAssertTrue(display.contains("WED"), "Display string should contain WED for weekday 4")
        XCTAssertTrue(display.contains("FRI"), "Display string should contain FRI for weekday 6")
    }

    // MARK: - Task Properties

    func testTaskIsActiveByDefault() {
        let task = TodoTask(title: "Task")
        XCTAssertTrue(task.isActive)
    }

    func testTaskTitleIsPreserved() {
        let task = TodoTask(title: "Morning Workout")
        XCTAssertEqual(task.title, "Morning Workout")
    }

    func testTaskCategoryIsNilByDefault() {
        let task = TodoTask(title: "Task")
        XCTAssertNil(task.category)
    }

    func testTaskCategoryIsPreservedWhenSet() {
        let task = TodoTask(title: "Task", category: "Fitness")
        XCTAssertEqual(task.category, "Fitness")
    }

    func testTaskStartDateIsNilByDefault() {
        let task = TodoTask(title: "Task")
        XCTAssertNil(task.startDate)
    }

    func testStartDateDisplayStringTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let task = TodoTask(title: "Task", startDate: tomorrow)
        XCTAssertEqual(task.startDateDisplayString, "Tomorrow")
    }

    func testStartDateDisplayStringToday() {
        let task = TodoTask(title: "Task", startDate: Date())
        XCTAssertEqual(task.startDateDisplayString, "Today")
    }

    func testStartDateDisplayStringNilWhenNoStartDate() {
        let task = TodoTask(title: "Task")
        XCTAssertNil(task.startDateDisplayString)
    }
}

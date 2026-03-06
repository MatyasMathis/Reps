//
//  TodoTask.swift
//  Shared
//
//  Purpose: Defines the TodoTask model for SwiftData persistence
//  Shared between main app and widget extension.
//

import Foundation
import SwiftData

// MARK: - Recurrence Type Enum

/// Defines the type of recurrence pattern for a task
enum RecurrenceType: String, Codable, CaseIterable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .none: return "One Time"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }

    var subtitle: String {
        switch self {
        case .none: return "Task disappears after completion"
        case .daily: return "Task reappears every day"
        case .weekly: return "Task reappears on selected days"
        case .monthly: return "Task reappears on selected dates"
        }
    }

    var icon: String? {
        switch self {
        case .none: return nil
        case .daily, .weekly, .monthly: return "repeat"
        }
    }
}

/// Represents a task in the to-do list
///
/// Tasks can be one-time or recurring with various patterns:
/// - One-time: Completed once and then removed from today's list permanently
/// - Daily: Reappears every day
/// - Weekly: Reappears on selected weekdays (e.g., Mon, Wed, Fri)
/// - Monthly: Reappears on selected dates (e.g., 1st, 15th)
@Model
final class TodoTask {

    // MARK: - Properties

    /// Unique identifier for the task
    var id: UUID = UUID()

    /// The user-visible title of the task
    var title: String = ""

    /// Optional category for organizing tasks
    var category: String?

    /// Flag indicating if this task repeats daily (kept for backward compatibility)
    var isRecurring: Bool = false

    /// Date when the task was created
    var createdAt: Date = Date()

    /// Sort order for manual task reordering
    var sortOrder: Int = 0

    /// Flag indicating if the task is active (not deleted)
    var isActive: Bool = true

    /// Flag indicating this task was created as part of the onboarding flow.
    /// Used to clean up starter tasks on a new device when the user's real
    /// CloudKit data arrives after the first restart.
    var isOnboarding: Bool = false

    /// Optional start date for the task (nil = starts immediately)
    /// Used for one-time and daily tasks to schedule them for a future date
    var startDate: Date?

    // MARK: - Recurrence Properties

    /// The type of recurrence pattern (none, daily, weekly, monthly)
    var recurrenceTypeRaw: String?

    /// Selected weekdays for weekly recurrence (1=Sun, 2=Mon, ..., 7=Sat)
    /// Stored as comma-separated string for SwiftData compatibility
    var selectedWeekdaysRaw: String?

    /// Selected dates for monthly recurrence (1-31)
    /// Stored as comma-separated string for SwiftData compatibility
    var selectedMonthDaysRaw: String?

    /// Relationship to completion records
    @Relationship(deleteRule: .cascade, inverse: \TaskCompletion.task)
    var completions: [TaskCompletion]?

    // MARK: - Computed Properties

    /// The recurrence type for this task
    var recurrenceType: RecurrenceType {
        get {
            if let raw = recurrenceTypeRaw {
                return RecurrenceType(rawValue: raw) ?? .none
            }
            // Backward compatibility: convert old isRecurring flag
            return isRecurring ? .daily : .none
        }
        set {
            recurrenceTypeRaw = newValue.rawValue
            // Keep isRecurring in sync for backward compatibility
            isRecurring = newValue != .none
        }
    }

    /// Selected weekdays as an array of integers (1=Sun, 2=Mon, ..., 7=Sat)
    var selectedWeekdays: [Int] {
        get {
            guard let raw = selectedWeekdaysRaw, !raw.isEmpty else { return [] }
            return raw.split(separator: ",").compactMap { Int($0) }
        }
        set {
            selectedWeekdaysRaw = newValue.map { String($0) }.joined(separator: ",")
        }
    }

    /// Selected month days as an array of integers (1-31)
    var selectedMonthDays: [Int] {
        get {
            guard let raw = selectedMonthDaysRaw, !raw.isEmpty else { return [] }
            return raw.split(separator: ",").compactMap { Int($0) }
        }
        set {
            selectedMonthDaysRaw = newValue.map { String($0) }.joined(separator: ",")
        }
    }

    // MARK: - Initialization

    init(
        title: String,
        category: String? = nil,
        isRecurring: Bool = false,
        recurrenceType: RecurrenceType = .none,
        selectedWeekdays: [Int] = [],
        selectedMonthDays: [Int] = [],
        sortOrder: Int = 0,
        startDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.isRecurring = isRecurring || recurrenceType != .none
        self.recurrenceTypeRaw = recurrenceType.rawValue
        self.selectedWeekdaysRaw = selectedWeekdays.map { String($0) }.joined(separator: ",")
        self.selectedMonthDaysRaw = selectedMonthDays.map { String($0) }.joined(separator: ",")
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.isActive = true
        self.startDate = startDate
        self.completions = []
    }

    // MARK: - Methods

    /// Checks if the task has been completed today
    func isCompletedToday() -> Bool {
        guard let completions = completions else { return false }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return completions.contains { completion in
            calendar.startOfDay(for: completion.completedAt) == today
        }
    }

    /// Checks if the task should appear today based on its recurrence pattern and start date
    func shouldShowToday() -> Bool {
        let calendar = Calendar.current
        let today = Date()
        let todayStart = calendar.startOfDay(for: today)

        // Check if task has started yet (startDate must be today or earlier)
        if let startDate = startDate {
            let startDateStart = calendar.startOfDay(for: startDate)
            if startDateStart > todayStart {
                return false
            }
        }

        switch recurrenceType {
        case .none:
            // One-time tasks: always show (filtering is done elsewhere)
            return true
        case .daily:
            // Daily tasks: always show
            return true
        case .weekly:
            // Weekly tasks: show only on selected weekdays
            let weekday = calendar.component(.weekday, from: today)
            return selectedWeekdays.isEmpty || selectedWeekdays.contains(weekday)
        case .monthly:
            // Monthly tasks: show only on selected dates
            let dayOfMonth = calendar.component(.day, from: today)
            return selectedMonthDays.isEmpty || selectedMonthDays.contains(dayOfMonth)
        }
    }

    /// Returns a display string for the start date
    var startDateDisplayString: String? {
        guard let startDate = startDate else { return nil }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDay = calendar.startOfDay(for: startDate)

        if startDay == today {
            return "Today"
        } else if startDay == calendar.date(byAdding: .day, value: 1, to: today) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: startDate)
        }
    }

    /// Returns a display string for the recurrence pattern (e.g., "Mon, Wed, Fri")
    var recurrenceDisplayString: String {
        switch recurrenceType {
        case .none:
            return ""
        case .daily:
            return "DAILY"
        case .weekly:
            if selectedWeekdays.isEmpty {
                return "WEEKLY"
            }
            let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let sortedDays = selectedWeekdays.sorted()
            return sortedDays.map { $0 >= 0 && $0 < dayNames.count ? dayNames[$0] : "?" }.joined(separator: ", ").uppercased()
        case .monthly:
            if selectedMonthDays.isEmpty {
                return "MONTHLY"
            }
            let sortedDays = selectedMonthDays.sorted()
            return sortedDays.map { ordinalString($0) }.joined(separator: ", ").uppercased()
        }
    }

    /// Converts a number to ordinal string (1st, 2nd, 3rd, etc.)
    private func ordinalString(_ number: Int) -> String {
        let suffix: String
        let ones = number % 10
        let tens = (number / 10) % 10

        if tens == 1 {
            suffix = "th"
        } else {
            switch ones {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(number)\(suffix)"
    }
}

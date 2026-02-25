//
//  TaskCompletion.swift
//  Shared
//
//  Purpose: Tracks individual completion records for tasks
//  Shared between main app and widget extension.
//

import Foundation
import SwiftData

/// Represents a single completion event for a task
///
/// Each TaskCompletion record represents one instance of completing a task.
@Model
final class TaskCompletion {

    // MARK: - Properties

    /// Unique identifier for this completion record
    var id: UUID = UUID()

    /// The exact date and time when the task was completed
    var completedAt: Date = Date()

    /// Reference to the task that was completed
    var task: TodoTask?

    // MARK: - Initialization

    init(task: TodoTask, completedAt: Date = Date()) {
        self.id = UUID()
        self.completedAt = completedAt
        self.task = task
    }
}

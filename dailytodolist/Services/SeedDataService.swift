//
//  SeedDataService.swift
//  Reps
//
//  Purpose: Populates the app with realistic demo data for App Store screenshots.
//  Only available in DEBUG builds.
//

#if DEBUG
import Foundation
import SwiftData

/// Populates the app with realistic demo data for App Store screenshot purposes.
///
/// Creates 9 daily tasks across Health, Work, and Personal categories with
/// 90 days of completion history — producing a 47-day current streak and
/// a rich Year in Pixels heatmap.
@MainActor
class SeedDataService {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public

    /// Wipes all existing data and inserts fresh demo content.
    func loadDemoData() throws {
        try clearAllData()
        let tasks = insertTasks()
        try modelContext.save()
        insertCompletions(for: tasks)
        try modelContext.save()
    }

    // MARK: - Clear

    private func clearAllData() throws {
        try modelContext.delete(model: TaskCompletion.self)
        try modelContext.delete(model: TodoTask.self)
        try modelContext.delete(model: CustomCategory.self)
    }

    // MARK: - Tasks

    private struct TaskDef {
        let title: String
        let category: String
        let sortOrder: Int
    }

    private let taskDefs: [TaskDef] = [
        // Health (4)
        TaskDef(title: "Morning workout", category: "Health", sortOrder: 0),
        TaskDef(title: "Drink 8 glasses of water", category: "Health", sortOrder: 1),
        TaskDef(title: "Meditate 10 mins", category: "Health", sortOrder: 2),
        TaskDef(title: "Take vitamins", category: "Health", sortOrder: 3),
        // Work (3)
        TaskDef(title: "Review daily priorities", category: "Work", sortOrder: 4),
        TaskDef(title: "Deep work block", category: "Work", sortOrder: 5),
        TaskDef(title: "End of day review", category: "Work", sortOrder: 6),
        // Personal (2)
        TaskDef(title: "Read 20 pages", category: "Personal", sortOrder: 7),
        TaskDef(title: "Journal 5 minutes", category: "Personal", sortOrder: 8),
    ]

    private func insertTasks() -> [TodoTask] {
        let calendar = Calendar.current
        let createdAt = calendar.date(byAdding: .day, value: -90, to: Date()) ?? Date()

        return taskDefs.map { def in
            let task = TodoTask(
                title: def.title,
                category: def.category,
                recurrenceType: .daily,
                sortOrder: def.sortOrder
            )
            task.createdAt = createdAt
            modelContext.insert(task)
            return task
        }
    }

    // MARK: - Completions

    /// Completion strategy:
    ///  - Days 0–46 (today through 46 days ago): 47-day streak.
    ///    Each task has an 88% chance of completion, but we guarantee
    ///    at least 4 tasks complete every day to keep the streak alive.
    ///  - Days 47–89: sporadic activity (30% per task, some days get 0).
    ///    Roughly 60% of those days will have completions to fill the
    ///    Year in Pixels without extending the streak.
    private func insertCompletions(for tasks: [TodoTask]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Seeded RNG for reproducible, realistic-looking data
        var rng = SeededRandom(seed: 42)

        for daysBack in 0...89 {
            guard let day = calendar.date(byAdding: .day, value: -daysBack, to: today) else { continue }

            let inStreakZone = daysBack < 47

            if inStreakZone {
                // Complete each task with 88% probability
                var completed: [TodoTask] = []
                for task in tasks {
                    if rng.nextDouble() < 0.88 {
                        completed.append(task)
                    }
                }
                // Guarantee at least 4 completions to keep the streak
                if completed.count < 4 {
                    let missing = tasks.filter { !completed.contains($0) }
                    completed += missing.prefix(4 - completed.count)
                }
                for task in completed {
                    addCompletion(task: task, day: day, calendar: calendar, rng: &rng)
                }
            } else {
                // Sporadic: ~60% chance the day has any activity at all
                guard rng.nextDouble() < 0.60 else { continue }
                // 30% per task on active days
                for task in tasks where rng.nextDouble() < 0.30 {
                    addCompletion(task: task, day: day, calendar: calendar, rng: &rng)
                }
            }
        }
    }

    private func addCompletion(
        task: TodoTask,
        day: Date,
        calendar: Calendar,
        rng: inout SeededRandom
    ) {
        // Scatter completion times naturally across the day (6 AM – 10 PM)
        let minuteOffset = Int(rng.nextDouble() * 960) + 360 // 360–1320 mins from midnight
        let completedAt = calendar.date(
            byAdding: .minute,
            value: minuteOffset,
            to: day
        ) ?? day

        let completion = TaskCompletion(task: task, completedAt: completedAt)
        modelContext.insert(completion)
    }
}

// MARK: - Seeded Random Number Generator

/// Simple LCG-based RNG for reproducible demo data.
private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }

    /// Returns a value in [0, 1)
    mutating func nextDouble() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}
#endif

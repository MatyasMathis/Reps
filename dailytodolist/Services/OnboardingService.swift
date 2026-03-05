//
//  OnboardingService.swift
//  Reps
//
//  Purpose: Manages first-launch onboarding with starter tasks
//  Design: Teaches by doing, not by explaining
//

import Foundation
import SwiftData

/// Manages first-launch experience with contextual onboarding
@MainActor
class OnboardingService {

    // MARK: - UserDefaults Keys

    private static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private static let hasSeenFirstStreakKey = "hasSeenFirstStreak"

    // MARK: - Properties

    /// Whether the user has already been onboarded.
    ///
    /// Reads from both local UserDefaults and iCloud Key-Value Store so that
    /// returning users on a new device are not shown the starter tasks again.
    static var hasCompletedOnboarding: Bool {
        get {
            // iCloud KV store syncs the flag across all devices on the same Apple ID.
            if NSUbiquitousKeyValueStore.default.bool(forKey: hasCompletedOnboardingKey) {
                return true
            }
            return UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey)
            NSUbiquitousKeyValueStore.default.set(newValue, forKey: hasCompletedOnboardingKey)
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }

    /// Whether the user has seen the first streak celebration (2-day)
    static var hasSeenFirstStreak: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeenFirstStreakKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeenFirstStreakKey) }
    }

    // MARK: - Starter Tasks

    /// Creates starter tasks on first launch that teach the user by doing
    static func createStarterTasksIfNeeded(modelContext: ModelContext) {
        guard !hasCompletedOnboarding else { return }

        let taskService = TaskService(modelContext: modelContext)

        // Task 1: A real daily habit — teaches daily recurrence by showing up tomorrow
        taskService.createTask(
            title: "Drink 8 glasses of water",
            category: "Health",
            recurrenceType: .daily
        )

        // Task 2: One-time task with an invitation to personalise —
        // the user wants to edit this, which teaches the long-press mechanic through motivation
        taskService.createTask(
            title: "Your biggest priority today — long press to make it yours",
            category: "Personal",
            recurrenceType: .none
        )

        // Task 3: A second daily habit — reinforces the daily loop concept
        taskService.createTask(
            title: "5 minute walk outside",
            category: "Health",
            recurrenceType: .daily
        )

        hasCompletedOnboarding = true
    }
}

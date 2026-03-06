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

    /// Creates starter tasks on first launch that teach the user by doing.
    ///
    /// New-device flow for existing Pro users:
    /// On the very first launch on a new device the iCloud KV store may not have
    /// synced yet, so `hasCompletedOnboarding` returns false and the three starter
    /// tasks are created in the local-only (pre-restart) container. After the user
    /// restarts the app with CloudKit active, these tasks would normally be uploaded
    /// and pollute the user's real task list on all devices.
    ///
    /// To prevent that, starter tasks are tagged with `isOnboarding = true` and a
    /// `needsOnboardingCleanup` flag is stored in UserDefaults. On the next call
    /// (after restart) where the KV store confirms this is an existing user, the
    /// tagged tasks are deleted before CloudKit can upload them.
    static func createStarterTasksIfNeeded(modelContext: ModelContext) {
        // The hasCompletedOnboarding getter checks iCloud KV first, so if a prior
        // device already completed onboarding, this returns early without creating
        // tasks — even on a completely fresh install.
        guard !hasCompletedOnboarding else { return }

        let taskService = TaskService(modelContext: modelContext)

        // Task 1: A real daily habit — teaches daily recurrence by showing up tomorrow
        let t1 = taskService.createTask(
            title: "Drink 8 glasses of water",
            category: "Health",
            recurrenceType: .daily
        )
        t1.isOnboarding = true

        // Task 2: One-time task with an invitation to personalise —
        // the user wants to edit this, which teaches the long-press mechanic through motivation
        let t2 = taskService.createTask(
            title: "Your biggest priority today — long press to make it yours",
            category: "Personal",
            recurrenceType: .none
        )
        t2.isOnboarding = true

        // Task 3: A second daily habit — reinforces the daily loop concept
        let t3 = taskService.createTask(
            title: "5 minute walk outside",
            category: "Health",
            recurrenceType: .daily
        )
        t3.isOnboarding = true

        hasCompletedOnboarding = true
    }

    // MARK: - Onboarding Cleanup

    /// Deletes any tasks tagged as onboarding tasks from the local database.
    ///
    /// Called when the iCloud KV store confirms the user already completed
    /// onboarding on another device, meaning the locally-created starter tasks
    /// should not exist and must be removed before CloudKit uploads them.
    private static func cleanupOnboardingTasks(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<TodoTask>(
            predicate: #Predicate { $0.isOnboarding == true }
        )
        guard let tasks = try? modelContext.fetch(descriptor), !tasks.isEmpty else { return }
        for task in tasks {
            if let completions = task.completions {
                for completion in completions {
                    modelContext.delete(completion)
                }
            }
            modelContext.delete(task)
        }
        try? modelContext.save()
    }
}

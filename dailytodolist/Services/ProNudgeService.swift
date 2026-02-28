//
//  ProNudgeService.swift
//  Reps
//
//  Purpose: Controls when and how often pro upgrade nudges are shown to free users
//  Design: Non-intrusive — hard frequency caps and per-milestone dedup prevent annoyance
//

import Foundation

/// Manages the timing and eligibility of proactive pro-feature nudges.
///
/// Rules:
/// - Never shows if Pro is already unlocked
/// - 72-hour cooldown between any two nudges
/// - Stops after 5 dismissals (user has signalled they're not interested)
/// - Each streak milestone and the history-tab nudge fire at most once ever
final class ProNudgeService {

    static let shared = ProNudgeService()
    private init() {}

    // MARK: - Configuration

    private let maxDismissals = 5
    private let cooldownHours: Double = 72

    // MARK: - UserDefaults Keys

    private let lastShownKey = "proNudge_lastShownDate"
    private let dismissCountKey = "proNudge_dismissCount"

    // MARK: - Eligibility Gate

    /// Returns `true` when it is appropriate to show a pro nudge right now.
    var canShow: Bool {
        guard !StoreKitService.shared.isProUnlocked else { return false }

        let dismissCount = UserDefaults.standard.integer(forKey: dismissCountKey)
        guard dismissCount < maxDismissals else { return false }

        if let lastShown = UserDefaults.standard.object(forKey: lastShownKey) as? Date {
            let hoursSince = Date().timeIntervalSince(lastShown) / 3600
            guard hoursSince >= cooldownHours else { return false }
        }

        return true
    }

    // MARK: - State Mutations

    /// Call when a nudge becomes visible (starts cooldown timer).
    func markShown() {
        UserDefaults.standard.set(Date(), forKey: lastShownKey)
    }

    /// Call when the user actively dismisses a nudge (increments dismiss counter + starts cooldown).
    func markDismissed() {
        let current = UserDefaults.standard.integer(forKey: dismissCountKey)
        UserDefaults.standard.set(current + 1, forKey: dismissCountKey)
        markShown()
    }

    // MARK: - Per-Milestone Dedup

    private func streakNudgeKey(for streak: Int) -> String {
        "proNudge_streak_\(streak)"
    }

    func hasShownStreakNudge(for streak: Int) -> Bool {
        UserDefaults.standard.bool(forKey: streakNudgeKey(for: streak))
    }

    func markStreakNudgeShown(for streak: Int) {
        UserDefaults.standard.set(true, forKey: streakNudgeKey(for: streak))
    }

    // MARK: - History Tab Dedup

    var hasSeenHistoryNudge: Bool {
        get { UserDefaults.standard.bool(forKey: "proNudge_historyTabSeen") }
        set { UserDefaults.standard.set(newValue, forKey: "proNudge_historyTabSeen") }
    }

    // MARK: - All-Tasks-Done Daily Dedup

    private var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    var hasShownAllTasksDoneNudgeToday: Bool {
        get { UserDefaults.standard.bool(forKey: "proNudge_allDone_\(todayString)") }
        set { UserDefaults.standard.set(newValue, forKey: "proNudge_allDone_\(todayString)") }
    }
}

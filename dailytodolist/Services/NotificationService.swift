//
//  NotificationService.swift
//  Reps
//
//  Purpose: Manages the daily reminder local notification
//  Design: Singleton that schedules/cancels a repeating daily UNCalendarNotificationTrigger

import UserNotifications
import SwiftUI

/// Manages scheduling and cancellation of the single daily reminder notification.
@MainActor
class NotificationService {

    static let shared = NotificationService()

    private let notificationIdentifier = "dailyReminder"

    private init() {}

    // MARK: - Permission

    /// Requests system notification authorization.
    /// - Returns: `true` if the user granted permission.
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    /// Returns the current system authorization status without prompting.
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - Scheduling

    /// Schedules the daily reminder at the given hour and minute.
    /// Removes any previously scheduled reminder first to avoid duplicates.
    func scheduleReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Put in your reps"
        content.body = "Consistency beats intensity. Your tasks are ready when you are."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// Removes the pending daily reminder.
    func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
}

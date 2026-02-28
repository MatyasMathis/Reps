# Push Notifications Implementation Plan

## Overview

Add a single daily reminder notification to the app. Users can toggle it on/off and choose the delivery time (default: 8:00 AM). All logic is handled via `UserNotifications` framework (local notifications — no server/push infrastructure needed).

---

## Files to Create

### `dailytodolist/Services/NotificationService.swift`

A new `@MainActor` singleton service responsible for all notification logic:

**Responsibilities:**
- Request system notification permission from the user
- Schedule / cancel the daily reminder
- Re-schedule when the user changes the time setting
- Check current authorization status (to handle cases where user denied permission in system Settings)

**Key Properties:**
```swift
@AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false
@AppStorage("notificationHour")     var notificationHour: Int    = 8
@AppStorage("notificationMinute")   var notificationMinute: Int  = 0
private let notificationIdentifier  = "dailyReminder"
```

**Key Methods:**
```swift
func requestPermission() async -> Bool
// Calls UNUserNotificationCenter.requestAuthorization(options: [.alert, .sound])
// Returns true if granted

func scheduleReminder()
// Removes any existing pending request with `notificationIdentifier`
// Creates a UNCalendarNotificationTrigger set to repeat daily at (notificationHour, notificationMinute)
// Content: title "Daily Check-In", body "Time to complete your daily tasks!"
// Adds request to UNUserNotificationCenter

func cancelReminder()
// Removes pending request with `notificationIdentifier`

func checkAuthorizationStatus() async -> UNAuthorizationStatus
// Returns current system permission status
```

---

## Files to Modify

### `dailytodolist/Views/SettingsView.swift`

Add a **Notifications** section above the existing **General** section.

**New Section UI:**
```
─── Notifications ───────────────────────────
  [Bell icon]  Daily Reminder       [ Toggle ]
  [Clock icon] Reminder Time        8:00 AM ▸
──────────────────────────────────────────────
```

**Behavior:**

1. **Toggle ON (notifications were off):**
   - Call `NotificationService.shared.requestPermission()`
   - If granted → set `notificationsEnabled = true`, call `scheduleReminder()`
   - If denied → keep toggle off, show an alert: _"Please enable notifications for REPS in Settings → Notifications."_

2. **Toggle OFF:**
   - Set `notificationsEnabled = false`
   - Call `cancelReminder()`

3. **Time Picker** (shown only when `notificationsEnabled == true`):
   - Uses a `DatePicker` in `.hourAndMinute` display mode
   - Bound to a local `Date` computed from `notificationHour` / `notificationMinute`
   - On change → update `notificationHour` / `notificationMinute`, call `scheduleReminder()`

4. **Edge case — permission revoked externally:**
   - On `.task` / `.onAppear` check `checkAuthorizationStatus()`
   - If status is `.denied` but `notificationsEnabled` is `true` → flip flag to `false` silently
   - Prevents a confusing state where the toggle is on but notifications never fire

**New AppStorage bindings in SettingsView:**
```swift
@AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
@AppStorage("notificationHour")     private var notificationHour: Int    = 8
@AppStorage("notificationMinute")   private var notificationMinute: Int  = 0
```

---

### `dailytodolist/dailytodolistApp.swift`

On app launch (`@main` body), after the existing setup:

```swift
.task {
    // Re-schedule reminder if it was set before (iOS clears pending notifications
    // when the app is reinstalled; this ensures it is always scheduled on launch)
    if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
        NotificationService.shared.scheduleReminder()
    }
}
```

This is safe because `scheduleReminder()` removes the old request before adding a new one, so there is never a duplicate.

---

## Notification Content

| Field   | Value                                   |
|---------|-----------------------------------------|
| Title   | "Daily Check-In"                        |
| Body    | "Time to complete your daily tasks!"    |
| Sound   | `.default`                              |
| Badge   | None (not set)                          |
| Trigger | `UNCalendarNotificationTrigger` daily   |

---

## AppStorage Keys (new)

| Key                    | Type   | Default | Description                       |
|------------------------|--------|---------|-----------------------------------|
| `notificationsEnabled` | Bool   | `false` | Whether the daily reminder is on  |
| `notificationHour`     | Int    | `8`     | Hour component of reminder time   |
| `notificationMinute`   | Int    | `0`     | Minute component of reminder time |

---

## Implementation Steps

1. Create `NotificationService.swift` with the singleton and its four methods.
2. Modify `SettingsView.swift`:
   - Add new AppStorage properties.
   - Add Notifications section with toggle + conditional time picker.
   - Wire toggle logic (permission request / cancel).
   - Wire time picker to reschedule on change.
   - Add `.task` modifier to sync permission status on appear.
3. Modify `dailytodolistApp.swift` to call `scheduleReminder()` on launch when enabled.
4. Test scenarios:
   - First-time enable → permission dialog appears → notification scheduled.
   - Toggle off → notification cancelled.
   - Change time → old notification removed, new one scheduled.
   - Permission denied externally → toggle auto-disables on next app open.
   - App reinstall → notification rescheduled on first launch.

---

## Non-Goals (out of scope for this plan)

- Multiple reminders per day
- Per-task individual reminders
- Rich notification content (images, actions)
- Remote/server push notifications

# App Store Review Response — Guideline 2.1 (Information Needed)

**Submission ID:** 01111a46-108f-4d0a-8782-8263b5cf974a
**App:** REPS — Lock In (v1.0)
**Submitted:** Mar 17, 2026

---

## Notes for App Store Connect — App Review Information

*Copy the content below into the **Notes** field of the App Review Information section in App Store Connect.*

---

### 1. Screen Recording

A screen recording captured on a physical iPhone demonstrating the following flows is attached:

- **App launch & onboarding**: App opens to the Today tab with 3 starter tasks auto-generated on first launch. No account registration required.
- **Core task flow**: Creating a task (title, category, recurrence), completing a task (checkbox tap with animation and haptic), viewing the streak badge.
- **History tab**: Browsing completed tasks grouped by date.
- **Pro purchase flow**: Tapping "Unlock REPS Pro" on the paywall, StoreKit payment sheet, and successful unlock. *(Use sandbox environment for testing — see instructions below.)*
- **Settings**: Enabling daily reminder notifications (permission prompt shown), toggling sound/haptic feedback.
- **Widget**: Adding the "Today's Tasks" home screen widget (small, medium, and large sizes) and tapping it to deep-link into the app.
- **Share feature**: Navigating to Stats → tapping the share icon on a stat card → system share sheet appears with the exported PNG image.

> **Note on screen recording:** A physical iPhone running iOS 17+ is required. The recording was captured using the iOS built-in screen recording feature (Control Center → Screen Recording). The full recording begins with a cold app launch from the home screen.

---

### 2. App Purpose

**REPS** is a daily task management and habit-tracking app designed around the concept of athletic consistency. The name "REPS" reflects the idea that personal progress — like physical training — is built through daily repetition.

**Problem it solves:** Most to-do apps are either too complex (project management tools) or too generic (plain checklists). REPS focuses specifically on the daily repetition of habits and routines, helping users build momentum through streaks, visual progress tracking, and a minimal friction interface.

**Value to users:**
- Create daily, weekly, or monthly recurring tasks alongside one-time to-dos
- Track streaks and completion history to stay accountable
- Visualize a full year of consistency with the "Year in Pixels" heatmap
- Review completion statistics filtered by category (Work, Health, Personal, etc.)
- Add a home screen widget to see and check off today's tasks without opening the app
- Sync tasks across devices via iCloud (Pro feature)

**Target audience:** Individuals who want to build consistent habits and daily routines — athletes, students, professionals, and anyone focused on self-improvement.

---

### 3. Instructions for Accessing and Reviewing Features

**No account or login is required.** The app functions fully offline from first launch.

#### Free Features (available immediately):
1. **Today Tab** — Tap the + button (bottom-right) to create a task. Enter a title, select a category, choose recurrence (One Time or Daily), then tap "Save Task."
2. **Completing Tasks** — Tap the checkbox on any task row. The task animates out and the progress bar updates. Sound and haptic feedback play (if enabled in Settings).
3. **Streak Badge** — Tap the flame/star badge in the top-left of the Today tab to open the Year in Pixels heatmap.
4. **History Tab** — Switch to the History tab (bottom navigation) to view all completed tasks grouped by date.
5. **Settings** — Tap the gear icon (top-right of Today tab) to access notification preferences, sound/haptic toggles, and app info.
6. **Widget** — Long-press the home screen → tap "+" → search "Reps" → choose a size (small, medium, large).

#### Testing REPS Pro ($4.99 one-time, non-renewable):
- Open **Settings** (gear icon) → tap the **Pro** section, **or** complete all tasks on a given day (the Pro nudge card will appear).
- Use Apple's **sandbox IAP environment** (sign in with a Sandbox Apple ID in Settings → App Store on the test device).
- **Product ID:** `com.mathis.reps.pro`
- After purchase: the Statistics dashboard, Year in Pixels sharing, iCloud sync, and custom recurring patterns (weekly/monthly) are unlocked.
- **Restore Purchase:** Available via the "Restore Purchase" link on the paywall screen.

#### Pro Features to Review:
- **Statistics** (History tab → "Stats" button in toolbar): Full dashboard with completion rates, weekly rhythm chart, monthly trend, and per-task analytics. Filter by category using the pill selector.
- **Year in Pixels** (tap streak badge on Today tab): Full-year heatmap. Tap "Share" to export as PNG image.
- **iCloud Sync**: Toggle visible in Settings after Pro unlock. Requires an iCloud account on device. Note: requires app restart after first enabling.
- **Custom Categories** (Add Task → Category section → "+" button): Create a category with a custom SF Symbol icon, color, and name.
- **Weekly/Monthly Recurrence**: Visible in Add Task → Recurrence section after Pro unlock.

#### Share Feature (no additional permissions required):
- History tab → tap "Stats" → scroll to any stat card → tap the share icon. The system share sheet opens with an exportable PNG image.

---

### 4. External Services, Tools, and Platforms

| Service | Purpose | Required? |
|---------|---------|-----------|
| **StoreKit 2** (Apple) | In-app purchase processing for REPS Pro ($4.99 one-time) | Optional — free features work without purchase |
| **CloudKit** (Apple) | Cross-device iCloud sync of tasks and completions | Pro feature only; requires iCloud account |
| **UserNotifications** (Apple) | Local push notifications for daily reminders | Optional; requested at runtime when user enables reminders in Settings |
| **WidgetKit** (Apple) | Today's Tasks home screen widget | Optional; user adds widget manually |
| **AppIntents** (Apple) | Widget interactive task completion without opening app | Powers the widget checkbox interaction |

**No third-party services are used.** The app does not use:
- Analytics or tracking SDKs (no Firebase, Mixpanel, etc.)
- Crash reporting SDKs (relies on Apple's built-in crash reporting)
- Advertising networks
- Authentication services (no login accounts)
- Any external APIs or servers

All user data is stored locally on-device via SwiftData (SQLite) and optionally synced via Apple's CloudKit for Pro users. No user data is transmitted to any developer-controlled servers.

---

### 5. Regional Differences

**REPS functions consistently across all regions.** There are no region-specific features, content restrictions, or functionality differences.

- The app is available worldwide.
- All content (task management, statistics, widgets) is available in all regions.
- The REPS Pro in-app purchase ($4.99 USD or local equivalent) is available in all regions where the App Store supports purchases.
- The app is in English only (no localization for other languages in v1.0).

---

### 6. Regulated Industry

REPS is a productivity / habit tracking app and does not operate in a regulated industry. Specifically:

- It is **not** a medical, health monitoring, or clinical app (no health data collected or processed).
- It is **not** a financial services app.
- It does **not** provide professional advice of any kind.
- It does **not** handle sensitive user data beyond local task/habit records stored on the user's own device.

No regulatory documentation or professional credentials are applicable.

---

## Summary for Reviewer

- **No login required** — launch the app and all core features are immediately accessible.
- **Pro purchase** — test with a Sandbox Apple ID; product ID is `com.mathis.reps.pro`.
- **No camera, location, contacts, or microphone permissions** are requested. The only runtime permission is **notifications** (opt-in, triggered from Settings).
- **No external servers** — all data is local. CloudKit sync uses Apple's infrastructure only.
- The app is a straightforward task tracker with no user-generated content visible to other users, no social features, and no content reporting mechanisms (content is private to each user's device).

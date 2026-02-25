# App Store Deployment Guide — REPS

## Analysis Summary

Your app is well-built. The code architecture, design system, StoreKit 2 integration, widget extension, and legal screens (Privacy Policy, Terms of Service) are all solid. Below is an honest breakdown of what is **missing**, what is **incomplete**, and **feature recommendations** to maximize your chances of success.

---

## What Is Missing

### Critical — Will Block Submission

| # | Issue | Location |
|---|-------|----------|
| 1 | Apple Developer Program membership ($99/yr) | External |
| 2 | App Store Connect listing not created | External |
| 3 | In-App Purchase `com.mathis.reps.pro` not configured in App Store Connect | External |
| 4 | No public Privacy Policy URL (App Store Connect requires a live URL) | External |
| 5 | Export Compliance key missing (`ITSAppUsesNonExemptEncryption`) | `Info.plist` / build settings |
| 6 | No distribution provisioning profile / archive never created | Xcode |
| 7 | App Store screenshots not prepared | External |

### Non-Critical — Will Degrade UX or App Review Experience

| # | Issue | Location |
|---|-------|----------|
| 8 | "Rate on App Store" button does nothing — placeholder comment only | `SettingsView.swift:236` |
| 9 | "Contact / Feedback" button does nothing — placeholder comment only | `SettingsView.swift:248` |
| 10 | No Support URL configured for App Store Connect | External |
| 11 | No App Review Notes prepared (reviewer will not know how to test Pro) | External |

---

## Step-by-Step Guide for Each Missing Item

---

### Step 1 — Apple Developer Program

**What:** A paid membership required to submit to the App Store.

1. Go to [developer.apple.com/programs](https://developer.apple.com/programs/)
2. Sign in with your Apple ID
3. Click **Enroll** → select **Individual** (or Organization if you have a company)
4. Pay the $99/year fee
5. Wait for activation email (usually instant for individuals, up to 48 hours for organizations)

---

### Step 2 — Create the App in App Store Connect

**What:** Registers your app and creates the listing page.

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - **Platform:** iOS
   - **Name:** REPS - Daily To-Do List *(or your preferred title)*
   - **Primary Language:** English (or your locale)
   - **Bundle ID:** `com.mathis.reps` *(must match your Xcode project exactly)*
   - **SKU:** `reps-ios-1` *(any unique internal identifier)*
4. Click **Create**

---

### Step 3 — Configure the In-App Purchase in App Store Connect

**What:** Your local `Products.storekit` file works only for testing. The real product must exist in App Store Connect for production.

1. In App Store Connect, go to your app → **Monetization** → **In-App Purchases**
2. Click **+** to create a new IAP
3. Select **Non-Consumable** (matches your local StoreKit config)
4. Fill in:
   - **Reference Name:** REPS Pro
   - **Product ID:** `com.mathis.reps.pro` *(must match `StoreKitService.proProductID` exactly)*
5. Under **Pricing**, set price to **$4.99** (Tier 5)
6. Under **App Store Localization**, add:
   - **Display Name:** REPS Pro
   - **Description:** Unlock Stats, Year in Pixels, and shareable completion cards.
7. Upload a **screenshot** (can be a screenshot of your PaywallView — required for IAP review)
8. Set status to **Ready to Submit**

---

### Step 4 — Create a Public Privacy Policy URL

**What:** App Store Connect requires a live, publicly accessible URL. Your in-app `PrivacyPolicyView` does not count.

**Quickest option (free):**

1. Go to [notion.so](https://notion.so) and create a new page
2. Copy the text content from `/home/user/IOS-To-Do-List/dailytodolist/Views/PrivacyPolicyView.swift` (the strings inside the view)
3. Paste it as a Notion page
4. Click **Share** → **Publish to web** → copy the public URL
5. Paste this URL into App Store Connect under **App Information → Privacy Policy URL**

**Alternative options:**
- GitHub Pages (free, professional)
- Your own domain (`yourdomain.com/privacy`)
- Carrd.co (free static sites)

---

### Step 5 — Add Export Compliance Key

**What:** Apple requires you to declare whether your app uses encryption. Your app uses HTTPS (URLSession/StoreKit), which counts as standard encryption exempt from US export regulations.

**In Xcode:**

1. Open `dailytodolist.xcodeproj`
2. Select the `dailytodolist` target → **Info** tab
3. Click **+** to add a new key
4. Add: `ITSAppUsesNonExemptEncryption` → **Boolean** → **NO**

**Or directly in build settings** by adding to the auto-generated Info.plist section of `project.pbxproj`:
```
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO
```

This tells Apple your app only uses standard HTTPS/TLS (exempt) and no custom encryption algorithms. Setting it to `NO` skips the export compliance questionnaire on every upload.

---

### Step 6 — Create Distribution Provisioning Profile & Archive

**What:** You need to build a release-signed binary and upload it to App Store Connect.

#### 6a. Register App ID (if not already)

1. Go to [developer.apple.com/account](https://developer.apple.com/account) → **Certificates, IDs & Profiles**
2. Click **Identifiers** → **+**
3. Select **App IDs** → **App**
4. Fill in:
   - **Description:** REPS Daily To-Do List
   - **Bundle ID:** `com.mathis.reps` (Explicit)
5. Under **Capabilities**, enable:
   - **App Groups** (add `group.com.mathis.reps`)
   - **WidgetKit** (may not be listed — it's automatic)
   - **Siri** (for App Intents / ToggleTaskIntent)
6. Click **Continue** → **Register**

#### 6b. Register Widget Extension App ID

Repeat the same process for:
- **Bundle ID:** `com.mathis.reps.TodayTasksWidget`
- Enable **App Groups** → add same `group.com.mathis.reps`

#### 6c. Create Distribution Certificate

1. In Xcode → **Settings** → **Accounts** → select your Apple ID → **Manage Certificates**
2. Click **+** → **Apple Distribution**
3. Xcode creates and installs the certificate automatically

#### 6d. Archive the App

1. In Xcode, select the **dailytodolist** scheme
2. Set destination to **Any iOS Device (arm64)**
3. Menu: **Product** → **Archive**
4. Wait for the build to complete (the Organizer window opens automatically)

#### 6e. Upload to App Store Connect

1. In the Organizer, select your archive
2. Click **Distribute App**
3. Select **App Store Connect** → **Upload**
4. Follow the wizard (Xcode handles signing automatically with Automatic signing)
5. When upload completes, the build appears in App Store Connect under **TestFlight** within ~30 minutes

---

### Step 7 — Prepare App Store Screenshots

**What:** Required for every supported device size. You need at minimum the **6.9" iPhone** size (iPhone 16 Pro Max). Screenshots of **5.5" iPhone** (iPhone 8 Plus) are also required unless you check "Use 6.9-inch screenshots."

#### How to capture screenshots:

1. Open your project in Xcode
2. Run the app on the **iPhone 16 Pro Max simulator** (set to light or dark mode — dark looks great for your app)
3. Navigate to each key screen
4. Press `Cmd+S` or use the simulator menu **File → Save Screenshot** (saves to Desktop)

#### Recommended screens to capture (5-10 screenshots):

1. **Today's task list** — shows tasks with progress card and streak
2. **Add Task sheet** — shows recurrence picker and categories
3. **History view** — shows completion calendar
4. **Stats view** — shows analytics (use debug toggle to enable Pro for screenshot)
5. **Year in Pixels** — the annual habit calendar (visually striking)
6. **Paywall / Upgrade screen** — shows the Pro offer
7. **Widget on home screen** — use a real device or simulator widget screenshot

#### Screenshot specifications:

| Device | Size | Required |
|--------|------|----------|
| iPhone 16 Pro Max | 1320 × 2868 px | Yes |
| iPhone 8 Plus | 1242 × 2208 px | Yes (or use 6.9" for all) |
| iPad Pro 13" | 2064 × 2752 px | Only if you target iPad |

**Tip:** Use [screenshots.pro](https://screenshots.pro) or Figma to add device frames and marketing text overlay to your screenshots. It significantly increases conversion.

---

### Step 8 — Implement "Rate on App Store" Button

**What:** `SettingsView.swift:236` has a placeholder comment with no implementation.

**In Xcode**, replace the empty action closure on `aboutRow(icon: "star", title: "Rate on App Store")`:

```swift
aboutRow(icon: "star", title: "Rate on App Store") {
    // Replace YOUR_APP_ID with the numeric ID from App Store Connect
    // (found under App Information → Apple ID, e.g. 6742098765)
    if let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID?action=write-review") {
        UIApplication.shared.open(url)
    }
}
```

You get the App ID numeric value from App Store Connect → App Information → **Apple ID** (visible after you create the listing in Step 2).

---

### Step 9 — Implement "Contact / Feedback" Button

**What:** `SettingsView.swift:248` has a placeholder comment with no implementation.

**Option A — Open Mail compose:**

```swift
aboutRow(icon: "envelope", title: "Contact / Feedback") {
    let email = "your@email.com"
    let subject = "REPS App Feedback"
    let body = "App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
    let encoded = "mailto:\(email)?subject=\(subject)&body=\(body)"
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
        UIApplication.shared.open(url)
    }
}
```

**Option B — Open a feedback form URL** (Notion form, Typeform, Google Forms):

```swift
aboutRow(icon: "envelope", title: "Contact / Feedback") {
    if let url = URL(string: "https://your-feedback-form-url.com") {
        UIApplication.shared.open(url)
    }
}
```

---

### Step 10 — App Store Connect Listing Content

Fill in the following in App Store Connect → your app → **App Store** tab:

#### App Information
- **Name:** REPS - Daily To-Do List *(30 chars max)*
- **Subtitle:** Build habits. Lock in. *(30 chars max)*
- **Category:** Productivity
- **Secondary Category:** Health & Fitness (optional, matches the Whoop-inspired branding)

#### Description (4000 chars max — example):
```
REPS is the no-nonsense habit tracker for people who get things done.

Build daily routines, track recurring tasks, and watch your streaks grow.
No fluff. No cluttered dashboards. Just your tasks, your progress, your reps.

CORE FEATURES
• Daily task list with progress tracking
• Recurring tasks — daily, weekly on specific days, or monthly on specific dates
• Drag-to-reorder your incomplete tasks
• Task history with calendar view
• Streak counter — consecutive days with completions
• Custom categories with icons and colors
• Home Screen and Lock Screen widgets

REPS PRO — ONE-TIME PURCHASE, $4.99
• Advanced Statistics — weekly rhythm, monthly trends, per-task streaks
• Year in Pixels — your annual habit calendar at a glance
• Shareable completion cards — post your wins

YOUR DATA STAYS ON YOUR DEVICE
REPS stores everything locally using SwiftData. No account required. No cloud sync. No tracking.

Lock in.
```

#### Keywords (100 chars max — comma separated):
```
habit tracker,to do list,daily tasks,routine,streak,productivity,task manager,recurring,widget
```

#### Support URL:
Link to your email or a support page (e.g. `mailto:your@email.com` doesn't work here — use a real URL like a Notion page or your website).

---

### Step 11 — App Review Information

In App Store Connect → your app → **App Review** section:

- **Sign-In Required:** No (your app works without an account)
- **Notes for App Reviewer:**
  ```
  To test the Pro in-app purchase, use the Sandbox test account
  (provided in the Sandbox Testers section of App Store Connect).

  The IAP product ID is: com.mathis.reps.pro
  Price: $4.99 (Sandbox purchases are free).

  Tap the crown icon or the UPGRADE button in Settings to access the paywall.
  Pro features unlocked: Stats tab, Year in Pixels, shareable cards.

  The widget can be added from the iOS widget picker by searching "REPS".
  ```

---

### Step 12 — Submit for Review

1. In App Store Connect → your app:
   - Add the build uploaded in Step 6
   - Fill in all metadata (Steps 7, 10)
   - Set price: **Free** (with IAP)
   - Set availability: All countries (or select)
   - Answer **Age Rating** questionnaire (select "None" for all — this is a clean productivity app)
2. Click **Add for Review** → **Submit to App Review**
3. Wait 24–48 hours (Apple's average review time as of 2026)

---

## Feature Recommendations

These are features that would increase user retention, conversion to Pro, and App Store ratings. Listed by priority.

---

### High Priority

#### 1. Notifications / Reminders
**Why:** The #1 requested feature for any to-do app. Without reminders, users forget to open the app, streaks break, churn happens.

**What to build:**
- Per-task reminder time (e.g. "Remind me at 9:00 AM")
- Daily summary notification ("You have 3 tasks today")
- Streak protection alert ("Don't lose your 7-day streak!")
- Uses `UserNotifications` framework — no additional entitlements needed

---

#### 2. iCloud Sync
**Why:** Users switch between iPhone and iPad. SwiftData currently stores data only on-device. Losing a phone = losing all task history.

**What to build:**
- Enable **CloudKit** entitlement on the App ID
- Change `SharedModelContainer` to use `ModelConfiguration` with `CloudKit`
- Data syncs automatically across all devices signed into the same Apple ID
- Free for users, no backend needed

---

#### 3. Task Priority / Urgency
**Why:** Not all tasks are equal. Power users want to mark tasks as high/medium/low priority.

**What to build:**
- Add a `priority: TaskPriority` enum to `TodoTask.swift` (`.low`, `.medium`, `.high`)
- Show a colored dot or exclamation badge on `TaskRow.swift`
- Allow sorting by priority in `TaskListView.swift`

---

### Medium Priority

#### 4. Siri Shortcuts Customization
**Why:** You already have `ToggleTaskIntent` wired up. Exposing it as an Siri Shortcut phrase lets power users say "Hey Siri, mark gym as done."

**What to build:**
- Add an `AppShortcutsProvider` conformance to expose phrases
- Appear in Shortcuts.app for automation
- No additional entitlements needed

---

#### 5. Onboarding Improvements
**Why:** First-run experience drives activation. `OnboardingService.swift` exists but its quality depends on the implementation.

**What to build:**
- 3-screen onboarding: What is REPS → How recurring tasks work → Unlock Pro
- Pre-populate 3–5 example tasks so the list isn't empty on day 1
- Request notification permission during onboarding (higher acceptance rate when contextual)

---

#### 6. Lock Screen Widget Improvements
**Why:** You already have the widget. Making it more useful drives daily opens.

**What to build:**
- Show current streak on the small widget
- Tap a task row directly to toggle it (App Intents)
- Add a "progress ring" accessory widget showing today's completion %

---

#### 7. Task Notes / Description Field
**Why:** Simple tasks often need a one-line note ("call John re: invoice" → note: phone number).

**What to build:**
- Add `notes: String?` to `TodoTask.swift`
- Show a notes field in `AddTaskSheet.swift` and `EditTaskSheet.swift` (collapsed by default)
- Display a small note icon on `TaskRow.swift` when notes exist

---

### Lower Priority / Nice to Have

#### 8. Passcode / Face ID Lock
Lock the app with Face ID for privacy-conscious users. Uses `LocalAuthentication` framework.

#### 9. CSV / JSON Export
Let users export their task history. Useful for power users, supports the "your data is yours" privacy angle.

#### 10. Apple Watch App
A WatchKit or SwiftUI Watch app to view today's tasks and tap to complete them. Significant development effort but differentiates the app on the App Store.

#### 11. Focus Modes Integration
Expose the app as a **Focus Filter** so tasks auto-filter to work tasks when Work Focus is active, personal tasks in Personal Focus.

---

## Quick Wins Checklist (Do These Before Submitting)

- [ ] Add `ITSAppUsesNonExemptEncryption = NO` to build settings
- [ ] Implement "Rate on App Store" action (Step 8)
- [ ] Implement "Contact / Feedback" action (Step 9)
- [ ] Create App Store Connect listing (Step 2)
- [ ] Configure IAP in App Store Connect (Step 3)
- [ ] Publish Privacy Policy to a public URL (Step 4)
- [ ] Take and upload screenshots (Step 7)
- [ ] Write App Review notes (Step 11)
- [ ] Archive and upload build (Step 6)

---

*Guide written for REPS v1.0, Xcode 26, iOS 17+ deployment target.*

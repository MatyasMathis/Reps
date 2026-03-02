# App Store Release Checklist — REPS

**App:** REPS
**Bundle ID:** `com.mathis.reps`
**Version:** 1.0 (Build 1)
**IAP Product:** `com.mathis.reps.pro` — REPS Pro ($4.99 one-time)

Legend: ✅ Done · ⬜ Needs action · ⚠️ Needs verification

---

## 1. Apple Developer Portal

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1.1 | App ID `com.mathis.reps` registered | ⚠️ | Verify in developer.apple.com → Identifiers |
| 1.2 | Capabilities enabled on App ID: **App Groups**, **CloudKit**, **Push Notifications** | ⚠️ | Must match entitlements exactly |
| 1.3 | App Group `group.com.mathis.reps` registered | ⚠️ | Required for widget ↔ app data sharing |
| 1.4 | CloudKit container `iCloud.com.mathis.reps` created | ⚠️ | Required for Pro iCloud sync |
| 1.5 | Widget extension App ID `com.mathis.reps.TodayTasksWidget` registered | ⚠️ | Separate identifier for the widget |
| 1.6 | Distribution provisioning profiles created (App Store distribution) | ⚠️ | One for main app, one for widget |
| 1.7 | Distribution certificate valid and not expired | ⚠️ | Check in Keychain + developer portal |

---

## 2. App Store Connect Setup

| # | Item | Status | Notes |
|---|------|--------|-------|
| 2.1 | App created in App Store Connect with bundle ID `com.mathis.reps` | ⬜ | One-time step |
| 2.2 | Agreements, Tax, and Banking completed | ⬜ | **Required before any paid IAP can go live** |
| 2.3 | IAP product `com.mathis.reps.pro` created (Non-Consumable, $4.99) | ⬜ | Must match `StoreKitService.proProductID` exactly |
| 2.4 | IAP product submitted for review (reference screenshots, review notes) | ⬜ | Can be submitted alongside the app |
| 2.5 | App primary language set | ⬜ | English (or your target locale) |
| 2.6 | App category selected | ⬜ | Recommended: **Productivity** (primary), Health & Fitness (secondary) |
| 2.7 | Content rights declaration completed | ⬜ | Confirm you own all content |

---

## 3. App Store Listing Metadata

| # | Item | Status | Notes |
|---|------|--------|-------|
| 3.1 | **App name** — "Reps" | ✅ | Set in build settings |
| 3.2 | **Subtitle** (30 chars max) | ⬜ | e.g. "Daily Habits & Task Tracker" |
| 3.3 | **Promotional text** (170 chars, updatable without resubmission) | ⬜ | Use for launch messaging |
| 3.4 | **Full description** (4000 chars max) | ⬜ | Explain features, Pro benefits, widget |
| 3.5 | **Keywords** (100 chars total, comma-separated) | ⬜ | e.g. `habits,tasks,to-do,daily,routine,tracker,productivity,widget` |
| 3.6 | **Support URL** | ⬜ | Must be live (GitHub page, Notion, or simple landing page) |
| 3.7 | **Marketing URL** (optional) | ⬜ | Product landing page |
| 3.8 | **Privacy Policy URL** (hosted, publicly accessible) | ⬜ | **Required by App Store.** The in-app view alone is not sufficient — you need a hosted URL (GitHub Pages, Notion public page, etc.) |
| 3.9 | **Copyright** field | ⬜ | e.g. "© 2026 Mathis Matyas-Istvan" |

---

## 4. App Store Screenshots (Required)

Apple requires at minimum one set of screenshots. These sizes are mandatory:

| # | Device / Size | Status | Notes |
|---|--------------|--------|-------|
| 4.1 | **iPhone 6.7"** — 1290 × 2796 px (iPhone 15 Pro Max) | ⬜ | **Required** |
| 4.2 | **iPhone 6.5"** — 1242 × 2688 px (iPhone 14 Plus / 11 Pro Max) | ⬜ | Required if 6.7" not provided alone |
| 4.3 | **iPhone 5.5"** — 1242 × 2208 px (iPhone 8 Plus) | ⬜ | Required for older device support |
| 4.4 | **iPad Pro 12.9"** — 2048 × 2732 px | ⬜ | Required since the app supports iPad |
| 4.5 | **iPad Pro 11"** — 1668 × 2388 px | ⬜ | Recommended |
| 4.6 | App preview video (optional, 15–30 sec, landscape or portrait) | ⬜ | Strongly recommended; improves conversion |

**Screenshot tips:** Show the task list, streak stats, widget, and Pro paywall. Dark mode looks great — use it. Use a tool like Rottenwood, ScreenshotCreator, or Figma to add device frames + captions.

---

## 5. Age Rating

| # | Item | Status | Notes |
|---|------|--------|-------|
| 5.1 | Age rating questionnaire completed in App Store Connect | ⬜ | App has no mature content — expected rating: **4+** |

---

## 6. Export Compliance (Encryption)

| # | Item | Status | Notes |
|---|------|--------|-------|
| 6.1 | Export compliance answered in App Store Connect | ⬜ | CloudKit uses Apple's encryption. Answer **"Yes, it uses encryption"** then select **"Exempt"** (uses standard iOS encryption only, no custom crypto) |

---

## 7. Code Fixes Required Before Submission

These are placeholder buttons in `SettingsView.swift` that currently do nothing:

| # | Item | Status | File |
|---|------|--------|------|
| 7.1 | **"Rate on App Store"** — wire up to actual App Store review link | ✅ | `SettingsView.swift` — needs App Store ID after app is created |
| 7.2 | **"Contact / Feedback"** — wire up to `mailto:` or feedback URL | ✅ | `SettingsView.swift` |

> **Note:** The App Store review link uses the format `https://apps.apple.com/app/idYOUR_APP_ID?action=write-review`. You'll get the App Store ID after creating the app in App Store Connect. Update `SettingsView.swift` once you have it.

---

## 8. Build & Archive

| # | Item | Status | Notes |
|---|------|--------|-------|
| 8.1 | All warnings resolved (check Xcode's Issue Navigator) | ⬜ | Zero warnings preferred before submission |
| 8.2 | Archive built in **Release** configuration (`Product → Archive`) | ⬜ | Must be on a Mac with Xcode installed |
| 8.3 | Archive validated in Xcode Organizer (no errors) | ⬜ | Catches entitlement / icon / metadata issues |
| 8.4 | Build uploaded to App Store Connect | ⬜ | Via Xcode Organizer or `xcrun altool` |
| 8.5 | Build selected in App Store Connect for the submission | ⬜ | May take 15–30 min to process after upload |

---

## 9. TestFlight (Recommended Before Submission)

| # | Item | Status | Notes |
|---|------|--------|-------|
| 9.1 | Internal testers added and build distributed via TestFlight | ⬜ | Test on real device; simulator doesn't test IAP or CloudKit |
| 9.2 | REPS Pro purchase tested end-to-end in sandbox environment | ⬜ | Use Sandbox Apple ID in TestFlight |
| 9.3 | Widget displays correctly on home screen and lock screen | ⬜ | Test all sizes: small, medium, large |
| 9.4 | iCloud sync tested across two devices (Pro feature) | ⬜ | Log into same iCloud account on both devices |
| 9.5 | Notifications fire at the scheduled time | ⬜ | Background app refresh must be on |
| 9.6 | Restore Purchases button works | ⬜ | Log out + log in with sandbox account |

---

## 10. App Review Notes (for Apple's Review Team)

When submitting, provide review notes explaining:

```
Test Account: Not required — the app works offline with no account.

In-App Purchase Testing:
- Use the sandbox IAP system to test "REPS Pro" ($4.99 one-time purchase)
- Product ID: com.mathis.reps.pro

CloudKit / iCloud:
- iCloud sync is a Pro-only feature. Enable it by purchasing REPS Pro.
- Requires signing into an iCloud account on device.

Widget:
- Long-press home screen → Add Widget → Search "Reps" to add the Today's Tasks widget.
- Available in small, medium, and large sizes.

Camera / Photo Library:
- Used only in the Share Card feature (Stats tab → Share)
- Tap the share icon on any stat card to trigger photo access.
```

---

## 11. Post-Launch

| # | Item | Status | Notes |
|---|------|--------|-------|
| 11.1 | Update "Rate on App Store" deep link in Settings with the real App Store ID | ⬜ | Can be done in a quick follow-up update |
| 11.2 | Monitor crash reports via Xcode Organizer / Instruments | ⬜ | No third-party crash SDK — rely on Apple's built-in reporting |
| 11.3 | Respond to App Store reviews | ⬜ | Check App Store Connect regularly |
| 11.4 | Plan 1.1 update based on user feedback | ⬜ | Common requests: additional recurrence types, more stats |

---

## Summary — What's Blocking Release Right Now

1. **Apple Developer Portal** — verify App ID capabilities, App Group, and CloudKit container are all created and match the entitlements.
2. **App Store Connect** — create the app listing, complete Agreements/Tax/Banking, and register the IAP product `com.mathis.reps.pro`.
3. **Hosted Privacy Policy URL** — the in-app view exists but App Store Connect requires a publicly accessible URL.
4. **App Store screenshots** — minimum: iPhone 6.7" + iPhone 5.5" + iPad 12.9" sets.
5. **App metadata** — subtitle, description, keywords, support URL.
6. **Export compliance** — answer the encryption question (select Exempt).
7. **Archive & upload** — build the Release archive on a Mac and upload to App Store Connect.
8. **"Rate on App Store" and "Contact / Feedback" buttons** — currently placeholders; wired up in this update with your email; the App Store deep link needs updating once you have the App Store ID.

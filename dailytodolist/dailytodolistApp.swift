//
//  RepsApp.swift
//  Reps
//
//  Created by Mathis Matyas-Istvan on 24.01.2026.
//
//  Purpose: Main entry point for the Reps app
//  Key responsibilities:
//  - Configure SwiftData model container for persistence (shared with widget)
//  - Set up the main app window with tab navigation
//  - Handle deep links from widget
//

import SwiftUI
import SwiftData
import UserNotifications

/// Notification posted when the app should navigate to the Tasks tab
extension Notification.Name {
    static let navigateToTasks = Notification.Name("navigateToTasks")
}

/// Main application entry point
///
/// Configures the SwiftData persistence layer and sets up the root view.
/// Uses SharedModelContainer to share data with the widget extension.
/// When the user has REPS Pro, a CloudKit-backed container is created at launch
/// (based on a cached UserDefaults flag) to enable iCloud sync.
@main
struct RepsApp: App {
    let container: ModelContainer
    @State private var showSplash = true
    @State private var showSyncActivatedAlert = false
    @ObservedObject private var store = StoreKitService.shared

    /// Dark mode preference — defaults to true (dark mode on first launch).
    /// Changing this value instantly re-applies the color scheme app-wide.
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true

    init() {
        // Check both the local cache and the iCloud KV store so that a Pro purchase
        // made on another device is recognised here without requiring a re-purchase.
        let localCache = UserDefaults.standard.bool(forKey: StoreKitService.proUnlockedCacheKey)
        let iCloudCache = NSUbiquitousKeyValueStore.default.bool(forKey: StoreKitService.proUnlockedCacheKey)
        let isPro = localCache || iCloudCache

        // Keep the local cache in sync with what iCloud reported.
        if iCloudCache && !localCache {
            UserDefaults.standard.set(true, forKey: StoreKitService.proUnlockedCacheKey)
        }

        container = SharedModelContainer.makeContainer(cloudSyncEnabled: isPro)
        // Record whether CloudKit was active at this launch so the Settings UI can
        // show the correct sync status without waiting for async StoreKit validation.
        UserDefaults.standard.set(isPro, forKey: "cloudKitActiveOnLaunch")
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .onChange(of: store.isProUnlocked) { _, newValue in
                        // When Pro is purchased mid-session, CloudKit isn't active yet
                        // (the container was already created without it). Prompt restart.
                        let wasActiveOnLaunch = UserDefaults.standard.bool(forKey: "cloudKitActiveOnLaunch")
                        if newValue && !wasActiveOnLaunch {
                            showSyncActivatedAlert = true
                        }
                    }
                    .alert("iCloud Sync Enabled", isPresented: $showSyncActivatedAlert) {
                        Button("Got it") {}
                    } message: {
                        Text("Restart the app to activate iCloud sync across your devices.")
                    }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // Dismiss splash after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
            .task {
                // Re-schedule the daily reminder on every launch.
                // iOS can clear pending notifications after a reinstall, so this
                // ensures the reminder is always active if the user enabled it.
                let defaults = UserDefaults.standard
                if defaults.bool(forKey: "notificationsEnabled") {
                    let hour = defaults.object(forKey: "notificationHour") != nil
                        ? defaults.integer(forKey: "notificationHour") : 8
                    let minute = defaults.integer(forKey: "notificationMinute")
                    NotificationService.shared.scheduleReminder(hour: hour, minute: minute)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .modelContainer(container)
    }

    /// Handles deep links from the widget
    ///
    /// URL scheme: reps://tasks
    /// Posts a notification to navigate to the tasks tab.
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "reps" else { return }

        switch url.host {
        case "tasks":
            NotificationCenter.default.post(
                name: .navigateToTasks,
                object: nil
            )
        default:
            break
        }
    }
}

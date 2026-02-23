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

/// Notification posted when the app should navigate to the Tasks tab
extension Notification.Name {
    static let navigateToTasks = Notification.Name("navigateToTasks")
}

/// Main application entry point
///
/// Configures the SwiftData persistence layer and sets up the root view.
/// Uses SharedModelContainer to share data with the widget extension.
@main
struct RepsApp: App {
    @AppStorage("colorSchemePreference") private var colorSchemePreference: String = "dark"
    @State private var showSplash = true

    private var resolvedColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "system": return nil
        default: return .dark
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .preferredColorScheme(resolvedColorScheme)
            .onAppear {
                // Dismiss splash after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
        }
        // Use shared model container for widget data access
        .modelContainer(SharedModelContainer.sharedModelContainer)
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

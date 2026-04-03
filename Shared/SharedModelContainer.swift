//
//  SharedModelContainer.swift
//  Reps
//
//  Purpose: Provides a shared SwiftData container accessible by both
//  the main app and the widget extension via App Groups.
//

import SwiftData
import Foundation

/// Shared model container for cross-target data access
///
/// Uses an App Group container to store the SQLite database in a location
/// accessible by both the main app and the widget extension.
enum SharedModelContainer {
    /// The App Group identifier shared between app and widget
    static let appGroupIdentifier = "group.com.mathis.reps"

    private static let schema = Schema([
        TodoTask.self,
        TaskCompletion.self,
        CustomCategory.self
    ])

    private static var storeURL: URL {
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) {
            return containerURL.appendingPathComponent("reps.sqlite")
        }
        // Fallback: App Group not accessible (misconfigured signing/capabilities).
        // Use Documents directory so the app can still launch; widget data sharing
        // will not work until the App Group capability is restored in Xcode.
        assertionFailure("App Group '\(appGroupIdentifier)' unavailable — check Signing & Capabilities for both targets.")
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("reps.sqlite")
    }

    /// Creates a ModelContainer for the main app.
    /// - Parameter cloudSyncEnabled: Pass `true` for Pro users to enable iCloud sync via CloudKit.
    static func makeContainer(cloudSyncEnabled: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: cloudSyncEnabled ? .automatic : .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    /// Local-only container used by the widget extension and App Intents.
    /// Widget extensions cannot use CloudKit; they read the shared SQLite file directly.
    static var sharedModelContainer: ModelContainer = {
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create shared ModelContainer: \(error)")
        }
    }()
}

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
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            fatalError("Failed to get App Group container URL for \(appGroupIdentifier)")
        }
        return containerURL.appendingPathComponent("reps.sqlite")
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

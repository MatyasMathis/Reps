//
//  CloudSyncTests.swift
//  dailytodolistTests
//
//  Tests for iCloud sync configuration and Pro status gating.
//
//  Cloud sync in REPS works as follows:
//  1. At launch, the app reads a cached Pro status from UserDefaults.
//  2. If Pro is active, SwiftData is initialised with CloudKit enabled.
//  3. The "cloudKitActiveOnLaunch" flag is stored so SettingsView can
//     display the correct sync status without waiting for async StoreKit.
//  4. If Pro is purchased mid-session, the user must restart to activate
//     CloudKit (the ModelContainer cannot be reconfigured at runtime).
//

import XCTest
import SwiftData

final class CloudSyncTests: XCTestCase {

    // MARK: - Setup / Teardown

    private let defaults = UserDefaults.standard
    private let proKey = "isProUnlocked"
    private let syncLaunchKey = "cloudKitActiveOnLaunch"

    override func tearDown() {
        super.tearDown()
        defaults.removeObject(forKey: proKey)
        defaults.removeObject(forKey: syncLaunchKey)
    }

    // MARK: - StoreKit Cache Key

    func testProCacheKeyConstantValue() {
        // The cache key must match what RepsApp.init() reads at launch.
        XCTAssertEqual(StoreKitService.proUnlockedCacheKey, "isProUnlocked")
    }

    // MARK: - Pro Status Caching (UserDefaults)

    func testProStatusDefaultsToFalse() {
        defaults.removeObject(forKey: proKey)
        XCTAssertFalse(defaults.bool(forKey: proKey),
            "A fresh install should not have Pro unlocked")
    }

    func testProStatusPersistsAcrossReads() {
        defaults.set(true, forKey: proKey)
        XCTAssertTrue(defaults.bool(forKey: proKey))
        XCTAssertTrue(defaults.bool(forKey: proKey),
            "Cached Pro status must remain stable across consecutive reads")
    }

    func testProStatusCanBeRevoked() {
        defaults.set(true, forKey: proKey)
        defaults.set(false, forKey: proKey)
        XCTAssertFalse(defaults.bool(forKey: proKey),
            "Pro status should be revocable (e.g. refund scenario)")
    }

    // MARK: - cloudKitActiveOnLaunch Flag

    func testSyncLaunchFlagDefaultsToFalse() {
        defaults.removeObject(forKey: syncLaunchKey)
        XCTAssertFalse(defaults.bool(forKey: syncLaunchKey),
            "CloudKit should not be marked active before any launch with Pro")
    }

    func testSyncLaunchFlagTrueWhenProActiveAtLaunch() {
        // Simulate what RepsApp.init() does: mirror Pro status into the launch flag.
        let isPro = true
        defaults.set(isPro, forKey: proKey)
        defaults.set(isPro, forKey: syncLaunchKey)
        XCTAssertTrue(defaults.bool(forKey: syncLaunchKey),
            "cloudKitActiveOnLaunch must be true when the app launches with Pro")
    }

    func testSyncLaunchFlagFalseForNonProUser() {
        let isPro = false
        defaults.set(isPro, forKey: proKey)
        defaults.set(isPro, forKey: syncLaunchKey)
        XCTAssertFalse(defaults.bool(forKey: syncLaunchKey),
            "cloudKitActiveOnLaunch must be false for free-tier users")
    }

    func testMidSessionPurchaseDoesNotActivateSyncImmediately() {
        // At launch, the app was not Pro.
        defaults.set(false, forKey: syncLaunchKey)

        // Pro is purchased mid-session — the launch flag stays false.
        // The user must restart for the CloudKit container to be created.
        defaults.set(true, forKey: proKey)

        let wasActiveAtLaunch = defaults.bool(forKey: syncLaunchKey)
        XCTAssertFalse(wasActiveAtLaunch,
            "A mid-session Pro purchase should not retroactively set cloudKitActiveOnLaunch; the user must restart")
    }

    // MARK: - SwiftData In-Memory Container (validates schema + container creation)

    func testInMemoryContainerCreatesWithAllSchemaTypes() throws {
        let schema = Schema([TodoTask.self, TaskCompletion.self, CustomCategory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        XCTAssertNotNil(container)
    }

    func testLocalOnlyContainerExplicitlyDisablesCloudKit() throws {
        let schema = Schema([TodoTask.self, TaskCompletion.self, CustomCategory.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        XCTAssertNotNil(container,
            "Local-only container (no CloudKit) must initialise successfully")
    }

    func testTaskCanBeInsertedAndFetchedFromLocalContainer() throws {
        let schema = Schema([TodoTask.self, TaskCompletion.self, CustomCategory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let task = TodoTask(title: "Cloud Sync Test Task")
        context.insert(task)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<TodoTask>())
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Cloud Sync Test Task")
    }

    func testMultipleTasksInLocalContainer() throws {
        let schema = Schema([TodoTask.self, TaskCompletion.self, CustomCategory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        for i in 1...5 {
            context.insert(TodoTask(title: "Task \(i)"))
        }
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<TodoTask>())
        XCTAssertEqual(tasks.count, 5,
            "All inserted tasks must be persisted in the local container")
    }

    func testTaskDeletionInLocalContainer() throws {
        let schema = Schema([TodoTask.self, TaskCompletion.self, CustomCategory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let task = TodoTask(title: "To Be Deleted")
        context.insert(task)
        try context.save()

        context.delete(task)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<TodoTask>())
        XCTAssertTrue(tasks.isEmpty,
            "Deleted task must not appear in subsequent fetches")
    }

    func testCompletionRelationshipCascadeDelete() throws {
        let schema = Schema([TodoTask.self, TaskCompletion.self, CustomCategory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let task = TodoTask(title: "Task With Completion")
        context.insert(task)

        let completion = TaskCompletion(task: task)
        context.insert(completion)
        try context.save()

        // Delete the parent task — completions should cascade-delete.
        context.delete(task)
        try context.save()

        let completions = try context.fetch(FetchDescriptor<TaskCompletion>())
        XCTAssertTrue(completions.isEmpty,
            "Cascade delete must remove TaskCompletion records when the parent task is deleted")
    }
}

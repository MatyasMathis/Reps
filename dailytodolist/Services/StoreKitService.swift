//
//  StoreKitService.swift
//  Reps
//
//  Purpose: StoreKit 2 service for managing REPS Pro in-app purchase
//  Features: Product fetching, purchasing, restore, entitlement checking
//

import Combine
import StoreKit
import SwiftUI

/// Manages the REPS Pro lifetime in-app purchase using StoreKit 2
@MainActor
final class StoreKitService: ObservableObject {

    // MARK: - Singleton

    static let shared = StoreKitService()

    // MARK: - Published State

    @Published private(set) var isProUnlocked: Bool = false
    @Published private(set) var proProduct: Product?
    @Published private(set) var purchaseState: PurchaseState = .idle
    @Published private(set) var isLoadingProducts: Bool = true
    @Published private(set) var productLoadFailed: Bool = false

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case purchased
        case failed(String)
        case restored
    }

    // MARK: - Constants

    static let proProductID = "com.mathis.reps.pro"

    /// UserDefaults key used to cache Pro status for synchronous reads at app launch.
    /// This allows `dailytodolistApp` to decide the CloudKit configuration before
    /// StoreKit's async entitlement check completes.
    static let proUnlockedCacheKey = "isProUnlocked"

    // MARK: - Private

    private var transactionListener: Task<Void, Never>?

    // MARK: - Init

    private init() {
        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
            await updateEntitlement()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoadingProducts = true
        productLoadFailed = false
        do {
            let products = try await Product.products(for: [Self.proProductID])
            proProduct = products.first
            productLoadFailed = proProduct == nil
        } catch {
            productLoadFailed = true
        }
        isLoadingProducts = false
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product = proProduct else { return }
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isProUnlocked = true
                Self.cacheProStatus(true)
                purchaseState = .purchased

            case .userCancelled:
                purchaseState = .idle

            case .pending:
                purchaseState = .idle

            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Restore

    func restore() async {
        purchaseState = .purchasing

        do {
            try await AppStore.sync()
            await updateEntitlement(isExplicitSync: true)

            if isProUnlocked {
                purchaseState = .restored
            } else {
                purchaseState = .failed("No previous purchase found.")
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Entitlement Check

    func updateEntitlement(isExplicitSync: Bool = false) async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID,
               transaction.revocationDate == nil {
                isProUnlocked = true
                Self.cacheProStatus(true)
                return
            }
        }
        isProUnlocked = false
        // Only clear the persistent cache (both UserDefaults and iCloud KV store)
        // when the caller has first called AppStore.sync() to ensure the local
        // receipt is up to date. Passive entitlement checks on launch must not
        // erase a valid Pro status that arrived via iCloud KV from another device
        // but whose StoreKit receipt hasn't yet propagated to this device.
        if isExplicitSync {
            Self.cacheProStatus(false)
        }
    }

    /// Persists Pro status in both local UserDefaults (for synchronous launch reads)
    /// and iCloud Key-Value Store (to propagate the status to other devices automatically).
    static func cacheProStatus(_ isPro: Bool) {
        UserDefaults.standard.set(isPro, forKey: proUnlockedCacheKey)
        NSUbiquitousKeyValueStore.default.set(isPro, forKey: proUnlockedCacheKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.updateEntitlement()
                }
            }
        }
    }

    // MARK: - Reset State

    func resetPurchaseState() {
        purchaseState = .idle
    }

    // MARK: - Debug

    #if DEBUG
    /// Toggle Pro status for testing in simulator
    func debugTogglePro() {
        isProUnlocked.toggle()
    }
    #endif

    // MARK: - Verification Helper

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let item):
            return item
        }
    }
}

// MARK: - Store Error

enum StoreError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Transaction verification failed."
        }
    }
}

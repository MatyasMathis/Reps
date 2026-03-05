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
            await refreshEntitlement()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.proProductID])
            proProduct = products.first
        } catch {
            // Product loading failed — will show unavailable state in paywall
        }
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
                UserDefaults.standard.set(true, forKey: Self.proUnlockedCacheKey)
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
            await updateEntitlement()

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

    /// Silent check used at launch. Only upgrades to Pro — never downgrades.
    /// `Transaction.currentEntitlements` can return empty on TestFlight due to
    /// network latency, so we must not overwrite a cached `true` with `false` here.
    private func refreshEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID,
               transaction.revocationDate == nil {
                isProUnlocked = true
                UserDefaults.standard.set(true, forKey: Self.proUnlockedCacheKey)
                return
            }
        }
        // Do not write false here — preserve the cached value.
        // Definitive revocation is handled by listenForTransactions().
        isProUnlocked = UserDefaults.standard.bool(forKey: Self.proUnlockedCacheKey)
    }

    /// Full sync after AppStore.sync() — safe to write false because the transaction
    /// list is guaranteed to be fresh at this point.
    func updateEntitlement() async {
        var foundPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID,
               transaction.revocationDate == nil {
                foundPro = true
                break
            }
        }
        isProUnlocked = foundPro
        UserDefaults.standard.set(foundPro, forKey: Self.proUnlockedCacheKey)
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    guard transaction.productID == StoreKitService.proProductID else { continue }
                    let isActive = transaction.revocationDate == nil
                    await MainActor.run {
                        self?.isProUnlocked = isActive
                        UserDefaults.standard.set(isActive, forKey: StoreKitService.proUnlockedCacheKey)
                    }
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

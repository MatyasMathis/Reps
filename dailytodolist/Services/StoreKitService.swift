//
//  StoreKitService.swift
//  Reps
//
//  Purpose: StoreKit 2 service for managing REPS Pro in-app purchase
//  Features: Product fetching, purchasing, restore, entitlement checking
//

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
    @Published private(set) var productLoadState: ProductLoadState = .loading

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case purchased
        case failed(String)
        case restored
    }

    enum ProductLoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    // MARK: - Constants

    static let proProductID = "com.mathis.reps.pro"

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

    // MARK: - Retry Logic

    private static let maxRetries = 3
    private static let retryDelay: UInt64 = 2_000_000_000 // 2 seconds

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        productLoadState = .loading
        print("[StoreKit] Loading product: \(Self.proProductID)")

        for attempt in 1...Self.maxRetries {
            do {
                let products = try await Product.products(for: [Self.proProductID])
                print("[StoreKit] Fetched \(products.count) product(s) on attempt \(attempt)")

                if let product = products.first {
                    proProduct = product
                    productLoadState = .loaded
                    print("[StoreKit] Product loaded: \(product.displayName) — \(product.displayPrice)")
                    return
                }
            } catch {
                print("[StoreKit] Attempt \(attempt) failed: \(error.localizedDescription)")
                if attempt == Self.maxRetries {
                    productLoadState = .failed(
                        "Unable to load product. Check your connection and try again."
                    )
                    return
                }
            }

            // Wait before retrying
            try? await Task.sleep(nanoseconds: Self.retryDelay)
        }

        // All retries returned empty products
        print("[StoreKit] Product not found after \(Self.maxRetries) attempts. Ensure IAP is configured in App Store Connect with all required metadata.")
        productLoadState = .failed(
            "Product not available. Please try again later."
        )
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product = proProduct else {
            print("[StoreKit] Purchase called but proProduct is nil — product not loaded")
            purchaseState = .failed("Product not loaded. Please try again.")
            return
        }

        purchaseState = .purchasing
        print("[StoreKit] Starting purchase for \(product.id)")

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isProUnlocked = true
                purchaseState = .purchased
                print("[StoreKit] Purchase successful")

            case .userCancelled:
                purchaseState = .idle
                print("[StoreKit] Purchase cancelled by user")

            case .pending:
                purchaseState = .idle
                print("[StoreKit] Purchase pending (e.g. awaiting approval)")

            @unknown default:
                purchaseState = .idle
                print("[StoreKit] Purchase returned unknown result")
            }
        } catch {
            print("[StoreKit] Purchase error: \(error.localizedDescription)")
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Restore

    func restore() async {
        purchaseState = .purchasing
        print("[StoreKit] Restoring purchases…")

        do {
            try await AppStore.sync()
            await updateEntitlement()

            if isProUnlocked {
                purchaseState = .restored
                print("[StoreKit] Restore successful — Pro unlocked")
            } else {
                purchaseState = .failed("No previous purchase found.")
                print("[StoreKit] Restore complete — no purchase found")
            }
        } catch {
            print("[StoreKit] Restore error: \(error.localizedDescription)")
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Entitlement Check

    func updateEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID,
               transaction.revocationDate == nil {
                isProUnlocked = true
                return
            }
        }
        isProUnlocked = false
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

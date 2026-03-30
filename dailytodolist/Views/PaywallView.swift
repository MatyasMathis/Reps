//
//  PaywallView.swift
//  Reps
//
//  Purpose: Paywall screen for REPS Pro lifetime unlock
//  Design: Dark, athletic Whoop-inspired aesthetic with feature list and purchase CTA
//

import StoreKit
import SwiftUI

/// Paywall sheet presenting REPS Pro features and purchase button
struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = StoreKitService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xxl) {
                        headerSection
                        featuresSection
                        purchaseSection
                        restoreButton
                        legalNote
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.mediumGray)
                            .frame(width: 30, height: 30)
                            .background(Color.darkGray2)
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarBackground(Color.brandBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationBackground(Color.brandBlack)
        .alert("Purchase Failed", isPresented: showErrorAlert) {
            Button("OK") {
                store.resetPurchaseState()
            }
        } message: {
            if case .failed(let message) = store.purchaseState {
                Text(message)
            }
        }
    }

    // MARK: - Error Alert Binding

    private var showErrorAlert: Binding<Bool> {
        Binding(
            get: {
                if case .failed = store.purchaseState { return true }
                return false
            },
            set: { newValue in
                if !newValue { store.resetPurchaseState() }
            }
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.recoveryGreen.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Color.recoveryGreen)
            }

            Text("REPS PRO")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .tracking(3)
                .foregroundStyle(Color.pureWhite)

            Text("Unlock the full experience")
                .font(.system(size: Typography.bodySize, weight: .medium))
                .foregroundStyle(Color.mediumGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            featureRow(
                icon: "chart.bar.fill",
                title: "Detailed Statistics",
                subtitle: "Unlock trends, streaks, and completion analytics"
            )

            Divider().background(Color.darkGray2)

            featureRow(
                icon: "calendar.badge.clock",
                title: "Year in Pixels & Recurrence",
                subtitle: "Full-year heatmap plus weekly & monthly scheduling"
            )

            Divider().background(Color.darkGray2)

            featureRow(
                icon: "square.and.arrow.up",
                title: "Share Your Wins",
                subtitle: "Share completion calendars and category stats"
            )

            Divider().background(Color.darkGray2)

            featureRow(
                icon: "plus.square.on.square",
                title: "Custom Categories",
                subtitle: "Create unlimited categories with custom colors and icons"
            )

            Divider().background(Color.darkGray2)

            featureRow(
                icon: "icloud.fill",
                title: "iCloud Sync",
                subtitle: "Access your tasks on all your Apple devices"
            )

            Divider().background(Color.darkGray2)

            featureRow(
                icon: "heart.fill",
                title: "Support Development",
                subtitle: "Help keep REPS ad-free and privacy-focused"
            )
        }
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
    }

    // MARK: - Purchase

    private var purchaseSection: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                if store.productLoadFailed {
                    Task { await store.loadProducts() }
                } else {
                    Task { await store.purchase() }
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    if store.isLoadingProducts || store.purchaseState == .purchasing {
                        ProgressView()
                            .tint(Color.brandBlack)
                    } else if store.productLoadFailed {
                        Text("Tap to Retry")
                            .font(.system(size: Typography.bodySize, weight: .bold))
                    } else {
                        Text("Unlock REPS Pro")
                            .font(.system(size: Typography.bodySize, weight: .bold))

                        if let product = store.proProduct {
                            Text("— \(product.displayPrice)")
                                .font(.system(size: Typography.bodySize, weight: .bold))
                        }
                    }
                }
                .foregroundStyle(Color.brandBlack)
                .frame(maxWidth: .infinity)
                .frame(height: ComponentSize.buttonHeight)
                .background(store.productLoadFailed ? Color.mediumGray : Color.recoveryGreen)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
            }
            .disabled(store.isLoadingProducts || store.purchaseState == .purchasing)

            Text("One-time purchase. No subscription.")
                .font(.system(size: Typography.captionSize, weight: .medium))
                .foregroundStyle(Color.mediumGray)
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            Task { await store.restore() }
        } label: {
            Text("Restore Purchase")
                .font(.system(size: Typography.bodySize, weight: .medium))
                .foregroundStyle(Color.recoveryGreen)
        }
        .disabled(store.purchaseState == .purchasing)
    }

    // MARK: - Legal Note

    private var legalNote: some View {
        Text("Payment is charged to your Apple ID account at confirmation of purchase. The purchase is a one-time, non-consumable transaction.")
            .font(.system(size: Typography.captionSize, weight: .regular))
            .foregroundStyle(Color.mediumGray.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Feature Row Helper

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.recoveryGreen)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: Typography.bodySize, weight: .medium))
                    .foregroundStyle(Color.pureWhite)

                Text(subtitle)
                    .font(.system(size: Typography.captionSize, weight: .regular))
                    .foregroundStyle(Color.mediumGray)
            }

            Spacer()
        }
        .padding(Spacing.lg)
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}

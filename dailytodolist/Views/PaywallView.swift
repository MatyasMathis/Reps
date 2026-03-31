//
//  PaywallView.swift
//  Reps
//
//  Purpose: Paywall screen for REPS Pro lifetime unlock
//  Design: Full-page dark athletic experience with green hero glow
//

import StoreKit
import SwiftUI

/// Full-page paywall presenting REPS Pro features and purchase button
struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = StoreKitService.shared

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Base background
            Color.brandBlack.ignoresSafeArea()

            // Green radial glow at top
            RadialGradient(
                colors: [Color.recoveryGreen.opacity(0.22), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.0),
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()
            .frame(maxHeight: .infinity, alignment: .top)

            // Scrollable content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Room for close button
                    Spacer().frame(height: 72)

                    headerSection

                    Spacer().frame(height: Spacing.xxl)

                    featuresSection
                        .padding(.horizontal, Spacing.lg)

                    Spacer().frame(height: Spacing.xl)

                    purchaseSection
                        .padding(.horizontal, Spacing.lg)

                    restoreButton
                        .padding(.top, Spacing.md)

                    legalNote
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, 40)
                }
            }

            // Floating close button
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.mediumGray)
                    .frame(width: 36, height: 36)
                    .background(Color.darkGray1)
                    .clipShape(Circle())
            }
            .padding(.top, 56)
            .padding(.trailing, Spacing.lg)
        }
        .alert("Purchase Failed", isPresented: showErrorAlert) {
            Button("OK") { store.resetPurchaseState() }
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
        VStack(spacing: Spacing.lg) {
            // Icon with glow
            ZStack {
                Circle()
                    .fill(Color.recoveryGreen.opacity(0.25))
                    .frame(width: 130, height: 130)
                    .blur(radius: 30)

                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.recoveryGreen)
                    .frame(width: 80, height: 80)

                Image(systemName: "flame.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.brandBlack)
            }
            .padding(.bottom, Spacing.sm)

            // REPS PRO title
            HStack(spacing: 0) {
                Text("REPS ")
                    .font(.system(size: 52, weight: .black))
                    .italic()
                    .foregroundStyle(Color.pureWhite)
                Text("PRO")
                    .font(.system(size: 52, weight: .black))
                    .italic()
                    .foregroundStyle(Color.recoveryGreen)
            }

            // Subtitle
            Text("UNLOCK THE FULL EXPERIENCE")
                .font(.system(size: 12, weight: .semibold))
                .italic()
                .tracking(3.5)
                .foregroundStyle(Color.mediumGray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: Spacing.md) {
            featureCard(
                icon: "chart.bar.fill",
                iconBg: Color(hex: "0F2E1C"),
                iconColor: Color.recoveryGreen,
                title: "Detailed Statistics",
                subtitle: "TRENDS, STREAKS & ANALYTICS"
            )
            featureCard(
                icon: "calendar.fill",
                iconBg: Color(hex: "2E1E08"),
                iconColor: Color.personalOrange,
                title: "Year in Pixels",
                subtitle: "FULL-YEAR HEATMAP PLUS RECURRENCE"
            )
            featureCard(
                icon: "person.3.fill",
                iconBg: Color(hex: "081828"),
                iconColor: Color(hex: "4A8CFF"),
                title: "Share Your Wins",
                subtitle: "PREMIUM SOCIAL SHARE CARDS"
            )
            featureCard(
                icon: "square.grid.2x2.fill",
                iconBg: Color(hex: "1E0E30"),
                iconColor: Color.performancePurple,
                title: "Custom Categories",
                subtitle: "UNLIMITED CATEGORIES & ICONS"
            )
            featureCard(
                icon: "icloud.fill",
                iconBg: Color(hex: "0A2818"),
                iconColor: Color.recoveryGreen,
                title: "iCloud Sync",
                subtitle: "SYNC ON ALL YOUR DEVICES"
            )
        }
    }

    private func featureCard(
        icon: String,
        iconBg: Color,
        iconColor: Color,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(iconBg)
                    .frame(width: 54, height: 54)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: Typography.bodySize, weight: .bold))
                    .italic()
                    .foregroundStyle(Color.pureWhite)

                Text(subtitle)
                    .font(.system(size: Typography.captionSize, weight: .semibold))
                    .foregroundStyle(Color.mediumGray)
                    .tracking(0.3)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }

    // MARK: - Purchase

    private var purchaseSection: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                Task { await store.purchase() }
            } label: {
                Group {
                    if store.purchaseState == .purchasing {
                        ProgressView().tint(Color.brandBlack)
                    } else if let product = store.proProduct {
                        Text("UNLOCK PRO — \(product.displayPrice)")
                            .font(.system(size: Typography.bodySize, weight: .black))
                            .italic()
                    } else {
                        Text("UNLOCK PRO")
                            .font(.system(size: Typography.bodySize, weight: .black))
                            .italic()
                    }
                }
                .foregroundStyle(Color.brandBlack)
                .frame(maxWidth: .infinity)
                .frame(height: ComponentSize.buttonHeight)
                .background(Color.recoveryGreen)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            }
            .disabled(store.purchaseState == .purchasing || store.proProduct == nil)

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
            .foregroundStyle(Color.mediumGray.opacity(0.6))
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}

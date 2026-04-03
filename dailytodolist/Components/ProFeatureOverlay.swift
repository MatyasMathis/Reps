//
//  ProFeatureOverlay.swift
//  Reps
//
//  Purpose: Blurred "sneak peek" overlay for Pro-gated features
//  Design: Shows real content behind gaussian blur with elegant unlock CTA
//

import StoreKit
import SwiftUI
import UIKit

/// Blurred overlay that gates premium content behind REPS Pro.
///
/// Shows the user's actual data with a gaussian blur and a centered
/// unlock card, creating a "sneak peek" that drives conversion.
/// When Pro is unlocked, the content renders normally with no overlay.
struct ProFeatureOverlay<Content: View>: View {

    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    @ObservedObject private var store = StoreKitService.shared
    @State private var showPaywall = false

    var body: some View {
        if store.isProUnlocked {
            content()
        } else {
            ZStack {
                // Real content rendered blurred — the "sneak peek"
                // Fixed height keeps the card position stable across categories
                content()
                    .blur(radius: 12)
                    .allowsHitTesting(false)
                    .frame(height: 480, alignment: .top)
                    .clipped()

                // Dark scrim for readability
                Color.brandBlack.opacity(0.4)
                    .allowsHitTesting(false)

                // Unlock CTA card
                unlockCard
            }
            .frame(height: 480)
            .clipped()
        }
    }

    // MARK: - Unlock Card

    private var unlockCard: some View {
        VStack(spacing: Spacing.xl) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.recoveryGreen.opacity(0.18))
                    .frame(width: 72, height: 72)

                Image(systemName: icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.recoveryGreen)
            }

            // Title + subtitle
            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Text(title)
                        .font(.system(size: Typography.h3Size, weight: .bold))
                        .foregroundStyle(Color.pureWhite)

                    Text("PRO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.mediumGray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.darkGray2)
                        .clipShape(Capsule())
                }

                Text(subtitle)
                    .font(.system(size: Typography.bodySize, weight: .regular))
                    .foregroundStyle(Color.mediumGray)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Unlock button with price
            VStack(spacing: Spacing.sm) {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showPaywall = true
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14, weight: .bold))
                        if let product = store.proProduct {
                            Text("Unlock REPS Pro — \(product.displayPrice)")
                                .font(.system(size: Typography.bodySize, weight: .bold))
                        } else {
                            Text("Unlock REPS Pro")
                                .font(.system(size: Typography.bodySize, weight: .bold))
                        }
                    }
                    .foregroundStyle(Color.brandBlack)
                    .frame(maxWidth: .infinity)
                    .frame(height: ComponentSize.buttonHeight)
                    .background(Color.recoveryGreen)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
                }

                Text("One-time purchase. No subscription.")
                    .font(.system(size: Typography.captionSize, weight: .regular))
                    .foregroundStyle(Color.mediumGray.opacity(0.7))
            }
        }
        .padding(.vertical, Spacing.xxl)
        .padding(.horizontal, Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color.darkGray1)
        )
        .padding(.horizontal, Spacing.lg)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Preview

#Preview("Pro Feature Overlay - Locked") {
    ZStack {
        Color.brandBlack.ignoresSafeArea()

        ProFeatureOverlay(
            icon: "chart.bar.fill",
            title: "Statistics",
            subtitle: "Unlock detailed stats, trends,\nand completion analytics"
        ) {
            // Fake content to show blur effect
            VStack(spacing: Spacing.lg) {
                ForEach(0..<6) { _ in
                    RoundedRectangle(cornerRadius: CornerRadius.standard)
                        .fill(Color.darkGray1)
                        .frame(height: 80)
                }
            }
            .padding(Spacing.lg)
        }
    }
}

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
        VStack(spacing: Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.recoveryGreen.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.recoveryGreen)
            }

            // Title + subtitle
            VStack(spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Text(title)
                        .font(.system(size: Typography.h3Size, weight: .bold))
                        .foregroundStyle(Color.pureWhite)

                    ProBadge()
                }

                Text(subtitle)
                    .font(.system(size: Typography.bodySize, weight: .medium))
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
                        Text("Unlock REPS Pro")
                            .font(.system(size: Typography.bodySize, weight: .bold))
                        if let product = store.proProduct {
                            Text("— \(product.displayPrice)")
                                .font(.system(size: Typography.bodySize, weight: .bold))
                        }
                    }
                    .foregroundStyle(Color.onAccent)
                    .frame(maxWidth: 280)
                    .frame(height: ComponentSize.buttonHeight)
                    .background(Color.recoveryGreen)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
                }

                Text("One-time purchase. No subscription.")
                    .font(.system(size: Typography.captionSize, weight: .medium))
                    .foregroundStyle(Color.mediumGray)
            }
        }
        .padding(.vertical, Spacing.xxl)
        .padding(.horizontal, Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .strokeBorder(Color.recoveryGreen.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, Spacing.xl)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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

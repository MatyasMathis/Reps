//
//  SplashView.swift
//  Reps
//
//  Purpose: Launch screen with animated logo
//  Design: Athletic, premium aesthetic matching app branding
//

import SwiftUI
import UIKit

/// Animated splash screen shown on app launch
struct SplashView: View {

    // MARK: - State

    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    // MARK: - Body

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0"
        return "VERSION \(version) • PROFESSIONAL EDITION"
    }

    var body: some View {
        ZStack {
            // Background with subtle green radial glow
            Color.brandBlack
                .ignoresSafeArea()

            // Subtle teal-green radial gradient from center
            RadialGradient(
                colors: [
                    Color(hex: "0D2B22").opacity(0.9),
                    Color.brandBlack
                ],
                center: .center,
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()
            .opacity(glowOpacity)

            VStack(spacing: 0) {
                Spacer()

                // REPS + tagline
                VStack(spacing: 12) {
                    Text("REPS")
                        .font(.system(size: 64, weight: .black))
                        .italic()
                        .foregroundStyle(Color.pureWhite)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    Text("LOCK IN.")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(Color.pureWhite.opacity(0.4))
                        .opacity(textOpacity)
                }

                Spacer()

                // Version footer
                Text(appVersion)
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(Color.pureWhite.opacity(0.25))
                    .padding(.bottom, 48)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            animateSplash()
        }
    }

    // MARK: - Animation

    private func animateSplash() {
        // Logo entrance
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
            glowOpacity = 1.0
        }

        // Text fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            textOpacity = 1.0
        }

        // Subtle haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
}

// MARK: - Preview

#Preview("Splash Screen") {
    SplashView()
}

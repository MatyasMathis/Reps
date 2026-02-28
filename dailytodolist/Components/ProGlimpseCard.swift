//
//  ProGlimpseCard.swift
//  Reps
//
//  Purpose: Non-intrusive pro feature sneak peek shown at key engagement moments
//  Design: Bottom overlay card — dismissable, feature-specific, never pushy
//

import SwiftUI

// MARK: - Variant

/// The context that triggered the nudge, driving copy and preview content.
enum ProGlimpseVariant {
    /// Shown after the user completes every task for the day.
    case allTasksDone
    /// Shown when the user hits a streak milestone (e.g. 7, 14, 30 days).
    case streakMilestone(Int)
    /// Shown the first time the user navigates to the History tab.
    case historyTab
}

// MARK: - Card View

/// A slim overlay card that slides up from the bottom of the screen and teases
/// one specific Pro feature. Tapping "Unlock" opens the paywall; the dismiss X
/// registers a dismissal with `ProNudgeService`.
struct ProGlimpseCard: View {

    let variant: ProGlimpseVariant
    let onUnlock: () -> Void
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            headerRow
            featurePreview
            unlockButton
        }
        .padding(Spacing.lg)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .strokeBorder(Color.recoveryGreen.opacity(0.3), lineWidth: 1)
        )
        .shadowLevel3()
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.recoveryGreen)

                    Text(headline)
                        .font(.system(size: Typography.h4Size, weight: .bold))
                        .foregroundStyle(Color.pureWhite)
                }

                Text(subheadline)
                    .font(.system(size: Typography.captionSize, weight: .medium))
                    .foregroundStyle(Color.mediumGray)
            }

            Spacer()

            Button {
                ProNudgeService.shared.markDismissed()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.mediumGray)
                    .frame(width: 26, height: 26)
                    .background(Color.darkGray2)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Feature Preview

    private var featurePreview: some View {
        ZStack {
            previewContent
                .blur(radius: 2)

            // "Locked" label over the blurred preview
            HStack(spacing: Spacing.xs) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text("Pro")
                    .font(.system(size: Typography.captionSize, weight: .bold))
            }
            .foregroundStyle(Color.recoveryGreen)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 4)
            .background(Color.brandBlack.opacity(0.7))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(Color.darkGray2)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.standard)
                .strokeBorder(Color.recoveryGreen.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Variant-Specific Preview Content

    @ViewBuilder
    private var previewContent: some View {
        switch variant {
        case .allTasksDone:
            barChartPreview
        case .streakMilestone(let n):
            pixelGridPreview(filledCount: min(n, 30))
        case .historyTab:
            lineChartPreview
        }
    }

    /// Mock bar chart — teases the Statistics view
    private var barChartPreview: some View {
        let heights: [CGFloat] = [30, 50, 38, 58, 44, 54, 46]
        return HStack(alignment: .bottom, spacing: 5) {
            ForEach(Array(heights.enumerated()), id: \.offset) { _, h in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.recoveryGreen.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .frame(height: h)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    /// Mini pixel grid — teases the Year in Pixels view
    private func pixelGridPreview(filledCount: Int) -> some View {
        let total = 35
        let columns = 7
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: columns),
            spacing: 4
        ) {
            ForEach(0..<total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < filledCount ? Color.recoveryGreen : Color.darkGray2.opacity(0.8))
                    .frame(height: 12)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    /// Mock line chart — teases the History/Stats analytics view
    private var lineChartPreview: some View {
        let points: [CGFloat] = [0.25, 0.5, 0.38, 0.65, 0.55, 0.82, 0.70]
        return GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let step = w / CGFloat(points.count - 1)

            Path { path in
                for (i, point) in points.enumerated() {
                    let x = CGFloat(i) * step
                    let y = h - (point * h * 0.75) - h * 0.12
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                Color.recoveryGreen,
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Unlock Button

    private var unlockButton: some View {
        Button {
            ProNudgeService.shared.markShown()
            onUnlock()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("Unlock REPS Pro")
                    .font(.system(size: Typography.bodySize, weight: .bold))
            }
            .foregroundStyle(Color.brandBlack)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.recoveryGreen)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        }
    }

    // MARK: - Copy

    private var iconName: String {
        switch variant {
        case .allTasksDone:      return "chart.bar.fill"
        case .streakMilestone:   return "flame.fill"
        case .historyTab:        return "chart.xyaxis.line"
        }
    }

    private var headline: String {
        switch variant {
        case .allTasksDone:               return "Day complete."
        case .streakMilestone(let n):     return "\(n) days locked in."
        case .historyTab:                 return "There's more to your story."
        }
    }

    private var subheadline: String {
        switch variant {
        case .allTasksDone:    return "See your trends with REPS Pro."
        case .streakMilestone: return "Your year is taking shape — unlock it."
        case .historyTab:      return "Full analytics waiting with Pro."
        }
    }
}

// MARK: - Preview

#Preview("All Tasks Done") {
    ZStack {
        Color.brandBlack.ignoresSafeArea()
        VStack {
            Spacer()
            ProGlimpseCard(variant: .allTasksDone, onUnlock: {}, onDismiss: {})
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 120)
        }
    }
}

#Preview("Streak Milestone") {
    ZStack {
        Color.brandBlack.ignoresSafeArea()
        VStack {
            Spacer()
            ProGlimpseCard(variant: .streakMilestone(7), onUnlock: {}, onDismiss: {})
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 120)
        }
    }
}

#Preview("History Tab") {
    ZStack {
        Color.brandBlack.ignoresSafeArea()
        VStack {
            Spacer()
            ProGlimpseCard(variant: .historyTab, onUnlock: {}, onDismiss: {})
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 120)
        }
    }
}

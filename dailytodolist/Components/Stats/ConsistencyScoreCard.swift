//
//  ConsistencyScoreCard.swift
//  Reps
//
//  Purpose: Whoop-style single-number consistency score (0–100) combining
//           completion rate, streak momentum, and recent trend.
//  Design:  Arc gauge with large number, color-coded tier label.
//

import SwiftUI

/// Computes and displays a 0–100 consistency score for the selected category.
///
/// Score formula (all components clamped to 0–100):
///   - 50% completion rate (recurring tasks only; 100 if no recurring tasks)
///   - 30% streak momentum: min(streak / 21, 1) × 100
///   - 20% trend signal:   thisMonth >= lastMonth ? 100 : max(0, 100 − drop%)
struct ConsistencyScoreCard: View {

    // MARK: - Properties

    let score: Int          // 0–100
    let accentColor: Color

    // MARK: - Computed

    private var tier: (label: String, color: Color) {
        switch score {
        case 85...: return ("ON FIRE",     .recoveryGreen)
        case 70...: return ("CONSISTENT",  .recoveryGreen)
        case 50...: return ("BUILDING",    .personalOrange)
        case 30...: return ("INCONSISTENT",.personalOrange)
        default:    return ("NEEDS FOCUS", .strainRed)
        }
    }

    private var scoreColor: Color { tier.color }

    // Arc goes from -210° to 30° (240° sweep), starts bottom-left, ends bottom-right
    private let startAngle: Double = -210
    private let totalSweep: Double = 240

    private var fillSweep: Double { totalSweep * Double(min(max(score, 0), 100)) / 100 }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("CONSISTENCY SCORE")
                .font(.system(size: Typography.captionSize, weight: .bold))
                .foregroundStyle(Color.mediumGray)
                .tracking(1.0)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                // Background arc
                Arc(startAngle: .degrees(startAngle), endAngle: .degrees(startAngle + totalSweep))
                    .stroke(Color.darkGray2, style: StrokeStyle(lineWidth: 10, lineCap: .round))

                // Filled arc
                Arc(startAngle: .degrees(startAngle), endAngle: .degrees(startAngle + fillSweep))
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .animation(.spring(response: 0.8, dampingFraction: 0.75), value: score)

                // Center content
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.6), value: score)

                    Text(tier.label)
                        .font(.system(size: Typography.captionSize, weight: .bold))
                        .foregroundStyle(scoreColor)
                        .tracking(0.8)
                }
            }
            .frame(height: 160)
            .padding(.horizontal, Spacing.xxl)
        }
        .padding(Spacing.lg)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }
}

// MARK: - Arc Shape

private struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set {
            startAngle = .degrees(newValue.first)
            endAngle   = .degrees(newValue.second)
        }
    }
}

// MARK: - Score Computation Helper

extension ConsistencyScoreCard {

    /// Computes the consistency score from raw stats.
    ///
    /// - Parameters:
    ///   - completionRate: 0–100 integer rate from recurring tasks (nil if no recurring tasks)
    ///   - currentStreak: current consecutive-day streak
    ///   - thisMonthCount: completions in the current calendar month
    ///   - lastMonthCount: completions in the previous calendar month
    static func compute(
        completionRate: Int?,
        currentStreak: Int,
        thisMonthCount: Int,
        lastMonthCount: Int
    ) -> Int {
        // 50% — completion rate (default 100 if no recurring tasks)
        let rateComponent = Double(completionRate ?? 100)

        // 30% — streak momentum (caps at 21-day streak = full score)
        let streakComponent = min(Double(currentStreak) / 21.0, 1.0) * 100

        // 20% — trend signal
        let trendComponent: Double
        if lastMonthCount == 0 {
            trendComponent = thisMonthCount > 0 ? 100 : 50
        } else {
            let change = Double(thisMonthCount - lastMonthCount) / Double(lastMonthCount)
            // +20% change → 100, 0% → 70, -50% change → 20
            trendComponent = min(max(70 + change * 150, 0), 100)
        }

        let raw = 0.50 * rateComponent + 0.30 * streakComponent + 0.20 * trendComponent
        return min(max(Int(raw.rounded()), 0), 100)
    }
}

// MARK: - Preview

#Preview("Consistency Score Card") {
    ZStack {
        Color.brandBlack.ignoresSafeArea()
        VStack(spacing: Spacing.xl) {
            ConsistencyScoreCard(score: 91, accentColor: .recoveryGreen)
            ConsistencyScoreCard(score: 62, accentColor: .personalOrange)
            ConsistencyScoreCard(score: 24, accentColor: .strainRed)
        }
        .padding(Spacing.lg)
    }
}

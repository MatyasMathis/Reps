//
//  ConsistencyScoreCard.swift
//  Reps
//
//  Purpose: Whoop-style arc gauge showing a 0–100 consistency score
//  Design: Animated arc fill, color-coded tiers, single-number health score
//

import SwiftUI

/// Whoop-inspired arc gauge displaying a 0–100 consistency score.
///
/// Formula:
///   50% × completion rate (or 30-day activity ratio if no recurring tasks)
///   30% × streak momentum (currentStreak / bestStreak)
///   20% × monthly trend (this month vs last month ratio)
struct ConsistencyScoreCard: View {

    // MARK: - Properties

    let completionRate: Int?
    let currentStreak: Int
    let bestStreak: Int
    let completions: [Date]
    var accentColor: Color = .recoveryGreen

    // MARK: - State

    @State private var animatedScore: Double = 0

    // MARK: - Score

    private var score: Int {
        var s = 0.0

        // 50% — completion rate
        if let rate = completionRate {
            s += 0.5 * Double(rate)
        } else {
            // No recurring tasks: use activity ratio over last 30 days
            let cal = Calendar.current
            let now = Date()
            if let cutoff = cal.date(byAdding: .day, value: -30, to: now) {
                let recentDays = Set(completions.filter { $0 >= cutoff }.map { cal.startOfDay(for: $0) }).count
                s += 0.5 * min(Double(recentDays) / 30.0 * 100, 100)
            }
        }

        // 30% — streak momentum
        if bestStreak > 0 {
            s += 0.3 * min(Double(currentStreak) / Double(bestStreak), 1.0) * 100
        }

        // 20% — monthly trend
        s += 0.2 * monthlyTrendScore * 100

        return min(Int(s.rounded()), 100)
    }

    private var monthlyTrendScore: Double {
        let cal = Calendar.current
        let now = Date()
        guard let thisMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)),
              let lastMonthStart = cal.date(byAdding: .month, value: -1, to: thisMonthStart) else { return 0.5 }

        let thisCount = Set(completions.compactMap { c -> Date? in
            let d = cal.startOfDay(for: c)
            return d >= thisMonthStart ? d : nil
        }).count

        let lastCount = Set(completions.compactMap { c -> Date? in
            let d = cal.startOfDay(for: c)
            return d >= lastMonthStart && d < thisMonthStart ? d : nil
        }).count

        if lastCount == 0 { return thisCount > 0 ? 0.8 : 0.5 }
        return min(Double(thisCount) / Double(lastCount), 2.0) / 2.0
    }

    // MARK: - Tiers

    private struct Tier {
        let label: String
        let color: Color
    }

    private func tier(for value: Int) -> Tier {
        switch value {
        case 0..<26: return Tier(label: "Needs Focus",     color: .strainRed)
        case 26..<51: return Tier(label: "Building Habits", color: .personalOrange)
        case 51..<76: return Tier(label: "In the Zone",     color: Color(hex: "FFB800"))
        default:       return Tier(label: "On Fire",         color: .recoveryGreen)
        }
    }

    private var finalTier: Tier { tier(for: score) }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("CONSISTENCY SCORE")
                .font(.system(size: Typography.captionSize, weight: .black))
                .italic()
                .foregroundStyle(Color.mediumGray)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                // Background track (270° arc)
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.darkGray2, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(135))

                // Filled arc
                Circle()
                    .trim(from: 0, to: animatedScore / 100.0 * 0.75)
                    .stroke(finalTier.color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(135))
                    .animation(.spring(response: 1.2, dampingFraction: 0.75), value: animatedScore)

                // Center: number + tier label
                VStack(spacing: 4) {
                    Text("\(Int(animatedScore))")
                        .font(.system(size: 52, weight: .black))
                        .italic()
                        .monospacedDigit()
                        .foregroundStyle(finalTier.color)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 1.2, dampingFraction: 0.75), value: animatedScore)

                    Text(finalTier.label.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(finalTier.color.opacity(0.7))
                        .tracking(0.8)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 170, height: 170)
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.lg)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animatedScore = Double(score)
            }
        }
        .onChange(of: score) { _, newVal in
            withAnimation { animatedScore = Double(newVal) }
        }
    }
}

// MARK: - Preview

#Preview("Consistency Score Card") {
    let cal = Calendar.current
    var dates: [Date] = []
    for daysAgo in [0, 1, 2, 3, 5, 8, 10, 12, 15, 18, 20] {
        if let d = cal.date(byAdding: .day, value: -daysAgo, to: Date()),
           let t = cal.date(bySettingHour: 9, minute: 30, second: 0, of: d) {
            dates.append(t)
        }
    }
    return ZStack {
        Color.brandBlack.ignoresSafeArea()
        ConsistencyScoreCard(
            completionRate: 78,
            currentStreak: 4,
            bestStreak: 12,
            completions: dates
        )
        .padding(Spacing.lg)
    }
}

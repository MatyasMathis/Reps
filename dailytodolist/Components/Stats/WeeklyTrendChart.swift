//
//  WeeklyTrendChart.swift
//  Reps
//
//  Purpose: Rolling 8-week completion trend — shows trajectory, not just a snapshot.
//  Design:  Bar chart (most-recent week on the right), trend line overlay,
//           week labels, and a concise growth/decline badge.
//

import SwiftUI

/// Bar chart of completions per week for the last 8 weeks.
///
/// The rightmost bar is always the current (incomplete) week.
/// Week starts on Monday (ISO calendar).
struct WeeklyTrendChart: View {

    // MARK: - Properties

    let completions: [Date]
    var accentColor: Color = .recoveryGreen

    // MARK: - Constants

    private let weekCount = 8
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.locale = Locale.current
        return cal
    }()

    // MARK: - Computed

    /// Count of completions per week, index 0 = oldest, index 7 = current week
    private var weeklyCounts: [Int] {
        let now = Date()
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return Array(repeating: 0, count: weekCount)
        }

        var counts = [Int](repeating: 0, count: weekCount)

        for date in completions {
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { continue }
            let weeksAgo = calendar.dateComponents([.weekOfYear], from: weekStart, to: currentWeekStart).weekOfYear ?? 0
            let index = weekCount - 1 - weeksAgo
            if index >= 0 && index < weekCount {
                counts[index] += 1
            }
        }

        return counts
    }

    private var maxCount: Int { max(weeklyCounts.max() ?? 1, 1) }

    /// Short week label: "W8" … "W1" then "NOW"
    private var weekLabels: [String] {
        (0..<weekCount).map { i in
            i == weekCount - 1 ? "NOW" : "W\(weekCount - 1 - i)"
        }
    }

    /// +/- change from 7-week average to current week
    private var trendSummary: (value: Int, isUp: Bool)? {
        let prior = Array(weeklyCounts.dropLast())
        let priorTotal = prior.reduce(0, +)
        guard priorTotal > 0 else { return nil }
        let avg = Double(priorTotal) / Double(prior.count)
        let current = Double(weeklyCounts.last ?? 0)
        let pct = Int(((current - avg) / avg * 100).rounded())
        return (value: abs(pct), isUp: pct >= 0)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("8-WEEK TREND")
                    .font(.system(size: Typography.captionSize, weight: .bold))
                    .foregroundStyle(Color.mediumGray)
                    .tracking(1.0)

                Spacer()

                // Trend badge
                if let trend = trendSummary {
                    HStack(spacing: 3) {
                        Image(systemName: trend.isUp ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(trend.value)% vs avg")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(trend.isUp ? Color.recoveryGreen : Color.strainRed)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background((trend.isUp ? Color.recoveryGreen : Color.strainRed).opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(weeklyCounts.enumerated()), id: \.offset) { i, count in
                    let isCurrent = i == weekCount - 1
                    VStack(spacing: Spacing.xs) {
                        // Count above bar
                        Text(count > 0 ? "\(count)" : "")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(isCurrent ? accentColor : Color.mediumGray)
                            .frame(height: 12)

                        // Bar
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                isCurrent
                                    ? accentColor
                                    : accentColor.opacity(barOpacity(for: i))
                            )
                            .frame(height: barHeight(for: i))
                            .overlay(
                                // Current week gets a subtle glow border
                                isCurrent
                                ? RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(accentColor.opacity(0.4), lineWidth: 1)
                                : nil
                            )

                        // Week label
                        Text(weekLabels[i])
                            .font(.system(size: 9, weight: isCurrent ? .bold : .medium))
                            .foregroundStyle(isCurrent ? accentColor : Color.mediumGray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90)
        }
        .padding(Spacing.lg)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }

    // MARK: - Helpers

    private func barHeight(for index: Int) -> CGFloat {
        guard maxCount > 0 else { return 8 }
        let ratio = CGFloat(weeklyCounts[index]) / CGFloat(maxCount)
        return max(ratio * 60, 8)
    }

    private func barOpacity(for index: Int) -> Double {
        // Older weeks fade out slightly to emphasise recency
        let recencyFactor = Double(index) / Double(weekCount - 1)  // 0 = oldest, 1 = newest
        let countFactor = maxCount > 0 ? Double(weeklyCounts[index]) / Double(maxCount) : 0.1
        return max(countFactor * 0.6 + recencyFactor * 0.2, 0.15)
    }
}

// MARK: - Preview

#Preview("Weekly Trend Chart") {
    let calendar = Calendar(identifier: .iso8601)
    var dates: [Date] = []

    // Simulate improving trend over 8 weeks
    for weekOffset in 0..<8 {
        let completionsThisWeek = 3 + weekOffset  // grows each week
        for day in 0..<min(completionsThisWeek, 7) {
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start,
               let weekAgoStart = calendar.date(byAdding: .weekOfYear, value: -(7 - weekOffset), to: weekStart),
               let date = calendar.date(byAdding: .day, value: day, to: weekAgoStart) {
                dates.append(date)
            }
        }
    }

    return ZStack {
        Color.brandBlack.ignoresSafeArea()
        WeeklyTrendChart(completions: dates)
            .padding(Spacing.lg)
    }
}

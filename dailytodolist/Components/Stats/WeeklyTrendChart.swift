//
//  WeeklyTrendChart.swift
//  Reps
//
//  Purpose: Rolling 8-week bar chart with current week highlighted and vs-avg badge
//  Design: Recency-weighted opacity, bright current week, "+12% vs avg" pill
//

import SwiftUI

/// 8-week rolling bar chart. Current week is fully opaque and highlighted;
/// older bars fade with recency weighting to communicate trajectory at a glance.
struct WeeklyTrendChart: View {

    // MARK: - Properties

    let completions: [Date]
    var accentColor: Color = .recoveryGreen

    // MARK: - Data Model

    private struct WeekBar {
        let label: String
        let count: Int
        let isCurrentWeek: Bool
    }

    // MARK: - Computed

    private let calendar = Calendar.current

    private var bars: [WeekBar] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7

        guard let currentWeekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        var result: [WeekBar] = []

        // 7 past weeks + current week = 8 bars
        for weeksBack in stride(from: 7, through: 0, by: -1) {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: currentWeekStart),
                  let weekEnd   = calendar.date(byAdding: .day, value: 7, to: weekStart) else { continue }

            let count = completions.filter {
                let d = calendar.startOfDay(for: $0)
                return d >= weekStart && d < weekEnd
            }.count

            let isCurrentWeek = weeksBack == 0
            let label = isCurrentWeek ? "Now" : formatter.string(from: weekStart)
            result.append(WeekBar(label: label, count: count, isCurrentWeek: isCurrentWeek))
        }

        return result
    }

    private var maxCount: Int { bars.map(\.count).max() ?? 1 }

    /// Average of the 7 past weeks (excludes current week)
    private var sevenWeekAverage: Double {
        let past = bars.dropLast()
        let total = past.map(\.count).reduce(0, +)
        guard !past.isEmpty else { return 0 }
        return Double(total) / Double(past.count)
    }

    private var currentWeekCount: Int { bars.last?.count ?? 0 }

    /// Percent vs 7-week average (nil if average is zero)
    private var vsAvgPercent: Int? {
        guard sevenWeekAverage > 0 else { return nil }
        let pct = (Double(currentWeekCount) - sevenWeekAverage) / sevenWeekAverage * 100
        return Int(pct.rounded())
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header row
            HStack(alignment: .center) {
                Text("8-WEEK TREND")
                    .font(.system(size: Typography.captionSize, weight: .black))
                    .italic()
                    .foregroundStyle(Color.mediumGray)
                    .tracking(1.2)

                Spacer()

                if let pct = vsAvgPercent {
                    Text("\(pct >= 0 ? "+" : "")\(pct)% vs avg")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(pct >= 0 ? Color.recoveryGreen : Color.strainRed)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background((pct >= 0 ? Color.recoveryGreen : Color.strainRed).opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            // Bars
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(bars.enumerated()), id: \.offset) { index, bar in
                    VStack(spacing: Spacing.xs) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(bar.isCurrentWeek
                                  ? accentColor
                                  : accentColor.opacity(recencyOpacity(index: index)))
                            .frame(height: barHeight(count: bar.count))

                        Text(bar.label)
                            .font(.system(size: 8, weight: bar.isCurrentWeek ? .bold : .medium))
                            .foregroundStyle(bar.isCurrentWeek ? accentColor : Color.mediumGray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80)
        }
        .padding(Spacing.lg)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }

    // MARK: - Helpers

    private func barHeight(count: Int) -> CGFloat {
        guard maxCount > 0 else { return 6 }
        let ratio = CGFloat(count) / CGFloat(maxCount)
        return max(ratio * 60, count > 0 ? 8 : 4)
    }

    /// Recency-weighted opacity: oldest bar ≈ 0.15, last past bar ≈ 0.65, current = 1.0
    private func recencyOpacity(index: Int) -> Double {
        let pastCount = bars.count - 1 // exclude current week
        guard pastCount > 1 else { return 0.4 }
        let position = Double(index) / Double(pastCount - 1) // 0.0 … 1.0
        return 0.15 + position * 0.5
    }
}

// MARK: - Preview

#Preview("Weekly Trend Chart") {
    let cal = Calendar.current
    var dates: [Date] = []
    // Simulate improving trend: fewer completions in older weeks, more recent
    let pattern = [2, 3, 2, 4, 5, 4, 6, 7] // 8 weeks, oldest first
    for (weekOffset, count) in pattern.enumerated() {
        let weeksBack = 7 - weekOffset
        for day in 0..<count {
            if let w = cal.date(byAdding: .weekOfYear, value: -weeksBack, to: Date()),
               let d = cal.date(byAdding: .day, value: day, to: w) {
                dates.append(d)
            }
        }
    }
    return ZStack {
        Color.brandBlack.ignoresSafeArea()
        WeeklyTrendChart(completions: dates)
            .padding(Spacing.lg)
    }
}

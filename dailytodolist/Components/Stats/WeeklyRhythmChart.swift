//
//  WeeklyRhythmChart.swift
//  Reps
//
//  Purpose: 7-bar chart showing average completions per day of the week
//  Design: Minimal bars with day labels, fits the dark Whoop aesthetic
//

import SwiftUI

/// Shows which days of the week the user is most active
struct WeeklyRhythmChart: View {

    // MARK: - Properties

    /// Completion dates to analyze
    let completions: [Date]

    /// Accent color for the bars (defaults to recovery green)
    var accentColor: Color = .recoveryGreen

    // MARK: - Computed Properties

    private let calendar = Calendar.current
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    /// Counts per weekday (Monday=0, Sunday=6)
    private var weekdayCounts: [Int] {
        var counts = Array(repeating: 0, count: 7)

        for date in completions {
            let weekday = calendar.component(.weekday, from: date)
            // Convert: 1=Sun -> index 6, 2=Mon -> index 0, etc.
            let index = (weekday + 5) % 7
            counts[index] += 1
        }

        return counts
    }

    private var maxCount: Int {
        weekdayCounts.max() ?? 1
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Section label
            Text("WEEKLY RHYTHM")
                .font(.system(size: Typography.captionSize, weight: .black))
                .italic()
                .foregroundStyle(Color.mediumGray)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Bars
            HStack(alignment: .bottom, spacing: Spacing.sm) {
                ForEach(Array(dayLabels.enumerated()), id: \.offset) { index, label in
                    VStack(spacing: Spacing.xs) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(weekdayCounts[index] > 0 ? accentColor.opacity(barOpacity(for: index)) : Color.darkGray2)
                            .frame(height: barHeight(for: index))

                        // Day label
                        Text(label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(weekdayCounts[index] == maxCount && maxCount > 0 ? accentColor : Color.mediumGray)
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

    private func barHeight(for index: Int) -> CGFloat {
        guard maxCount > 0 else { return 8 }
        let ratio = CGFloat(weekdayCounts[index]) / CGFloat(maxCount)
        return max(ratio * 60, 8) // Minimum height of 8
    }

    private func barOpacity(for index: Int) -> Double {
        guard maxCount > 0 else { return 0.2 }
        let ratio = Double(weekdayCounts[index]) / Double(maxCount)
        return max(ratio, 0.3)
    }
}

// MARK: - Preview

#Preview("Weekly Rhythm Chart") {
    let calendar = Calendar.current
    var dates: [Date] = []

    // Simulate heavier Mon/Wed/Fri pattern
    for weeksAgo in 0..<8 {
        for dayOffset in [0, 2, 4] { // Mon, Wed, Fri
            if let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: Date()),
               let date = calendar.date(byAdding: .day, value: dayOffset - (calendar.component(.weekday, from: weekStart) + 5) % 7, to: weekStart) {
                dates.append(date)
            }
        }
    }

    return ZStack {
        Color.brandBlack.ignoresSafeArea()
        WeeklyRhythmChart(completions: dates)
            .padding(Spacing.lg)
    }
}

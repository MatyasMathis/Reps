//
//  PersonalRecordsCard.swift
//  Reps
//
//  Purpose: 2×2 grid of personal bests — Best Day, Best Week, Active Days, Avg/Week
//  Design: Milestone recognition card matching StatGridCard typography
//

import SwiftUI

/// 2×2 grid of personal milestone stats.
///
/// Milestone recognition is the #1 retention mechanic — seeing "Best Week: 12 reps"
/// creates an immediate desire to beat it.
struct PersonalRecordsCard: View {

    // MARK: - Properties

    let completions: [Date]
    var accentColor: Color = .recoveryGreen

    // MARK: - Computed

    private let calendar = Calendar.current

    private var bestDay: Int {
        var counts: [Date: Int] = [:]
        for d in completions {
            counts[calendar.startOfDay(for: d), default: 0] += 1
        }
        return counts.values.max() ?? 0
    }

    private var bestWeek: Int {
        var counts: [Date: Int] = [:]
        for d in completions {
            guard let weekStart = mondayOf(date: d) else { continue }
            counts[weekStart, default: 0] += 1
        }
        return counts.values.max() ?? 0
    }

    private var activeDays: Int {
        Set(completions.map { calendar.startOfDay(for: $0) }).count
    }

    private var avgPerWeek: Double {
        guard !completions.isEmpty else { return 0 }
        let sorted = completions.map { calendar.startOfDay(for: $0) }.sorted()
        guard let first = sorted.first else { return 0 }
        let today = calendar.startOfDay(for: Date())
        let days = max((calendar.dateComponents([.day], from: first, to: today).day ?? 0) + 1, 1)
        let weeks = max(Double(days) / 7.0, 1.0)
        return Double(completions.count) / weeks
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("PERSONAL RECORDS")
                .font(.system(size: Typography.captionSize, weight: .black))
                .italic()
                .foregroundStyle(Color.mediumGray)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: Spacing.sm), GridItem(.flexible(), spacing: Spacing.sm)],
                spacing: Spacing.sm
            ) {
                recordCell(
                    label: "BEST DAY",
                    value: "\(bestDay)",
                    icon: "trophy.fill",
                    color: Color.performancePurple
                )
                recordCell(
                    label: "BEST WEEK",
                    value: "\(bestWeek)",
                    icon: "flame.fill",
                    color: Color.performancePurple
                )
                recordCell(
                    label: "ACTIVE DAYS",
                    value: "\(activeDays)",
                    icon: "calendar",
                    color: accentColor
                )
                recordCell(
                    label: "AVG / WEEK",
                    value: String(format: avgPerWeek >= 10 ? "%.0f" : "%.1f", avgPerWeek),
                    icon: "chart.line.uptrend.xyaxis",
                    color: accentColor
                )
            }
        }
        .padding(Spacing.lg)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }

    // MARK: - Cell

    private func recordCell(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color.opacity(0.7))
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.mediumGray)
                    .tracking(0.6)
            }

            Text(value)
                .font(.system(size: 40, weight: .black))
                .italic()
                .monospacedDigit()
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.brandBlack.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
    }

    // MARK: - Helpers

    private func mondayOf(date: Date) -> Date? {
        let weekday = calendar.component(.weekday, from: date)
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: date))
    }
}

// MARK: - Preview

#Preview("Personal Records Card") {
    let cal = Calendar.current
    var dates: [Date] = []
    for daysAgo in [0, 0, 1, 2, 2, 3, 5, 5, 5, 8, 10, 12, 14, 15, 18, 20, 21, 21, 25, 28] {
        if let d = cal.date(byAdding: .day, value: -daysAgo, to: Date()),
           let t = cal.date(bySettingHour: 9, minute: 30, second: 0, of: d) {
            dates.append(t)
        }
    }
    return ZStack {
        Color.brandBlack.ignoresSafeArea()
        PersonalRecordsCard(completions: dates)
            .padding(Spacing.lg)
    }
}

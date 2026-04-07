//
//  PeakHoursChart.swift
//  Reps
//
//  Purpose: 4-block bar chart showing which part of the day the user is most active
//  Design: Morning / Afternoon / Evening / Night blocks with insight blurb
//

import SwiftUI

/// Bar chart bucketing completions into Morning / Afternoon / Evening / Night.
///
/// Uses the full `completedAt` timestamps already stored on TaskCompletion —
/// no model changes required.
struct PeakHoursChart: View {

    // MARK: - Properties

    /// Full completion timestamps (not start-of-day)
    let completions: [Date]
    var accentColor: Color = .recoveryGreen

    // MARK: - Period Definition

    private enum Period: String, CaseIterable {
        case morning   = "Morning"
        case afternoon = "Afternoon"
        case evening   = "Evening"
        case night     = "Night"

        var icon: String {
            switch self {
            case .morning:   "sunrise.fill"
            case .afternoon: "sun.max.fill"
            case .evening:   "sunset.fill"
            case .night:     "moon.stars.fill"
            }
        }

        var shortLabel: String {
            switch self {
            case .morning:   "MORN"
            case .afternoon: "AFT"
            case .evening:   "EVE"
            case .night:     "NIGHT"
            }
        }

        /// Hour range (24h). Night wraps: 21+ and 0-4.
        func contains(hour: Int) -> Bool {
            switch self {
            case .morning:   return (5..<12).contains(hour)
            case .afternoon: return (12..<17).contains(hour)
            case .evening:   return (17..<21).contains(hour)
            case .night:     return hour >= 21 || hour < 5
            }
        }
    }

    // MARK: - Computed

    private let calendar = Calendar.current

    private var counts: [Period: Int] {
        var result: [Period: Int] = [:]
        Period.allCases.forEach { result[$0] = 0 }
        for date in completions {
            let hour = calendar.component(.hour, from: date)
            for period in Period.allCases where period.contains(hour: hour) {
                result[period, default: 0] += 1
            }
        }
        return result
    }

    private var maxCount: Int { counts.values.max() ?? 1 }

    private var peakPeriod: Period? {
        guard let (period, count) = counts.max(by: { $0.value < $1.value }), count > 0 else { return nil }
        return period
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("PEAK HOURS")
                .font(.system(size: Typography.captionSize, weight: .black))
                .italic()
                .foregroundStyle(Color.mediumGray)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .bottom, spacing: Spacing.sm) {
                ForEach(Period.allCases, id: \.self) { period in
                    let count = counts[period] ?? 0
                    let isPeak = period == peakPeriod

                    VStack(spacing: Spacing.xs) {
                        // Count above bar
                        Text("\(count)")
                            .font(.system(size: 12, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(isPeak ? accentColor : Color.mediumGray)

                        // Bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isPeak ? accentColor : (count > 0 ? accentColor.opacity(0.3) : Color.darkGray2))
                            .frame(height: barHeight(for: period))

                        // Period icon
                        Image(systemName: period.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isPeak ? accentColor : Color.mediumGray)

                        // Period label
                        Text(period.shortLabel)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(isPeak ? accentColor : Color.mediumGray)
                            .tracking(0.4)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110)

            // Insight blurb
            if let peak = peakPeriod {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: peak.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accentColor)

                    Text("You're most active in the **\(peak.rawValue)**")
                        .font(.system(size: Typography.captionSize, weight: .medium))
                        .foregroundStyle(Color.pureWhite.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Spacing.lg)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }

    // MARK: - Helpers

    private func barHeight(for period: Period) -> CGFloat {
        let count = counts[period] ?? 0
        guard maxCount > 0, count > 0 else { return 6 }
        let ratio = CGFloat(count) / CGFloat(maxCount)
        return max(ratio * 64, 8)
    }
}

// MARK: - Preview

#Preview("Peak Hours Chart") {
    let cal = Calendar.current
    let today = Date()
    var dates: [Date] = []
    let schedule: [(Int, Int)] = [
        (8, 30), (9, 0), (8, 15), (9, 45), (7, 50), // mornings
        (14, 0), (15, 30),                            // afternoons
        (19, 0), (20, 30), (18, 45), (19, 15),       // evenings
        (23, 0)                                       // night
    ]
    for (h, m) in schedule {
        if let d = cal.date(byAdding: .day, value: -Int.random(in: 0...20), to: today),
           let t = cal.date(bySettingHour: h, minute: m, second: 0, of: d) {
            dates.append(t)
        }
    }
    return ZStack {
        Color.brandBlack.ignoresSafeArea()
        PeakHoursChart(completions: dates)
            .padding(Spacing.lg)
    }
}

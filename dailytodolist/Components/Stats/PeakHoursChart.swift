//
//  PeakHoursChart.swift
//  Reps
//
//  Purpose: Shows which time-of-day the user completes tasks most.
//  Design:  4-block bar chart (Morning / Afternoon / Evening / Night)
//           Uses exact completedAt timestamps already stored in TaskCompletion.
//

import SwiftUI

/// Visualises completion activity across 4 time-of-day windows.
///
/// Windows:
///   Morning   06:00–11:59
///   Afternoon 12:00–16:59
///   Evening   17:00–21:59
///   Night     22:00–05:59
struct PeakHoursChart: View {

    // MARK: - Properties

    /// Raw completion timestamps (not normalised to start-of-day — needs exact time)
    let completions: [Date]
    var accentColor: Color = .recoveryGreen

    // MARK: - Types

    private struct Block {
        let label: String
        let icon: String
        let hours: ClosedRange<Int>   // hour-of-day (0–23); Night wraps via special handling
    }

    private let blocks: [Block] = [
        Block(label: "MORNING",   icon: "sunrise.fill",  hours: 6...11),
        Block(label: "AFTERNOON", icon: "sun.max.fill",  hours: 12...16),
        Block(label: "EVENING",   icon: "sunset.fill",   hours: 17...21),
        Block(label: "NIGHT",     icon: "moon.stars.fill", hours: 22...23), // + 0...5 handled below
    ]

    private let calendar = Calendar.current

    // MARK: - Computed

    private var counts: [Int] {
        var result = [Int](repeating: 0, count: 4)
        for date in completions {
            let hour = calendar.component(.hour, from: date)
            switch hour {
            case 6...11:  result[0] += 1
            case 12...16: result[1] += 1
            case 17...21: result[2] += 1
            default:      result[3] += 1   // 22–23 and 0–5 → Night
            }
        }
        return result
    }

    private var maxCount: Int { counts.max() ?? 1 }

    private var peakIndex: Int {
        counts.indices.max(by: { counts[$0] < counts[$1] }) ?? 0
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("PEAK HOURS")
                .font(.system(size: Typography.captionSize, weight: .bold))
                .foregroundStyle(Color.mediumGray)
                .tracking(1.0)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .bottom, spacing: Spacing.sm) {
                ForEach(blocks.indices, id: \.self) { i in
                    let isPeak = i == peakIndex && maxCount > 0
                    VStack(spacing: Spacing.xs) {
                        // Count label above bar
                        if counts[i] > 0 {
                            Text("\(counts[i])")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(isPeak ? accentColor : Color.mediumGray)
                        } else {
                            Text("–")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.darkGray2)
                        }

                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                counts[i] > 0
                                    ? accentColor.opacity(barOpacity(for: i))
                                    : Color.darkGray2
                            )
                            .frame(height: barHeight(for: i))

                        // Icon
                        Image(systemName: blocks[i].icon)
                            .font(.system(size: 12))
                            .foregroundStyle(isPeak ? accentColor : Color.mediumGray)

                        // Label
                        Text(blocks[i].label)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(isPeak ? accentColor : Color.mediumGray)
                            .tracking(0.3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110)

            // Peak insight blurb
            if maxCount > 0 {
                let peak = blocks[peakIndex]
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accentColor)
                    Text("You're most active in the \(peak.label.capitalized.lowercased())")
                        .font(.system(size: Typography.captionSize, weight: .medium))
                        .foregroundStyle(Color.mediumGray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Spacing.lg)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }

    // MARK: - Helpers

    private func barHeight(for index: Int) -> CGFloat {
        guard maxCount > 0 else { return 8 }
        let ratio = CGFloat(counts[index]) / CGFloat(maxCount)
        return max(ratio * 64, 8)
    }

    private func barOpacity(for index: Int) -> Double {
        guard maxCount > 0 else { return 0.2 }
        let ratio = Double(counts[index]) / Double(maxCount)
        return max(ratio * 0.85 + 0.15, 0.2)
    }
}

// MARK: - Preview

#Preview("Peak Hours Chart") {
    let calendar = Calendar.current
    var dates: [Date] = []

    // Simulate morning-heavy completions
    for daysAgo in 0..<30 {
        guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
        // Morning completions (most)
        for hour in [7, 8, 9] {
            if let t = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) { dates.append(t) }
        }
        // Some afternoon
        if daysAgo % 2 == 0, let t = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: day) { dates.append(t) }
        // Occasional evening
        if daysAgo % 3 == 0, let t = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: day) { dates.append(t) }
    }

    return ZStack {
        Color.brandBlack.ignoresSafeArea()
        PeakHoursChart(completions: dates)
            .padding(Spacing.lg)
    }
}

//
//  PersonalRecordsCard.swift
//  Reps
//
//  Purpose: Surfaces personal-best milestones — best day, best week, total active days.
//  Design:  2×2 grid of compact stat tiles, trophy icon for best values.
//

import SwiftUI

/// Displays personal records computed from the user's completion history.
///
/// Records shown:
///   - Best Day    (most completions in a single calendar day)
///   - Best Week   (most completions in a single ISO week)
///   - Active Days (unique calendar days with ≥1 completion)
///   - Avg / Week  (total completions ÷ number of active weeks)
struct PersonalRecordsCard: View {

    // MARK: - Properties

    let completions: [Date]
    var accentColor: Color = .recoveryGreen

    // MARK: - Computed

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.locale = Locale.current
        return cal
    }()

    private var records: Records {
        Records(completions: completions, calendar: calendar)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("PERSONAL RECORDS")
                .font(.system(size: Typography.captionSize, weight: .bold))
                .foregroundStyle(Color.mediumGray)
                .tracking(1.0)
                .frame(maxWidth: .infinity, alignment: .leading)

            let r = records

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                RecordTile(
                    icon: "trophy.fill",
                    label: "BEST DAY",
                    value: "\(r.bestDay)",
                    unit: r.bestDay == 1 ? "rep" : "reps",
                    accentColor: accentColor
                )
                RecordTile(
                    icon: "calendar.badge.checkmark",
                    label: "BEST WEEK",
                    value: "\(r.bestWeek)",
                    unit: r.bestWeek == 1 ? "rep" : "reps",
                    accentColor: accentColor
                )
                RecordTile(
                    icon: "flame.fill",
                    label: "ACTIVE DAYS",
                    value: "\(r.activeDays)",
                    unit: r.activeDays == 1 ? "day" : "days",
                    accentColor: accentColor
                )
                RecordTile(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "AVG / WEEK",
                    value: r.avgPerWeekDisplay,
                    unit: "reps",
                    accentColor: accentColor
                )
            }
        }
        .padding(Spacing.lg)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }
}

// MARK: - Records Model

private struct Records {
    let bestDay: Int
    let bestWeek: Int
    let activeDays: Int
    let avgPerWeekDisplay: String

    init(completions: [Date], calendar: Calendar) {
        guard !completions.isEmpty else {
            self.bestDay = 0; self.bestWeek = 0; self.activeDays = 0; self.avgPerWeekDisplay = "0"
            return
        }

        // Count by day
        var dayCounts: [Date: Int] = [:]
        for date in completions {
            let day = calendar.startOfDay(for: date)
            dayCounts[day, default: 0] += 1
        }

        // Count by ISO week
        var weekCounts: [String: Int] = [:]
        let weekFormatter = DateFormatter()
        weekFormatter.dateFormat = "yyyy-ww"
        weekFormatter.calendar = calendar
        for date in completions {
            let key = weekFormatter.string(from: date)
            weekCounts[key, default: 0] += 1
        }

        self.bestDay    = dayCounts.values.max() ?? 0
        self.bestWeek   = weekCounts.values.max() ?? 0
        self.activeDays = dayCounts.count

        let activeWeeks = weekCounts.count
        if activeWeeks > 0 {
            let avg = Double(completions.count) / Double(activeWeeks)
            // Show one decimal if not a whole number
            if avg.truncatingRemainder(dividingBy: 1) == 0 {
                self.avgPerWeekDisplay = "\(Int(avg))"
            } else {
                self.avgPerWeekDisplay = String(format: "%.1f", avg)
            }
        } else {
            self.avgPerWeekDisplay = "0"
        }
    }
}

// MARK: - Record Tile

private struct RecordTile: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accentColor)
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.mediumGray)
                    .tracking(0.5)
            }

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: Typography.h3Size, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.pureWhite)
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.mediumGray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.darkGray2)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
    }
}

// MARK: - Preview

#Preview("Personal Records Card") {
    let calendar = Calendar.current
    var dates: [Date] = []

    for daysAgo in 0..<60 {
        guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
        let repsToday = daysAgo % 5 == 0 ? 4 : (daysAgo % 2 == 0 ? 2 : 1)
        for i in 0..<repsToday {
            if let t = calendar.date(bySettingHour: 8 + i * 3, minute: 0, second: 0, of: day) {
                dates.append(t)
            }
        }
    }

    return ZStack {
        Color.brandBlack.ignoresSafeArea()
        PersonalRecordsCard(completions: dates)
            .padding(Spacing.lg)
    }
}

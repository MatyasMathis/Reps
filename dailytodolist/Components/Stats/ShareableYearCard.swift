//
//  ShareableYearCard.swift
//  Reps
//
//  Purpose: Branded shareable card showing the full-year pixel heatmap
//  Design: Strava-inspired — dark, minimal, year + grid + key stats
//

import SwiftUI

/// Branded 1080x1920 card with the Year in Pixels heatmap rendered offscreen via ImageRenderer.
///
/// Uses raw color values (not theme colors) since ImageRenderer
/// runs outside the view hierarchy.
struct ShareableYearCard: View {

    // MARK: - Properties

    let selectedYear: Int
    let monthRows: [[DayInfo]]
    let monthNames: [String]
    let totalCompletions: Int
    let activeDays: Int
    let longestStreak: Int

    // MARK: - Constants

    private let cardWidth: CGFloat = 1080
    private let cardHeight: CGFloat = 1920

    // Raw theme colors for ImageRenderer
    private let bgBlack = Color(red: 0.04, green: 0.04, blue: 0.04)
    private let surfaceDark = Color(red: 0.10, green: 0.10, blue: 0.10)
    private let surfaceMid = Color(red: 0.165, green: 0.165, blue: 0.165)
    private let recoveryGreen = Color(red: 0.176, green: 0.847, blue: 0.506) // #2DD881

    // Pixel grid sizing
    private let cellSize: CGFloat = 24
    private let cellSpacing: CGFloat = 4
    private let monthLabelWidth: CGFloat = 68

    // MARK: - Body

    var body: some View {
        ZStack {
            bgBlack

            VStack(spacing: 0) {
                Spacer()

                // Year number
                Text(String(selectedYear))
                    .font(.system(size: 140, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.bottom, 64)

                // Pixel heatmap grid
                pixelGrid
                    .padding(.horizontal, 48)
                    .padding(.bottom, 64)

                // Stats bar
                statsRow
                    .padding(.horizontal, 48)

                Spacer()

                // Branding
                Text("REPS")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.25))
                    .tracking(4)
                    .padding(.bottom, 96)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    // MARK: - Pixel Grid

    private var pixelGrid: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(monthRows.enumerated()), id: \.offset) { monthIndex, days in
                HStack(spacing: 0) {
                    // Month label
                    Text(monthNames[monthIndex])
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(width: monthLabelWidth, alignment: .trailing)
                        .padding(.trailing, 10)

                    // Day pixels
                    ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(pixelColor(for: day))
                            .frame(width: cellSize, height: cellSize)
                            .padding(.trailing, cellSpacing)
                            .padding(.bottom, cellSpacing)
                    }

                    // Pad remaining cells for months with < 31 days
                    if days.count < 31 {
                        ForEach(0..<(31 - days.count), id: \.self) { _ in
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                                .padding(.trailing, cellSpacing)
                                .padding(.bottom, cellSpacing)
                        }
                    }
                }
            }
        }
    }

    private func pixelColor(for day: DayInfo) -> Color {
        if day.isEmpty || day.isFuture { return Color.clear }
        let count = day.completionCount
        if count == 0 { return surfaceMid }
        switch count {
        case 1: return recoveryGreen.opacity(0.30)
        case 2: return recoveryGreen.opacity(0.50)
        case 3...4: return recoveryGreen.opacity(0.70)
        default: return recoveryGreen
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statsItem(value: "\(totalCompletions)", label: "REPS")

            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(width: 1, height: 48)

            statsItem(value: "\(activeDays)", label: "DAYS")

            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(width: 1, height: 48)

            statsItem(value: "\(longestStreak)", label: "STREAK")
        }
        .padding(.vertical, 44)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(surfaceDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func statsItem(value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundStyle(recoveryGreen)
            Text(label)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Year Card") {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let currentYear = calendar.component(.year, from: Date())

    // Build sample month rows
    var completionsByDate: [Date: Int] = [:]
    for i in stride(from: 0, through: 180, by: 1) where Int.random(in: 0...3) > 0 {
        if let d = calendar.date(byAdding: .day, value: -i, to: today) {
            completionsByDate[calendar.startOfDay(for: d)] = Int.random(in: 1...5)
        }
    }

    let monthRows: [[DayInfo]] = (1...12).map { month in
        var comps = DateComponents()
        comps.year = currentYear
        comps.month = month
        comps.day = 1
        guard let monthStart = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
        return range.map { day -> DayInfo in
            comps.day = day
            guard let date = calendar.date(from: comps) else { return DayInfo.empty }
            let start = calendar.startOfDay(for: date)
            return DayInfo(date: start, completionCount: completionsByDate[start] ?? 0,
                           isFuture: start > today, isToday: start == today)
        }
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    let monthNames: [String] = (1...12).compactMap { month in
        var comps = DateComponents()
        comps.year = currentYear
        comps.month = month
        comps.day = 1
        guard let date = calendar.date(from: comps) else { return nil }
        return formatter.string(from: date)
    }

    return ShareableYearCard(
        selectedYear: currentYear,
        monthRows: monthRows,
        monthNames: monthNames,
        totalCompletions: 342,
        activeDays: 87,
        longestStreak: 14
    )
    .scaleEffect(0.22)
    .frame(width: 1080 * 0.22, height: 1920 * 0.22)
}

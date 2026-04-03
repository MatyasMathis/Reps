//
//  ShareableYearCard.swift
//  Reps
//
//  Purpose: Branded shareable card showing the full-year pixel heatmap
//  Design: Strava-inspired — minimal, typographic, supports photo/solid/transparent backgrounds
//

import SwiftUI
import UIKit

enum ShareBackground {
    case photo(UIImage)
    case solid
    case transparent
}

/// Branded 1080x1920 card with the Year in Pixels heatmap rendered offscreen via ImageRenderer.
struct ShareableYearCard: View {

    // MARK: - Properties

    let selectedYear: Int
    let monthRows: [[DayInfo]]
    let monthNames: [String]
    let totalCompletions: Int
    let activeDays: Int
    let longestStreak: Int
    var background: ShareBackground = .solid

    // MARK: - Constants

    private let cardWidth: CGFloat = 1080
    private let cardHeight: CGFloat = 1920
    private let recoveryGreen = Color(red: 0.176, green: 0.847, blue: 0.506)
    private let bgBlack = Color(red: 0.04, green: 0.04, blue: 0.04)
    private let cellSize: CGFloat = 22
    private let cellSpacing: CGFloat = 5

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            backgroundLayer

            VStack(alignment: .leading, spacing: 0) {
                // Header: REPS YEAR
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 0) {
                        Text("REPS ")
                            .font(.system(size: 100, weight: .black))
                            .italic()
                            .foregroundStyle(.white)
                        Text(String(selectedYear))
                            .font(.system(size: 100, weight: .black))
                            .italic()
                            .foregroundStyle(recoveryGreen)
                    }
                    .monospacedDigit()

                    Text("YEARLY PERFORMANCE")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white.opacity(0.35))
                        .tracking(4)
                }
                .padding(.top, 104)
                .padding(.horizontal, 64)

                Spacer()

                // Pixel dot grid
                pixelDotGrid
                    .padding(.horizontal, 64)

                // Legend
                HStack(spacing: 18) {
                    Text("LESS")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white.opacity(0.25))
                        .tracking(1.5)
                    ForEach([0.18, 0.38, 0.62, 0.82, 1.0], id: \.self) { opacity in
                        Circle()
                            .fill(recoveryGreen.opacity(opacity))
                            .frame(width: 22, height: 22)
                    }
                    Text("MORE")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white.opacity(0.25))
                        .tracking(1.5)
                }
                .padding(.top, 32)
                .padding(.horizontal, 64)

                Spacer()

                // Divider
                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 64)
                    .padding(.bottom, 56)

                // Stats
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TOTAL REPS")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white.opacity(0.35))
                            .tracking(2)
                        Text(totalCompletions.formatted())
                            .font(.system(size: 100, weight: .black))
                            .italic()
                            .foregroundStyle(recoveryGreen)
                            .monospacedDigit()
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("ACTIVE DAYS")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white.opacity(0.35))
                            .tracking(2)
                        Text("\(activeDays)")
                            .font(.system(size: 100, weight: .black))
                            .italic()
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 64)
                .padding(.bottom, 80)

                Text("REPS")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white.opacity(0.15))
                    .tracking(6)
                    .padding(.horizontal, 64)
                    .padding(.bottom, 96)
            }

            // Verified badge
            ZStack {
                Circle()
                    .fill(recoveryGreen)
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.black)
            }
            .padding(.top, 112)
            .padding(.trailing, 64)
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundLayer: some View {
        switch background {
        case .photo(let image):
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
                LinearGradient(
                    colors: [.black.opacity(0.25), .black.opacity(0.45), .black.opacity(0.88)],
                    startPoint: .top, endPoint: .bottom
                )
            }
        case .solid:
            bgBlack
        case .transparent:
            Color.clear
        }
    }

    // MARK: - Pixel Grid

    private var pixelDotGrid: some View {
        VStack(alignment: .leading, spacing: cellSpacing) {
            ForEach(Array(monthRows.enumerated()), id: \.offset) { _, days in
                HStack(spacing: cellSpacing) {
                    ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                        Circle()
                            .fill(pixelColor(for: day))
                            .frame(width: cellSize, height: cellSize)
                    }
                    if days.count < 31 {
                        ForEach(0..<(31 - days.count), id: \.self) { _ in
                            Color.clear.frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    private func pixelColor(for day: DayInfo) -> Color {
        if day.isEmpty { return .clear }
        if day.isFuture { return .white.opacity(0.06) }
        let count = day.completionCount
        if count == 0 { return .white.opacity(0.08) }
        switch count {
        case 1: return recoveryGreen.opacity(0.28)
        case 2: return recoveryGreen.opacity(0.52)
        case 3...4: return recoveryGreen.opacity(0.76)
        default: return recoveryGreen
        }
    }
}

// MARK: - Preview

#Preview("Year Card") {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let currentYear = calendar.component(.year, from: Date())
    var completionsByDate: [Date: Int] = [:]
    for i in stride(from: 0, through: 180, by: 1) where Int.random(in: 0...3) > 0 {
        if let d = calendar.date(byAdding: .day, value: -i, to: today) {
            completionsByDate[calendar.startOfDay(for: d)] = Int.random(in: 1...5)
        }
    }
    let monthRows: [[DayInfo]] = (1...12).map { month in
        var comps = DateComponents(); comps.year = currentYear; comps.month = month; comps.day = 1
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
    let formatter = DateFormatter(); formatter.dateFormat = "MMM"
    let monthNames: [String] = (1...12).compactMap { month in
        var comps = DateComponents(); comps.year = currentYear; comps.month = month; comps.day = 1
        guard let date = calendar.date(from: comps) else { return nil }
        return formatter.string(from: date)
    }
    return ShareableYearCard(
        selectedYear: currentYear, monthRows: monthRows, monthNames: monthNames,
        totalCompletions: 1248, activeDays: 312, longestStreak: 42, background: .solid
    )
    .scaleEffect(0.22)
    .frame(width: 1080 * 0.22, height: 1920 * 0.22)
}

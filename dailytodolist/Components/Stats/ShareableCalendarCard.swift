//
//  ShareableCalendarCard.swift
//  Reps
//
//  Purpose: Branded shareable card showing a category's monthly completion calendar
//  Design: Matches Year-in-Pixels card — full-bleed typographic layout with big header,
//          badge, full calendar grid, and bold stats at bottom.
//

import SwiftUI
import UIKit

/// Branded 1080x1920 card with monthly completion calendar rendered offscreen via ImageRenderer.
///
/// Uses raw color values (not theme colors) since ImageRenderer
/// runs outside the view hierarchy.
struct ShareableCalendarCard: View {

    // MARK: - Properties

    let categoryName: String
    let categoryIcon: String
    let categoryColorHex: String
    let completionDates: Set<Date>
    let displayedMonth: Date
    let streak: Int
    let completionCount: Int
    var background: ShareBackground = .solid

    // MARK: - Constants

    private let cardWidth: CGFloat = 1080
    private let cardHeight: CGFloat = 1920

    private var categoryColor: Color { Color(hex: categoryColorHex) }

    // Raw theme colors for ImageRenderer
    private let bgBlack = Color(red: 0.04, green: 0.04, blue: 0.04)

    private let calendar = Calendar.current
    private let daysOfWeek = ["M", "T", "W", "T", "F", "S", "S"]

    // MARK: - Computed Properties

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: displayedMonth).uppercased()
    }

    private var yearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var daysInMonth: [ShareCalDay] {
        var days: [ShareCalDay] = []

        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let monthRange = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return days
        }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingEmptyDays = (firstWeekday + 5) % 7

        for _ in 0..<leadingEmptyDays {
            days.append(ShareCalDay(dayNumber: 0))
        }

        let today = calendar.startOfDay(for: Date())
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                let startOfDate = calendar.startOfDay(for: date)
                days.append(ShareCalDay(
                    dayNumber: day,
                    isCompleted: completionDates.contains(startOfDate),
                    isToday: startOfDate == today,
                    isFuture: startOfDate > today
                ))
            }
        }

        return days
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            backgroundLayer

            // Main content — full-bleed layout matching Year card
            VStack(alignment: .leading, spacing: 0) {

                // Header: REPS + MONTH (like "REPS 2024")
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 0) {
                        Text("REPS ")
                            .font(.system(size: 100, weight: .black))
                            .italic()
                            .foregroundStyle(.white)
                        Text(monthTitle)
                            .font(.system(size: 100, weight: .black))
                            .italic()
                            .foregroundStyle(categoryColor)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .monospacedDigit()

                    // Category + Year subtitle
                    HStack(spacing: 16) {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(categoryColor.opacity(0.7))
                        Text("\(categoryName.uppercased())  ·  \(yearTitle)")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white.opacity(0.35))
                            .tracking(3)
                    }
                }
                .padding(.top, 104)
                .padding(.horizontal, 64)

                Spacer()

                // Calendar grid
                calendarGrid
                    .padding(.horizontal, 64)

                Spacer()

                // Divider
                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 64)
                    .padding(.bottom, 56)

                // Stats — big italic numbers like year card
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DAYS COMPLETED")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white.opacity(0.35))
                            .tracking(2)
                        Text("\(completionCount)")
                            .font(.system(size: 100, weight: .black))
                            .italic()
                            .foregroundStyle(categoryColor)
                            .monospacedDigit()
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("STREAK")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white.opacity(0.35))
                            .tracking(2)
                        Text("\(streak)")
                            .font(.system(size: 100, weight: .black))
                            .italic()
                            .foregroundStyle(streak > 0 ? .white : .white.opacity(0.2))
                            .monospacedDigit()
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 64)
                .padding(.bottom, 80)

                // Branding
                Text("REPS")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white.opacity(0.15))
                    .tracking(6)
                    .padding(.horizontal, 64)
                    .padding(.bottom, 96)
            }

            // Verified badge (top-right, matching year card)
            ZStack {
                Circle()
                    .fill(categoryColor)
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

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 16) {
            // Days-of-week header
            HStack(spacing: 0) {
                ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, day in
                    shareCalDayCell(day: day)
                }
            }
        }
    }

    @ViewBuilder
    private func shareCalDayCell(day: ShareCalDay) -> some View {
        if day.dayNumber > 0 {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(dayCellBackground(day))

                if day.isToday && !day.isCompleted {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(categoryColor.opacity(0.5), lineWidth: 2)
                }

                Text("\(day.dayNumber)")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(dayCellTextColor(day))
            }
            .aspectRatio(1, contentMode: .fit)
        } else {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
        }
    }

    private func dayCellBackground(_ day: ShareCalDay) -> Color {
        if day.isCompleted { return categoryColor }
        if day.isFuture { return .white.opacity(0.03) }
        return .white.opacity(0.07)
    }

    private func dayCellTextColor(_ day: ShareCalDay) -> Color {
        if day.isFuture { return .white.opacity(0.15) }
        if day.isCompleted { return bgBlack }
        return .white.opacity(0.45)
    }

    // MARK: - Background

    private var hasPhotoBackground: Bool {
        if case .photo = background { return true }
        return false
    }

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
}

// MARK: - Share Calendar Day Model

private struct ShareCalDay {
    let dayNumber: Int
    var isCompleted: Bool = false
    var isToday: Bool = false
    var isFuture: Bool = false
}

// MARK: - Preview

#Preview("Calendar Card - No Photo") {
    let calendar = Calendar.current
    var dates: Set<Date> = []
    for daysAgo in [0, 1, 2, 3, 5, 8, 10, 12, 15, 18, 20] {
        if let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) {
            dates.insert(calendar.startOfDay(for: date))
        }
    }

    return ShareableCalendarCard(
        categoryName: "Health",
        categoryIcon: "heart.fill",
        categoryColorHex: "2DD881",
        completionDates: dates,
        displayedMonth: Date(),
        streak: 4,
        completionCount: 11,
        background: .solid
    )
    .scaleEffect(0.25)
    .frame(width: 270, height: 480)
}

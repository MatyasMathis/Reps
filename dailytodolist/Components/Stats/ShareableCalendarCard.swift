//
//  ShareableCalendarCard.swift
//  Reps
//
//  Purpose: Branded shareable card showing a category's monthly completion calendar
//  Design: Strava-inspired — photo background, compact calendar, minimal text
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
    private let surfaceDark = Color(red: 0.10, green: 0.10, blue: 0.10)
    private let surfaceMid = Color(red: 0.165, green: 0.165, blue: 0.165)

    private let calendar = Calendar.current
    private let daysOfWeek = ["M", "T", "W", "T", "F", "S", "S"]

    // MARK: - Computed Properties

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth).uppercased()
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
        ZStack {
            // Background
            backgroundLayer

            // Content — pushed to bottom half, Strava-style
            VStack(spacing: 0) {
                Spacer()

                // Calendar card — frosted glass container
                VStack(spacing: 36) {
                    // Header: category + month
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: categoryIcon)
                                .font(.system(size: 24, weight: .semibold))
                            Text(categoryName.uppercased())
                                .font(.system(size: 24, weight: .bold))
                                .tracking(3)
                        }
                        .foregroundStyle(categoryColor)

                        Text(monthTitle)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                            .tracking(2)
                    }

                    // Compact calendar grid
                    calendarGrid

                    // Bottom stats row
                    HStack(spacing: 0) {
                        // Completions
                        VStack(spacing: 4) {
                            Text("\(completionCount)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(categoryColor)
                            Text("DAYS")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .tracking(1.5)
                        }
                        .frame(maxWidth: .infinity)

                        // Divider
                        Rectangle()
                            .fill(.white.opacity(0.1))
                            .frame(width: 1, height: 44)

                        // Streak
                        VStack(spacing: 4) {
                            Text("\(streak)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(streak > 0 ? categoryColor : .white.opacity(0.3))
                            Text("STREAK")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .tracking(1.5)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 48)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(.black.opacity(hasPhotoBackground ? 0.55 : 0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 48)

                // Branding
                Text("REPS")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(4)
                    .padding(.top, 40)
                    .padding(.bottom, 80)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 14) {
            // Days of week header
            HStack(spacing: 0) {
                ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells — compact dots with day numbers
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

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
                RoundedRectangle(cornerRadius: 16)
                    .fill(dayCellBackground(day))
                    .frame(width: 88, height: 88)

                Text("\(day.dayNumber)")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(dayCellTextColor(day))
            }
            .frame(height: 88)
        } else {
            Color.clear
                .frame(height: 88)
        }
    }

    private func dayCellBackground(_ day: ShareCalDay) -> Color {
        if day.isCompleted { return categoryColor }
        if day.isFuture { return .white.opacity(0.03) }
        return .white.opacity(0.06)
    }

    private func dayCellTextColor(_ day: ShareCalDay) -> Color {
        if day.isFuture { return .white.opacity(0.15) }
        if day.isCompleted { return bgBlack }
        return .white.opacity(0.4)
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
                    colors: [.black.opacity(0.3), .black.opacity(0.4), .black.opacity(0.85)],
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

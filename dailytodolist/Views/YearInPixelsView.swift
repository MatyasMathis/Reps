//
//  YearInPixelsView.swift
//  Reps
//
//  Purpose: Annual progress heatmap showing completion consistency
//  Design: 12 rows (months) x 31 columns (days), left-to-right reading
//

import SwiftUI
import UIKit
import SwiftData

/// Year in Pixels — a full-year heatmap of daily task completions
///
/// Layout: 12 rows (Jan-Dec), up to 31 columns (day of month)
/// Each pixel is colored by completion count for that day.
/// Tapping a pixel shows details.
struct YearInPixelsView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Pro Gate

    @ObservedObject private var store = StoreKitService.shared

    // MARK: - Queries

    @Query(sort: \TaskCompletion.completedAt, order: .reverse)
    private var allCompletions: [TaskCompletion]

    // MARK: - State

    @State private var selectedYear: Int
    @State private var selectedDayInfo: DayInfo?
    @State private var showShare = false

    // MARK: - Constants

    private let cellSize: CGFloat = 10
    private let cellSpacing: CGFloat = 2

    // MARK: - Init

    init() {
        _selectedYear = State(initialValue: Calendar.current.component(.year, from: Date()))
    }

    // MARK: - Computed Properties

    private let calendar = Calendar.current

    /// Map of date -> completion count for the selected year
    private var completionsByDate: [Date: Int] {
        var map: [Date: Int] = [:]

        for completion in allCompletions {
            let year = calendar.component(.year, from: completion.completedAt)
            guard year == selectedYear else { continue }
            let day = calendar.startOfDay(for: completion.completedAt)
            map[day, default: 0] += 1
        }

        return map
    }

    /// Month data: 12 arrays of DayInfo, one per month
    private var monthRows: [[DayInfo]] {
        let today = calendar.startOfDay(for: Date())

        return (1...12).map { month in
            var comps = DateComponents()
            comps.year = selectedYear
            comps.month = month
            comps.day = 1

            guard let monthStart = calendar.date(from: comps),
                  let range = calendar.range(of: .day, in: .month, for: monthStart) else {
                return []
            }

            return range.map { day -> DayInfo in
                comps.day = day
                guard let date = calendar.date(from: comps) else {
                    return DayInfo.empty
                }
                let startOfDate = calendar.startOfDay(for: date)
                let count = completionsByDate[startOfDate] ?? 0

                return DayInfo(
                    date: startOfDate,
                    completionCount: count,
                    isFuture: startOfDate > today,
                    isToday: startOfDate == today
                )
            }
        }
    }

    /// Short month names
    private var monthNames: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return (1...12).compactMap { month in
            var comps = DateComponents()
            comps.year = selectedYear
            comps.month = month
            comps.day = 1
            guard let date = calendar.date(from: comps) else { return nil }
            return formatter.string(from: date)
        }
    }

    /// Total completions this year
    private var totalCompletions: Int {
        completionsByDate.values.reduce(0, +)
    }

    /// Days with at least one completion
    private var activeDays: Int {
        completionsByDate.filter { $0.value > 0 }.count
    }

    /// Best single day count
    private var bestDay: Int {
        completionsByDate.values.max() ?? 0
    }

    /// Longest streak in selected year
    private var longestStreak: Int {
        let sortedDates = completionsByDate.keys.sorted()
        guard !sortedDates.isEmpty else { return 0 }

        var maxStreak = 1
        var current = 1

        for i in 1..<sortedDates.count {
            if let expected = calendar.date(byAdding: .day, value: 1, to: sortedDates[i - 1]),
               calendar.isDate(expected, inSameDayAs: sortedDates[i]) {
                current += 1
                maxStreak = max(maxStreak, current)
            } else {
                current = 1
            }
        }

        return maxStreak
    }

    private var canGoNext: Bool {
        selectedYear < calendar.component(.year, from: Date())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xxl) {
                        // Year selector — always visible
                        yearSelector

                        // Year content — gated behind Pro with blurred sneak peek
                        ProFeatureOverlay(
                            icon: "calendar.badge.clock",
                            title: "Year in Pixels",
                            subtitle: "Unlock your full-year heatmap\nand completion patterns"
                        ) {
                            VStack(spacing: Spacing.xxl) {
                                statsSummary
                                pixelGrid
                                legend

                                if let info = selectedDayInfo {
                                    selectedDayDetail(info)
                                }
                            }
                        }

                        Color.clear.frame(height: 40)
                    }
                    .padding(.top, Spacing.lg)
                }
            }
            .navigationTitle("Year in Pixels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if store.isProUnlocked {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showShare = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.recoveryGreen)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.recoveryGreen)
                }
            }
            .toolbarBackground(Color.brandBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showShare) {
                YearShareSheet(
                    selectedYear: selectedYear,
                    monthRows: monthRows,
                    monthNames: monthNames,
                    totalCompletions: totalCompletions,
                    activeDays: activeDays,
                    longestStreak: longestStreak
                )
            }
        }
    }

    // MARK: - Subviews

    private var yearSelector: some View {
        HStack(spacing: Spacing.xl) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedYear -= 1
                    selectedDayInfo = nil
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.pureWhite)
                    .frame(width: 44, height: 44)
            }

            Text(String(selectedYear))
                .font(.system(size: Typography.h2Size, weight: .bold, design: .rounded))
                .foregroundStyle(Color.pureWhite)
                .frame(minWidth: 100)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedYear += 1
                    selectedDayInfo = nil
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canGoNext ? Color.pureWhite : Color.darkGray2)
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoNext)
        }
    }

    private var statsSummary: some View {
        HStack(spacing: 0) {
            statItem(value: "\(totalCompletions)", label: "TOTAL REPS")
            statItem(value: "\(activeDays)", label: "ACTIVE DAYS")
            statItem(value: "\(longestStreak)", label: "BEST STREAK")
            statItem(value: "\(bestDay)", label: "BEST DAY")
        }
        .padding(.vertical, Spacing.lg)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .padding(.horizontal, Spacing.lg)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.system(size: Typography.h3Size, weight: .bold, design: .rounded))
                .foregroundStyle(Color.recoveryGreen)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.mediumGray)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    private var pixelGrid: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day number header (1, 5, 10, 15, 20, 25, 30)
            HStack(spacing: 0) {
                // Spacer for month label column
                Color.clear.frame(width: 32, height: 14)

                ForEach(1...31, id: \.self) { day in
                    if day == 1 || day % 5 == 0 {
                        Text("\(day)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(Color.mediumGray)
                            .frame(width: cellSize + cellSpacing, height: 14)
                    } else {
                        Color.clear
                            .frame(width: cellSize + cellSpacing, height: 14)
                    }
                }
            }

            // Month rows
            ForEach(Array(monthRows.enumerated()), id: \.offset) { monthIndex, days in
                HStack(spacing: 0) {
                    // Month label
                    Text(monthNames[monthIndex])
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.mediumGray)
                        .frame(width: 32, alignment: .trailing)
                        .padding(.trailing, Spacing.xs)

                    // Day pixels
                    ForEach(Array(days.enumerated()), id: \.offset) { dayIndex, day in
                        pixelCell(for: day)
                            .padding(.trailing, cellSpacing)
                            .padding(.bottom, cellSpacing)
                    }

                    // Pad remaining cells if month has < 31 days
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
        .padding(Spacing.md)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .padding(.horizontal, Spacing.sm)
    }

    private func pixelCell(for day: DayInfo) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(pixelColor(for: day))
            .frame(width: cellSize, height: cellSize)
            .overlay {
                if day.isToday {
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(Color.pureWhite, lineWidth: 1)
                }
            }
            .onTapGesture {
                if !day.isEmpty && !day.isFuture {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDayInfo = day
                    }
                }
            }
    }

    private func pixelColor(for day: DayInfo) -> Color {
        if day.isEmpty || day.isFuture { return Color.clear }

        let count = day.completionCount
        if count == 0 { return Color.darkGray2 }

        switch count {
        case 1: return Color.recoveryGreen.opacity(0.3)
        case 2: return Color.recoveryGreen.opacity(0.5)
        case 3...4: return Color.recoveryGreen.opacity(0.7)
        default: return Color.recoveryGreen
        }
    }

    private var legend: some View {
        HStack(spacing: Spacing.sm) {
            Text("Less")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.mediumGray)

            ForEach([0.0, 0.3, 0.5, 0.7, 1.0], id: \.self) { opacity in
                RoundedRectangle(cornerRadius: 2)
                    .fill(opacity == 0 ? Color.darkGray2 : Color.recoveryGreen.opacity(opacity))
                    .frame(width: 11, height: 11)
            }

            Text("More")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.mediumGray)
        }
    }

    private func selectedDayDetail(_ info: DayInfo) -> some View {
        VStack(spacing: Spacing.md) {
            Text(info.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                .font(.system(size: Typography.bodySize, weight: .semibold))
                .foregroundStyle(Color.pureWhite)

            VStack(spacing: Spacing.xs) {
                Text("\(info.completionCount)")
                    .font(.system(size: Typography.h2Size, weight: .bold, design: .rounded))
                    .foregroundStyle(info.completionCount > 0 ? Color.recoveryGreen : Color.mediumGray)
                Text("COMPLETIONS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.mediumGray)
                    .tracking(0.5)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .padding(.horizontal, Spacing.lg)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Day Info Model

struct DayInfo: Equatable {
    let date: Date
    let completionCount: Int
    let isFuture: Bool
    let isToday: Bool
    let isEmpty: Bool

    init(date: Date, completionCount: Int, isFuture: Bool = false, isToday: Bool = false) {
        self.date = date
        self.completionCount = completionCount
        self.isFuture = isFuture
        self.isToday = isToday
        self.isEmpty = false
    }

    private init() {
        self.date = Date()
        self.completionCount = 0
        self.isFuture = false
        self.isToday = false
        self.isEmpty = true
    }

    static let empty = DayInfo()
}

// MARK: - Preview

#Preview {
    YearInPixelsView()
        .modelContainer(for: [TodoTask.self, TaskCompletion.self, CustomCategory.self], inMemory: true)
}

//
//  HistoryView.swift
//  dailytodolist
//
//  Purpose: Display history of completed tasks with Whoop-inspired design
//  Design: Dark theme with calendar navigation, section headers, and card-based rows
//

import SwiftUI
import SwiftData

/// View for displaying completed tasks history with Whoop-inspired styling
///
/// Features:
/// - Collapsible calendar for quick date navigation
/// - Dark theme background
/// - Styled section headers (Today, Yesterday, dates)
/// - Card-based completion rows
/// - Empty state with motivational message
struct HistoryView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State

    @State private var refreshID = UUID()
    @State private var showCalendarSheet = false
    @State private var calendarMonth = Date()
    @State private var scrollProxy: ScrollViewProxy?

    // MARK: - Queries

    @Query(sort: \TaskCompletion.completedAt, order: .reverse)
    private var completions: [TaskCompletion]

    // MARK: - Computed Properties

    private var groupedCompletions: [Date: [TaskCompletion]] {
        let calendar = Calendar.current
        var grouped: [Date: [TaskCompletion]] = [:]

        for completion in completions {
            let dayKey = calendar.startOfDay(for: completion.completedAt)
            if grouped[dayKey] == nil {
                grouped[dayKey] = []
            }
            grouped[dayKey]?.append(completion)
        }

        return grouped
    }

    private var sortedDates: [Date] {
        groupedCompletions.keys.sorted(by: >)
    }

    private var completionDatesSet: Set<Date> {
        Set(groupedCompletions.keys)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
                // Background
                Color.brandBlack.ignoresSafeArea()

                if completions.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }

                // Floating calendar button
                if !completions.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            FloatingActionButton(icon: "calendar") {
                                showCalendarSheet = true
                            }
                            .padding(.trailing, Spacing.xxl)
                            .padding(.bottom, 80)
                        }
                    }
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
                // Refresh data when app comes to foreground (e.g., after widget interaction)
                if newPhase == .active {
                    refreshID = UUID()
                }
            }
            .id(refreshID)
            .sheet(isPresented: $showCalendarSheet) {
                calendarSheet
            }
    }

    // MARK: - Subviews

    private var historyListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(sortedDates, id: \.self) { date in
                        Section {
                            VStack(spacing: Spacing.sm) {
                                if let dateCompletions = groupedCompletions[date] {
                                    ForEach(dateCompletions) { completion in
                                        HistoryRow(completion: completion)
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.md)
                        } header: {
                            SectionHeader(title: formatDateHeader(date))
                        }
                        .id(date)
                    }
                }
                .padding(.bottom, 80) // Space for floating button
            }
            .refreshable {
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
    }

    private var calendarSheet: some View {
        NavigationStack {
            ZStack {
                Color.brandBlack.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    // Calendar (always expanded in sheet)
                    calendarContent
                        .padding(.horizontal, Spacing.lg)

                    Spacer()
                }
                .padding(.top, Spacing.md)
            }
            .navigationTitle("Jump to Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showCalendarSheet = false
                    }
                    .foregroundStyle(Color.recoveryGreen)
                }
            }
            .toolbarBackground(Color.brandBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var calendarContent: some View {
        VStack(spacing: Spacing.md) {
            // Month navigation
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: calendarMonth) {
                            calendarMonth = previousMonth
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.pureWhite)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(monthTitle)
                        .font(.system(size: Typography.captionSize, weight: .bold))
                        .foregroundStyle(Color.pureWhite)
                        .tracking(1.2)

                    Text("\(completionCountForMonth) completion\(completionCountForMonth == 1 ? "" : "s")")
                        .font(.system(size: Typography.captionSize, weight: .medium))
                        .foregroundStyle(Color.mediumGray)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: calendarMonth) {
                            calendarMonth = nextMonth
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(canGoToNextMonth ? Color.pureWhite : Color.darkGray2)
                        .frame(width: 44, height: 44)
                }
                .disabled(!canGoToNextMonth)
            }

            // Days of week header
            HStack(spacing: 0) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: Typography.captionSize, weight: .semibold))
                        .foregroundStyle(Color.mediumGray)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(daysInMonth) { day in
                    CalendarDayCell(day: day) {
                        if let date = day.date, day.hasCompletions {
                            scrollToDate(date)
                            showCalendarSheet = false
                        }
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
    }

    private var emptyStateView: some View {
        EmptyStateCard(
            icon: "flame",
            title: "No wins yet.",
            subtitle: "Complete tasks to build your streak. It starts today."
        )
    }

    // MARK: - Calendar Computed Properties

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: calendarMonth).uppercased()
    }

    private var completionCountForMonth: Int {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: calendarMonth))!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!

        return completionDatesSet.filter { $0 >= monthStart && $0 < nextMonth }.count
    }

    private var canGoToNextMonth: Bool {
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: calendarMonth) else {
            return false
        }
        let nextMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth))!
        let today = calendar.startOfDay(for: Date())
        return nextMonthStart <= today
    }

    private var daysInMonth: [CalendarDay] {
        let calendar = Calendar.current
        var days: [CalendarDay] = []

        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: calendarMonth)),
              let monthRange = calendar.range(of: .day, in: .month, for: calendarMonth) else {
            return days
        }

        // Get the weekday of the first day (1 = Sunday, 2 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        // Convert to Monday-based (0 = Monday, 6 = Sunday)
        let leadingEmptyDays = (firstWeekday + 5) % 7

        // Add empty days for alignment
        for _ in 0..<leadingEmptyDays {
            days.append(CalendarDay(date: nil, dayNumber: 0))
        }

        // Add actual days
        let today = calendar.startOfDay(for: Date())
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                let startOfDate = calendar.startOfDay(for: date)
                let hasCompletions = completionDatesSet.contains(startOfDate)
                let isToday = startOfDate == today
                let isFuture = startOfDate > today

                days.append(CalendarDay(
                    date: startOfDate,
                    dayNumber: day,
                    hasCompletions: hasCompletions,
                    isToday: isToday,
                    isFuture: isFuture
                ))
            }
        }

        return days
    }

    // MARK: - Methods

    private func scrollToDate(_ date: Date) {
        guard let proxy = scrollProxy else { return }

        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)

        // Find the closest date in our sorted dates
        if sortedDates.contains(targetDate) {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(targetDate, anchor: .top)
            }
        } else {
            // Find the closest date after the selected date
            let closestDate = sortedDates.first { $0 <= targetDate }
            if let closest = closestDate {
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(closest, anchor: .top)
                }
            }
        }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day().year())
        }
    }
}

// MARK: - Calendar Day Model

private struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date?
    let dayNumber: Int
    var hasCompletions: Bool = false
    var isToday: Bool = false
    var isFuture: Bool = false
}

// MARK: - Calendar Day Cell

private struct CalendarDayCell: View {
    let day: CalendarDay
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                if day.date != nil {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 36, height: 36)

                    // Today outline
                    if day.isToday {
                        Circle()
                            .strokeBorder(Color.pureWhite, lineWidth: 2)
                            .frame(width: 36, height: 36)
                    }
                }

                // Day number
                if day.dayNumber > 0 {
                    Text("\(day.dayNumber)")
                        .font(.system(size: 15, weight: day.isToday ? .bold : .medium))
                        .foregroundStyle(textColor)
                }
            }
            .frame(height: 40)
        }
        .buttonStyle(.plain)
        .disabled(day.date == nil || day.isFuture || !day.hasCompletions)
    }

    private var backgroundColor: Color {
        if day.hasCompletions {
            return Color.recoveryGreen
        } else if day.isFuture {
            return Color.clear
        } else {
            return Color.darkGray2
        }
    }

    private var textColor: Color {
        if day.isFuture {
            return Color.darkGray2
        } else if day.hasCompletions {
            return Color.brandBlack
        } else {
            return Color.mediumGray
        }
    }
}

// MARK: - Preview

#Preview("With History") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TodoTask.self, TaskCompletion.self, CustomCategory.self, configurations: config)

    let task1 = TodoTask(title: "Morning meditation", category: "Health", isRecurring: true)
    let task2 = TodoTask(title: "Buy groceries", category: "Shopping")
    let task3 = TodoTask(title: "Team meeting", category: "Work")
    container.mainContext.insert(task1)
    container.mainContext.insert(task2)
    container.mainContext.insert(task3)

    // Add completions for various dates
    let calendar = Calendar.current
    for daysAgo in [0, 0, 1, 1, 2, 3, 5, 8, 10, 15, 20] {
        if let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()),
           let dateWithTime = calendar.date(bySettingHour: Int.random(in: 8...18), minute: Int.random(in: 0...59), second: 0, of: date) {
            let task = [task1, task2, task3].randomElement()!
            let completion = TaskCompletion(task: task, completedAt: dateWithTime)
            container.mainContext.insert(completion)
        }
    }

    return HistoryView()
        .modelContainer(container)
}

#Preview("Empty State") {
    HistoryView()
        .modelContainer(for: [TodoTask.self, TaskCompletion.self, CustomCategory.self], inMemory: true)
}

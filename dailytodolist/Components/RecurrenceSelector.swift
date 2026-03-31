//
//  RecurrenceSelector.swift
//  dailytodolist
//
//  Purpose: Recurrence selection component for task creation and editing
//  Features: Frequency type picker, weekday selector, month day selector
//

import SwiftUI
import UIKit

// MARK: - Recurrence Selector

/// Complete recurrence selection UI with type picker and day/date selectors
struct RecurrenceSelector: View {
    @Binding var recurrenceType: RecurrenceType
    @Binding var selectedWeekdays: [Int]
    @Binding var selectedMonthDays: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.section) {
            // Frequency type selector
            FrequencyTypeSelector(recurrenceType: $recurrenceType)

            // Show weekday selector for weekly recurrence
            if recurrenceType == .weekly {
                WeekdaySelector(selectedWeekdays: $selectedWeekdays)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Show month day selector for monthly recurrence
            if recurrenceType == .monthly {
                MonthDaySelector(selectedMonthDays: $selectedMonthDays)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: recurrenceType)
    }
}

// MARK: - Frequency Type Selector

/// Radio button selector for recurrence type (none, daily, weekly, monthly)
struct FrequencyTypeSelector: View {
    @Binding var recurrenceType: RecurrenceType

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("FREQUENCY")
                .font(.system(size: Typography.labelSize, weight: .bold))
                .foregroundStyle(Color.mediumGray)
                .tracking(1.0)

            VStack(spacing: 0) {
                ForEach(RecurrenceType.allCases, id: \.self) { type in
                    if type != RecurrenceType.allCases.first {
                        Divider()
                            .background(Color.darkGray2)
                    }

                    RecurrenceTypeOption(
                        type: type,
                        isSelected: recurrenceType == type
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            recurrenceType = type
                        }
                    }
                }
            }
            .background(Color.darkGray1)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        }
    }
}

// MARK: - Recurrence Type Option

/// Individual recurrence type option (radio style)
struct RecurrenceTypeOption: View {
    let type: RecurrenceType
    let isSelected: Bool
    let action: () -> Void

    @ObservedObject private var store = StoreKitService.shared
    @State private var showPaywall = false

    /// Premium features: weekly and monthly recurrence
    private var isPremiumFeature: Bool {
        type == .weekly || type == .monthly
    }

    /// Whether this option is locked behind Pro
    private var isLocked: Bool {
        isPremiumFeature && !store.isProUnlocked
    }

    var body: some View {
        Button(action: {
            if isLocked {
                showPaywall = true
            } else {
                action()
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            HStack(spacing: Spacing.md) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.recoveryGreen : Color.mediumGray, lineWidth: 2)
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(Color.recoveryGreen)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.sm) {
                        Text(type.displayName)
                            .font(.system(size: Typography.bodySize, weight: .medium))
                            .foregroundStyle(Color.pureWhite)

                        if let icon = type.icon {
                            Image(systemName: icon)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.performancePurple)
                        }

                        if isLocked {
                            ProBadge()
                        }
                    }

                    Text(type.subtitle)
                        .font(.system(size: Typography.captionSize, weight: .regular))
                        .foregroundStyle(Color.mediumGray)
                }

                Spacer()
            }
            .padding(Spacing.lg)
            .contentShape(Rectangle())
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Weekday Selector

/// Circular buttons for selecting weekdays (Sun-Sat)
struct WeekdaySelector: View {
    @Binding var selectedWeekdays: [Int]

    // Weekday data: (Calendar weekday value, short name)
    private let weekdays: [(value: Int, name: String)] = [
        (1, "S"),  // Sunday
        (2, "M"),  // Monday
        (3, "T"),  // Tuesday
        (4, "W"),  // Wednesday
        (5, "T"),  // Thursday
        (6, "F"),  // Friday
        (7, "S")   // Saturday
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("SELECT DAYS")
                .font(.system(size: Typography.labelSize, weight: .bold))
                .foregroundStyle(Color.mediumGray)
                .tracking(1.0)

            HStack(spacing: Spacing.sm) {
                ForEach(weekdays, id: \.value) { weekday in
                    WeekdayButton(
                        label: weekday.name,
                        isSelected: selectedWeekdays.contains(weekday.value)
                    ) {
                        toggleWeekday(weekday.value)
                    }
                }
            }
        }
    }

    private func toggleWeekday(_ value: Int) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if selectedWeekdays.contains(value) {
                selectedWeekdays.removeAll { $0 == value }
            } else {
                selectedWeekdays.append(value)
                selectedWeekdays.sort()
            }
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Weekday Button

/// Individual weekday toggle button
struct WeekdayButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: Typography.bodySize, weight: .semibold))
                .foregroundStyle(isSelected ? Color.pureWhite : Color.mediumGray)
                .frame(width: 40, height: 40)
                .background(isSelected ? Color.recoveryGreen : Color.darkGray1)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.recoveryGreen : Color.darkGray2, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Month Day Selector

/// Grid of buttons for selecting month days (1-31)
struct MonthDaySelector: View {
    @Binding var selectedMonthDays: [Int]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("SELECT DATES")
                .font(.system(size: Typography.labelSize, weight: .bold))
                .foregroundStyle(Color.mediumGray)
                .tracking(1.0)

            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(1...31, id: \.self) { day in
                    MonthDayButton(
                        day: day,
                        isSelected: selectedMonthDays.contains(day)
                    ) {
                        toggleMonthDay(day)
                    }
                }
            }
        }
    }

    private func toggleMonthDay(_ day: Int) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if selectedMonthDays.contains(day) {
                selectedMonthDays.removeAll { $0 == day }
            } else {
                selectedMonthDays.append(day)
                selectedMonthDays.sort()
            }
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Month Day Button

/// Individual month day toggle button
struct MonthDayButton: View {
    let day: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(day)")
                .font(.system(size: Typography.captionSize, weight: .semibold))
                .foregroundStyle(isSelected ? Color.pureWhite : Color.mediumGray)
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.recoveryGreen : Color.darkGray1)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.recoveryGreen : Color.darkGray2, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Recurrence Selector") {
    struct PreviewWrapper: View {
        @State private var recurrenceType: RecurrenceType = .weekly
        @State private var selectedWeekdays: [Int] = [2, 4, 6]  // Mon, Wed, Fri
        @State private var selectedMonthDays: [Int] = [1, 15]

        var body: some View {
            ZStack {
                Color.brandBlack.ignoresSafeArea()
                ScrollView {
                    RecurrenceSelector(
                        recurrenceType: $recurrenceType,
                        selectedWeekdays: $selectedWeekdays,
                        selectedMonthDays: $selectedMonthDays
                    )
                    .padding(Spacing.xl)
                }
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Frequency Types") {
    struct PreviewWrapper: View {
        @State private var recurrenceType: RecurrenceType = .none

        var body: some View {
            ZStack {
                Color.brandBlack.ignoresSafeArea()
                FrequencyTypeSelector(recurrenceType: $recurrenceType)
                    .padding(Spacing.xl)
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Weekday Selector") {
    struct PreviewWrapper: View {
        @State private var selectedWeekdays: [Int] = [2, 4, 6]

        var body: some View {
            ZStack {
                Color.brandBlack.ignoresSafeArea()
                WeekdaySelector(selectedWeekdays: $selectedWeekdays)
                    .padding(Spacing.xl)
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Month Day Selector") {
    struct PreviewWrapper: View {
        @State private var selectedMonthDays: [Int] = [1, 15]

        var body: some View {
            ZStack {
                Color.brandBlack.ignoresSafeArea()
                MonthDaySelector(selectedMonthDays: $selectedMonthDays)
                    .padding(Spacing.xl)
            }
        }
    }

    return PreviewWrapper()
}

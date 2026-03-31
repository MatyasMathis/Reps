//
//  Cards.swift
//  Reps
//
//  Purpose: Reusable card components with Whoop styling
//

import SwiftUI

// MARK: - Daily Progress Card

/// Shows daily task completion progress
struct DailyProgressCard: View {
    let completed: Int
    let total: Int

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    private var percentageText: String {
        guard total > 0 else { return "0%" }
        return "\(Int(percentage * 100))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Label
            Text("DAILY RHYTHM")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.pureWhite.opacity(0.45))
                .tracking(1.5)

            // Numbers + percentage row
            HStack(alignment: .center) {
                // Big number left
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%02d", completed))
                        .font(.system(size: 72, weight: .black))
                        .italic()
                        .foregroundStyle(Color.pureWhite)
                        .monospacedDigit()

                    Text("/\(String(format: "%02d", total))")
                        .font(.system(size: 72, weight: .black))
                        .italic()
                        .foregroundStyle(Color.pureWhite.opacity(0.2))
                        .monospacedDigit()
                }

                Spacer()

                // Percentage right
                Text(percentageText)
                    .font(.system(size: 42, weight: .black))
                    .italic()
                    .foregroundStyle(Color.recoveryGreen)
                    .monospacedDigit()
            }

            // "LOCKED IN" sublabel
            Text("LOCKED IN")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.pureWhite.opacity(0.45))
                .tracking(1.5)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.pureWhite.opacity(0.08))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.recoveryGreen)
                        .frame(width: max(geometry.size.width * percentage, percentage > 0 ? 8 : 0), height: 4)
                        .animation(.easeInOut(duration: 0.5), value: percentage)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.lg)
        .background(
            ZStack {
                Color(hex: "141414")
                RadialGradient(
                    colors: [Color.recoveryGreen.opacity(0.18), Color.clear],
                    center: UnitPoint(x: 1.05, y: -0.05),
                    startRadius: 0,
                    endRadius: 220
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Task Card Container

/// Container styling for task cards
struct TaskCardContainer<Content: View>: View {
    let content: Content
    var isCompleted: Bool = false

    init(isCompleted: Bool = false, @ViewBuilder content: () -> Content) {
        self.isCompleted = isCompleted
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, 14)
            .background(Color.darkGray1)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
            .opacity(isCompleted ? 0.6 : 1.0)
    }
}

// MARK: - Empty State Card

/// Empty state display for lists
struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(Color.mediumGray)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.system(size: Typography.h2Size, weight: .bold))
                    .foregroundStyle(Color.pureWhite)

                Text(subtitle)
                    .font(.system(size: Typography.bodySize, weight: .regular))
                    .foregroundStyle(Color.mediumGray)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.primary)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xxl)
    }
}

// MARK: - Section Header

/// Styled section header for lists
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: Typography.captionSize, weight: .bold))
            .foregroundStyle(Color.mediumGray)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.brandBlack)
    }
}

// MARK: - Preview

#Preview("Cards") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            DailyProgressCard(completed: 4, total: 8)

            DailyProgressCard(completed: 0, total: 5)

            DailyProgressCard(completed: 10, total: 10)

            TaskCardContainer {
                HStack {
                    CheckboxButton(isChecked: false) {}
                    Text("Sample Task")
                        .foregroundStyle(Color.pureWhite)
                    Spacer()
                }
            }

            TaskCardContainer(isCompleted: true) {
                HStack {
                    CheckboxButton(isChecked: true) {}
                    Text("Completed Task")
                        .foregroundStyle(Color.pureWhite)
                        .strikethrough()
                    Spacer()
                }
            }

            EmptyStateCard(
                icon: "checklist",
                title: "Your day is a blank canvas.",
                subtitle: "What are you going to crush?",
                actionTitle: "Add Task"
            ) {}
        }
        .padding(Spacing.lg)
    }
    .background(Color.brandBlack)
}

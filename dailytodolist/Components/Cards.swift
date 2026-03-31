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
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Label
            Text("DAILY PROGRESS")
                .font(.system(size: Typography.labelSize, weight: .semibold))
                .foregroundStyle(Color.pureWhite.opacity(0.5))
                .tracking(0.8)

            // Stats row
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(completed)/\(total)")
                        .font(.system(size: Typography.h2Size + 4, weight: .bold))
                        .foregroundStyle(Color.pureWhite)
                    Text("completed")
                        .font(.system(size: Typography.captionSize + 1, weight: .medium))
                        .foregroundStyle(Color.pureWhite.opacity(0.5))
                }

                Spacer()

                Text(percentageText)
                    .font(.system(size: Typography.h2Size + 4, weight: .bold))
                    .foregroundStyle(Color.recoveryGreen)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 6)

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.recoveryGreen)
                        .frame(width: geometry.size.width * percentage, height: 6)
                        .animation(.easeInOut(duration: 0.5), value: percentage)
                }
            }
            .frame(height: 6)
        }
        .padding(Spacing.xl)
        .background(
            ZStack {
                // Base dark color
                Color(hex: "0D1F19")
                // Green radial glow from bottom-right
                RadialGradient(
                    colors: [
                        Color.recoveryGreen.opacity(0.25),
                        Color.clear
                    ],
                    center: UnitPoint(x: 1.1, y: 1.2),
                    startRadius: 0,
                    endRadius: 200
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .shadowLevel1()
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

//
//  HistoryRow.swift
//  Reps
//
//  Purpose: Individual row component for completed tasks with Whoop-inspired design
//  Design: Dark card styling with green checkmark and time badge
//

import SwiftUI
import SwiftData

/// A row view displaying a single completion record
struct HistoryRow: View {

    // MARK: - Properties

    let completion: TaskCompletion

    @Query(sort: \CustomCategory.sortOrder)
    private var customCategories: [CustomCategory]

    // MARK: - Computed Properties

    private var formattedTime: String {
        completion.completedAt.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Checkmark — rounded square matching CheckboxButton style
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.recoveryGreen)
                    .frame(width: 30, height: 30)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color.brandBlack)
            }

            // Task Info
            VStack(alignment: .leading, spacing: 4) {
                if let task = completion.task {
                    Text(task.title)
                        .font(.system(size: Typography.h4Size, weight: .bold))
                        .italic()
                        .foregroundStyle(Color.pureWhite)

                    // Inline badges — time • category • recurrence
                    HStack(spacing: 6) {
                        Text(formattedTime)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.mediumGray)

                        if let category = task.category, !category.isEmpty {
                            Text("•")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.mediumGray.opacity(0.4))
                            Text(category.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.categoryColor(for: category, customCategories: customCategories))
                        }

                        if task.recurrenceType != .none {
                            Text("•")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.mediumGray.opacity(0.4))
                            Text(task.recurrenceDisplayString.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.performancePurple)
                        }
                    }
                } else {
                    Text("Completed Task")
                        .font(.system(size: Typography.h4Size, weight: .bold))
                        .italic()
                        .foregroundStyle(Color.mediumGray)
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, 14)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.brandBlack.ignoresSafeArea()
        VStack(spacing: Spacing.sm) {
            Text("History Row Preview")
                .foregroundStyle(Color.pureWhite)
        }
        .padding(Spacing.lg)
    }
}

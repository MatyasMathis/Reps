//
//  MediumWidgetView.swift
//  TodayTasksWidget
//
//  Purpose: Medium 4x2 widget — snapshot view with progress and quick stats.
//  Design: SNAPSHOT — left big %, right two info cards (next up + streak)
//

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: TaskEntry

    private var percentage: Double {
        guard entry.totalCount > 0 else { return 0 }
        return Double(entry.completedCount) / Double(entry.totalCount)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Left column: REPS label + big % + progress bar
            VStack(alignment: .leading, spacing: 0) {
                Text("REPS")
                    .font(.system(size: 11, weight: .black))
                    .italic()
                    .foregroundStyle(Color.widgetRecoveryGreen)
                    .tracking(1.5)

                Spacer()

                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 58, weight: .black))
                    .italic()
                    .foregroundStyle(Color.widgetPureWhite)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Spacer(minLength: 10)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.widgetDarkGray2)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.widgetRecoveryGreen)
                            .frame(width: geo.size.width * percentage)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)

            // Right column: two info cards
            VStack(spacing: 8) {
                // Next up
                if let nextTask = entry.tasks.first {
                    MediumInfoCard(
                        icon: "checkmark.circle.fill",
                        iconColor: .widgetRecoveryGreen,
                        title: nextTask.title,
                        subtitle: "NEXT UP"
                    )
                } else {
                    MediumInfoCard(
                        icon: "checkmark.circle.fill",
                        iconColor: .widgetRecoveryGreen,
                        title: "All done!",
                        subtitle: "NEXT UP"
                    )
                }

                // Current streak
                MediumInfoCard(
                    icon: "flame.fill",
                    iconColor: .widgetPersonalOrange,
                    title: "\(String(format: "%02d", entry.currentStreak)) Days",
                    subtitle: "CURRENT STREAK"
                )
            }
            .frame(width: 155)
        }
        .widgetURL(URL(string: "reps://tasks"))
    }
}

// MARK: - Info Card

private struct MediumInfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .italic()
                    .foregroundStyle(Color.widgetPureWhite)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.widgetMediumGray)
                    .tracking(0.5)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.widgetDarkGray1)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

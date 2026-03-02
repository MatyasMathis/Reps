//
//  SmallWidgetView.swift
//  TodayTasksWidget
//
//  Purpose: Small widget view showing circular progress indicator.
//

import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: TaskEntry

    private var percentage: Double {
        guard entry.totalCount > 0 else { return 0 }
        return Double(entry.completedCount) / Double(entry.totalCount)
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("DAILY PROGRESS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.widgetMediumGray)
                Spacer()
            }

            Spacer()

            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.widgetDarkGray2, lineWidth: 6)

                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(
                        Color.widgetRecoveryGreen,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(entry.completedCount)/\(entry.totalCount)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.widgetPureWhite)
                }
            }
            .frame(width: 70, height: 70)

            Spacer()

            // Percentage
            Text("\(Int(percentage * 100))% complete")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.widgetRecoveryGreen)
        }
        .widgetURL(URL(string: "reps://tasks"))
    }
}

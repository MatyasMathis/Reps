//
//  MediumWidgetView.swift
//  TodayTasksWidget
//
//  Purpose: Medium widget view showing progress bar and 3 tasks.
//

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: TaskEntry

    private var percentage: Double {
        guard entry.totalCount > 0 else { return 0 }
        return Double(entry.completedCount) / Double(entry.totalCount)
    }

    private var displayTasks: [WidgetTask] {
        Array(entry.tasks.prefix(2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row
            HStack {
                Text("DAILY PROGRESS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.widgetMediumGray)


                Spacer()

                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.widgetPureWhite)

                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.widgetRecoveryGreen)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.widgetDarkGray2)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.widgetRecoveryGreen)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 6)

            // Task list
            if displayTasks.isEmpty {
                HStack {
                    Spacer()
                    Text("All done for today!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.widgetMediumGray)
                    Spacer()
                }
                .padding(.top, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(displayTasks) { task in
                        WidgetTaskRow(task: task, compact: true)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .widgetURL(URL(string: "reps://tasks"))
    }
}

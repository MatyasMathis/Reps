//
//  LargeWidgetView.swift
//  TodayTasksWidget
//
//  Purpose: Large widget view showing progress card and up to 5 tasks.
//

import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: TaskEntry

    private var percentage: Double {
        guard entry.totalCount > 0 else { return 0 }
        return Double(entry.completedCount) / Double(entry.totalCount)
    }

    private var displayTasks: [WidgetTask] {
        Array(entry.tasks.prefix(5))
    }

    private var remainingCount: Int {
        max(0, entry.tasks.count - 5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Progress card
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("DAILY PROGRESS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.widgetMediumGray)


                    Spacer()
                }

                HStack {
                    Text("\(entry.completedCount)/\(entry.totalCount) completed")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.widgetPureWhite)

                    Spacer()

                    Text("\(Int(percentage * 100))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.widgetRecoveryGreen)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.widgetDarkGray2)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.widgetRecoveryGreen)
                            .frame(width: geometry.size.width * percentage)
                    }
                }
                .frame(height: 6)
            }
            .padding(10)
            .background(Color.widgetDarkGray1)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Task list
            if displayTasks.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.widgetRecoveryGreen)
                        Text("All done for today!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.widgetMediumGray)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                VStack(spacing: 6) {
                    ForEach(displayTasks) { task in
                        WidgetTaskRow(task: task, compact: false)
                    }
                }

                if remainingCount > 0 {
                    Text("+ \(remainingCount) more task\(remainingCount == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.widgetMediumGray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .widgetURL(URL(string: "reps://tasks"))
    }
}

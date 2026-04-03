//
//  LargeWidgetView.swift
//  TodayTasksWidget
//
//  Purpose: Large 4x4 widget — rhythm tracker with task list.
//  Design: RHYTHM TRACKER — header, X/Y Completed + %, progress bar, task rows
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
        Array(entry.tasks.prefix(4))
    }

    private var remainingCount: Int {
        max(0, entry.tasks.count - 4)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section label
            Text("DAILY RHYTHM")
                .font(.system(size: 11, weight: .black))
                .italic()
                .foregroundStyle(Color.widgetMediumGray)
                .tracking(1.5)

            // Completion count + percentage
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(entry.completedCount)/\(entry.totalCount)")
                        .font(.system(size: 34, weight: .black))
                        .italic()
                        .foregroundStyle(Color.widgetPureWhite)
                        .monospacedDigit()
                    Text(" Completed")
                        .font(.system(size: 17, weight: .semibold))
                        .italic()
                        .foregroundStyle(Color.widgetRecoveryGreen)
                }

                Spacer()

                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 34, weight: .black))
                    .italic()
                    .foregroundStyle(Color.widgetRecoveryGreen)
                    .monospacedDigit()
            }
            .padding(.top, 6)

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
            .frame(height: 6)
            .padding(.top, 10)

            // Task list
            if displayTasks.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.widgetRecoveryGreen)
                        Text("All done for today!")
                            .font(.system(size: 14, weight: .semibold))
                            .italic()
                            .foregroundStyle(Color.widgetMediumGray)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                VStack(spacing: 8) {
                    ForEach(displayTasks) { task in
                        WidgetTaskRow(task: task)
                    }
                }
                .padding(.top, 14)

                if remainingCount > 0 {
                    Text("+ \(remainingCount) more")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.widgetMediumGray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }

            Spacer(minLength: 0)
        }
        .widgetURL(URL(string: "reps://tasks"))
    }
}

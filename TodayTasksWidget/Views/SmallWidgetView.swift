//
//  SmallWidgetView.swift
//  TodayTasksWidget
//
//  Purpose: Small 2x2 widget — minimal percentage view with progress bar.
//  Design: MINIMAL — flame icon, REPS label, big bold italic %, green bar
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
        VStack(alignment: .leading, spacing: 0) {
            // Top row: flame icon + REPS label
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.widgetDarkGray1)
                        .frame(width: 30, height: 30)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.widgetPersonalOrange)
                }

                Text("REPS")
                    .font(.system(size: 12, weight: .black))
                    .italic()
                    .foregroundStyle(Color.widgetPureWhite)
                    .tracking(1.5)

                Spacer()
            }

            Spacer()

            // Big percentage
            Text("\(Int(percentage * 100))%")
                .font(.system(size: 52, weight: .black))
                .italic()
                .foregroundStyle(Color.widgetPureWhite)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
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
        .widgetURL(URL(string: "reps://tasks"))
    }
}

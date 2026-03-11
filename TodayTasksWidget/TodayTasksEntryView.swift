//
//  TodayTasksEntryView.swift
//  TodayTasksWidget
//
//  Purpose: Routes to the appropriate widget view based on widget size.
//

import SwiftUI
import WidgetKit

struct TodayTasksEntryView: View {
    var entry: TaskEntry

    @Environment(\.widgetFamily) var family

    // Read the user's theme preference from the shared App Group store so the
    // widget respects the in-app dark/light toggle rather than the system setting.
    @AppStorage("isDarkMode", store: UserDefaults(suiteName: "group.com.mathis.reps"))
    private var isDarkMode: Bool = true

    var body: some View {
        content
            .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
                .padding(16)
        case .systemMedium:
            MediumWidgetView(entry: entry)
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
        case .systemLarge:
            LargeWidgetView(entry: entry)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
        default:
            SmallWidgetView(entry: entry)
                .padding(16)
        }
    }
}

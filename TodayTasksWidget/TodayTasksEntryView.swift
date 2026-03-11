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
            .containerBackground(for: .widget) {
                // Directly use the stored flag so the background color
                // matches the in-app dark/light preference.
                isDarkMode ? Color(hex: "0A0A0A") : Color(hex: "F2F2F7")
            }
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

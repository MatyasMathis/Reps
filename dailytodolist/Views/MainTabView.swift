//
//  MainTabView.swift
//  Reps
//
//  Purpose: Root view with compact pill toggle navigation
//  Design: Centered capsule toggle with sliding indicator
//

import SwiftUI
import SwiftData

/// Root view with compact pill toggle navigation
///
/// Features:
/// - Centered floating pill toggle
/// - Sliding capsule indicator
/// - Haptic feedback on tab switch
/// - Modern compact design
struct MainTabView: View {

    // MARK: - State

    @State private var selectedTab: Tab = .today
    @Namespace private var animation

    // MARK: - Init

    init() {
        // Set hidden tab bar background to match the app theme
        // Prevents grey bleed-through when scrolling to the bottom
        // Uses UIColor.systemBackground so it adapts to both light and dark modes
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    // MARK: - Tab Enum

    enum Tab: CaseIterable {
        case today
        case history

        var label: String {
            switch self {
            case .today: return "Today"
            case .history: return "History"
            }
        }

        var icon: String {
            switch self {
            case .today: return "checkmark.circle"
            case .history: return "clock.arrow.circlepath"
            }
        }

        var iconFilled: String {
            switch self {
            case .today: return "checkmark.circle.fill"
            case .history: return "clock.arrow.circlepath"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            TabView(selection: $selectedTab) {
                TaskListView()
                    .toolbar(.hidden, for: .tabBar)
                    .tag(Tab.today)

                HistoryView()
                    .toolbar(.hidden, for: .tabBar)
                    .tag(Tab.history)
            }
            .background(Color.brandBlack.ignoresSafeArea())

            // Compact Pill Toggle
            pillToggle
                .padding(.bottom, Spacing.lg)
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTasks)) { _ in
            withAnimation {
                selectedTab = .today
            }
        }
    }

    // MARK: - Pill Toggle

    private var pillToggle: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(tab: tab)
            }
        }
        .padding(Spacing.xs)
        .background(
            Capsule()
                .fill(Color.darkGray1)
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Tab Button

    private func tabButton(tab: Tab) -> some View {
        Button {
            HapticService.lightImpact()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: selectedTab == tab ? tab.iconFilled : tab.icon)
                    .font(.system(size: 16, weight: .semibold))

                Text(tab.label)
                    .font(.system(size: Typography.bodySize, weight: .semibold))
                    .fixedSize()
            }
            .foregroundStyle(selectedTab == tab ? Color.brandBlack : Color.mediumGray)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background {
                if selectedTab == tab {
                    Capsule()
                        .fill(Color.recoveryGreen)
                        .matchedGeometryEffect(id: "indicator", in: animation)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [TodoTask.self, TaskCompletion.self, CustomCategory.self], inMemory: true)
}

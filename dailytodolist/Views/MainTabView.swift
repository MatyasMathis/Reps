//
//  MainTabView.swift
//  Reps
//
//  Purpose: Root view with one NavigationStack and compact pill toggle navigation
//  Design: Single nav bar (no dual-stack flash), single sliding pill indicator
//

import SwiftUI
import SwiftData

/// Root view managing the single NavigationStack and two permanently-mounted tab views.
///
/// Architecture notes:
/// - ONE NavigationStack at this level. TaskListView / HistoryView contain plain ZStack
///   content with no NavigationStack. This eliminates the UIKit dual-nav-controller race
///   that caused the navigation bar background to flash when switching tabs.
/// - Both tab views stay permanently mounted (opacity toggle) so their SwiftData
///   @Query contexts and scroll positions are never torn down.
/// - Pill indicator is a SINGLE Capsule that slides between button positions via
///   PreferenceKey measurement — no crossfade artifact from two overlapping capsules.
struct MainTabView: View {

    // MARK: - State

    @State private var selectedTab: Tab = .today

    // Pro glimpse — history tab first-visit nudge
    @ObservedObject private var storeService = StoreKitService.shared
    @State private var showHistoryProGlimpse = false
    @State private var showHistoryPaywall = false

    // Sheets owned at the nav-bar level
    @State private var showSettings = false
    @State private var showYearInPixels = false
    @State private var showStats = false

    // Single sliding pill indicator positioning
    @State private var tabButtonFrames: [Tab: CGRect] = [:]

    // MARK: - Queries

    @Query(sort: \TaskCompletion.completedAt, order: .reverse)
    private var allCompletions: [TaskCompletion]

    // MARK: - Init

    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.brandBlack)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Global fallback — keeps bar black even before SwiftUI toolbar modifiers fire.
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Color.brandBlack)
        navBarAppearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = navBarAppearance
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

    // MARK: - Computed Properties

    /// Streak from allCompletions — displayed in the Today toolbar badge.
    private var currentStreak: Int {
        let calendar = Calendar.current
        let completionDays = Set(allCompletions.map { calendar.startOfDay(for: $0.completedAt) })
        guard !completionDays.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        if !completionDays.contains(checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            if !completionDays.contains(yesterday) { return 0 }
            checkDate = yesterday
        }

        while completionDays.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        return streak
    }

    private var formattedDate: String {
        Date().formatted(.dateTime.month(.abbreviated).day())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Tab content — both permanently mounted, only opacity toggles.
                // No NavigationStack inside either view, so there is exactly
                // one UINavigationController in the hierarchy → no bar flash.
                ZStack {
                    TaskListView()
                        .opacity(selectedTab == .today ? 1 : 0)
                        .transaction { $0.animation = nil }
                        .allowsHitTesting(selectedTab == .today)

                    HistoryView()
                        .opacity(selectedTab == .history ? 1 : 0)
                        .transaction { $0.animation = nil }
                        .allowsHitTesting(selectedTab == .history)
                }
                .background(Color.brandBlack.ignoresSafeArea())

                // Compact Pill Toggle
                pillToggle
                    .padding(.bottom, Spacing.lg)
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Leading: settings gear (today) or nothing (history)
                ToolbarItem(placement: .topBarLeading) {
                    Group {
                        if selectedTab == .today {
                            Button { showSettings = true } label: {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.mediumGray)
                                    .frame(width: 36, height: 36)
                                    .background(Color.darkGray1)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .transaction { $0.animation = nil }
                }

                // Trailing: date+streak (today) or Stats pill (history)
                ToolbarItem(placement: .topBarTrailing) {
                    Group {
                        if selectedTab == .today {
                            Button { showYearInPixels = true } label: {
                                HStack(spacing: Spacing.xs) {
                                    Text(formattedDate.uppercased())
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color.pureWhite.opacity(0.7))

                                    if currentStreak > 0 {
                                        ZStack {
                                            Capsule()
                                                .fill(Color(hex: "5C3800"))
                                                .frame(width: 40, height: 22)
                                            HStack(spacing: 3) {
                                                Image(systemName: "flame.fill")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundStyle(Color.personalOrange)
                                                Text("\(currentStreak)")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(Color.pureWhite)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.darkGray1)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        } else {
                            // Stats pill
                            Button { showStats = true } label: {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("STATS")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(Color.recoveryGreen)
                            }
                        }
                    }
                    .transaction { $0.animation = nil }
                }
            }
            .toolbarBackground(Color.brandBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onReceive(NotificationCenter.default.publisher(for: .navigateToTasks)) { _ in
                selectedTab = .today
            }
            .onChange(of: selectedTab) { _, newTab in
                guard newTab == .history else { return }
                guard !storeService.isProUnlocked else { return }
                guard !ProNudgeService.shared.hasSeenHistoryNudge else { return }
                guard ProNudgeService.shared.canShow else { return }

                ProNudgeService.shared.hasSeenHistoryNudge = true
                ProNudgeService.shared.markShown()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showHistoryProGlimpse = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                        withAnimation { showHistoryProGlimpse = false }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showHistoryProGlimpse && selectedTab == .history {
                    ProGlimpseCard(
                        variant: .historyTab,
                        onUnlock: {
                            withAnimation { showHistoryProGlimpse = false }
                            showHistoryPaywall = true
                        },
                        onDismiss: {
                            withAnimation { showHistoryProGlimpse = false }
                        }
                    )
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
                }
            }
            .fullScreenCover(isPresented: $showHistoryPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $showYearInPixels) {
                YearInPixelsView()
            }
            .sheet(isPresented: $showStats) {
                StatsView()
            }
        }
    }

    // MARK: - Pill Toggle

    /// Pill toggle with a SINGLE sliding green indicator measured via PreferenceKey.
    /// The indicator is one Capsule that moves — no two-capsule crossfade flash.
    private var pillToggle: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(tab: tab)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: TabButtonFrameKey.self,
                                value: [tab: geo.frame(in: .named("pillSpace"))]
                            )
                        }
                    )
            }
        }
        .padding(Spacing.xs)
        .background { pillBackground }
        .coordinateSpace(name: "pillSpace")
        .onPreferenceChange(TabButtonFrameKey.self) { frames in
            tabButtonFrames = frames
        }
    }

    /// Layered background: dark pill base + single sliding green indicator.
    private var pillBackground: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Dark pill base
                Capsule()
                    .fill(Color.darkGray1)
                    .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
                    .frame(width: geo.size.width, height: geo.size.height)

                // One indicator capsule, positioned at the selected button's frame
                if let frame = tabButtonFrames[selectedTab], frame != .zero {
                    Capsule()
                        .fill(Color.recoveryGreen)
                        .frame(width: frame.width, height: frame.height)
                        .offset(x: frame.minX, y: frame.minY)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.8),
                            value: selectedTab
                        )
                }
            }
        }
    }

    // MARK: - Tab Button

    private func tabButton(tab: Tab) -> some View {
        Button {
            HapticService.lightImpact()
            selectedTab = tab
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
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preference Key

/// Collects each tab button's frame in the pill's coordinate space.
private struct TabButtonFrameKey: PreferenceKey {
    typealias Value = [MainTabView.Tab: CGRect]
    static var defaultValue: [MainTabView.Tab: CGRect] = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [TodoTask.self, TaskCompletion.self, CustomCategory.self], inMemory: true)
}

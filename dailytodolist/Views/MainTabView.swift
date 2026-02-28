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

    // Pro glimpse — history tab first-visit nudge
    @ObservedObject private var storeService = StoreKitService.shared
    @State private var showHistoryProGlimpse = false
    @State private var showHistoryPaywall = false

    // MARK: - Init

    init() {
        // Set hidden tab bar background to match the app theme
        // Prevents grey bleed-through when scrolling to the bottom
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.brandBlack)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Set navigation bar background globally to prevent white flash when
        // switching tabs quickly. Without this, the system default white
        // background briefly bleeds through before the per-view .toolbarBackground
        // modifier is applied on the incoming tab's NavigationStack.
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

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            //
            // Use a plain ZStack with opacity instead of TabView so that
            // switching tabs never triggers a UIKit UITabBarController view-
            // controller swap. That swap is what causes the white background
            // flash: UIKit briefly resets the UINavigationBar to its default
            // appearance before SwiftUI's .toolbarBackground modifier can
            // re-apply the dark colour. By keeping both views permanently
            // mounted and only toggling opacity, the NavigationStack (and its
            // underlying UINavigationController) is never torn down or
            // re-presented — the nav bar colour stays consistent at all times.
            ZStack {
                TaskListView()
                    .opacity(selectedTab == .today ? 1 : 0)
                    // Disable inherited animation so the content snap is instant
                    // (the pill indicator still animates via matchedGeometryEffect).
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
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTasks)) { _ in
            withAnimation {
                selectedTab = .today
            }
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
        .sheet(isPresented: $showHistoryPaywall) {
            PaywallView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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

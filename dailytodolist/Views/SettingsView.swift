//
//  SettingsView.swift
//  Reps
//
//  Purpose: App settings screen with sound, haptic, and info controls
//  Design: Dark theme with grouped sections matching Whoop aesthetic
//

import SwiftUI

/// Settings screen presented as a sheet from the main task list
struct SettingsView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Persisted Preferences

    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("notificationHour") private var notificationHour: Int = 8
    @AppStorage("notificationMinute") private var notificationMinute: Int = 0
    @AppStorage("isDarkMode", store: UserDefaults(suiteName: "group.com.mathis.reps"))
    private var isDarkMode: Bool = true

    // MARK: - Store

    @ObservedObject private var store = StoreKitService.shared

    // MARK: - Sheet State

    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showPaywall = false
    @State private var showNotificationDeniedAlert = false

    // MARK: - Computed

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xxl) {
                        appInfoSection
                        proStatusSection
                        cloudSyncSection
                        notificationsSection
                        appearanceSection
                        generalSection
                        dataSection
                        aboutSection
                        #if DEBUG
                        debugSection
                        #endif
                        footerSection
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: Typography.h3Size, weight: .bold))
                        .foregroundStyle(Color.pureWhite)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.mediumGray)
                            .frame(width: 30, height: 30)
                            .background(Color.darkGray2)
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarBackground(Color.brandBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .presentationBackground(Color.brandBlack)
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(spacing: Spacing.sm) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text("REPS")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .tracking(3)
                .foregroundStyle(Color.pureWhite)

            Text("Lock in.")
                .font(.system(size: Typography.bodySize, weight: .medium))
                .foregroundStyle(Color.mediumGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }

    // MARK: - PRO Status Section

    private var proStatusSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("STATUS")

            Button {
                if !store.isProUnlocked {
                    showPaywall = true
                }
            } label: {
                HStack {
                    Image(systemName: store.isProUnlocked ? "crown.fill" : "crown")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(store.isProUnlocked ? Color.recoveryGreen : Color.mediumGray)

                    Text(store.isProUnlocked ? "REPS Pro" : "Free Plan")
                        .font(.system(size: Typography.bodySize, weight: .medium))
                        .foregroundStyle(Color.pureWhite)

                    Spacer()

                    if store.isProUnlocked {
                        Text("PRO")
                            .font(.system(size: Typography.captionSize, weight: .bold))
                            .foregroundStyle(Color.onAccent)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.recoveryGreen)
                            .clipShape(Capsule())
                    } else {
                        Text("UPGRADE")
                            .font(.system(size: Typography.captionSize, weight: .bold))
                            .foregroundStyle(Color.onAccent)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.recoveryGreen)
                            .clipShape(Capsule())
                    }
                }
                .padding(Spacing.lg)
                .background(Color.darkGray1)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Cloud Sync Section

    @ViewBuilder
    private var cloudSyncSection: some View {
        if store.isProUnlocked {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                sectionLabel("CLOUD SYNC")

                let isActive = UserDefaults.standard.bool(forKey: "cloudKitActiveOnLaunch")

                HStack(spacing: Spacing.md) {
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.recoveryGreen)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Sync")
                            .font(.system(size: Typography.bodySize, weight: .medium))
                            .foregroundStyle(Color.pureWhite)

                        Text("Tasks sync across all your Apple devices")
                            .font(.system(size: Typography.captionSize, weight: .regular))
                            .foregroundStyle(Color.mediumGray)
                    }

                    Spacer()

                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(isActive ? Color.recoveryGreen : Color.mediumGray)
                            .frame(width: 7, height: 7)

                        Text(isActive ? "Active" : "Restart required")
                            .font(.system(size: Typography.captionSize, weight: .medium))
                            .foregroundStyle(isActive ? Color.recoveryGreen : Color.mediumGray)
                    }
                }
                .padding(Spacing.lg)
                .background(Color.darkGray1)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("NOTIFICATIONS")

            VStack(spacing: 0) {
                // Daily reminder toggle
                HStack(spacing: Spacing.md) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.recoveryGreen)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminder")
                            .font(.system(size: Typography.bodySize, weight: .medium))
                            .foregroundStyle(Color.pureWhite)

                        Text("Get a nudge to complete your tasks")
                            .font(.system(size: Typography.captionSize, weight: .regular))
                            .foregroundStyle(Color.mediumGray)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { notificationsEnabled },
                        set: { enabled in
                            if enabled {
                                Task {
                                    let granted = await NotificationService.shared.requestPermission()
                                    if granted {
                                        notificationsEnabled = true
                                        NotificationService.shared.scheduleReminder(
                                            hour: notificationHour,
                                            minute: notificationMinute
                                        )
                                    } else {
                                        notificationsEnabled = false
                                        showNotificationDeniedAlert = true
                                    }
                                }
                            } else {
                                notificationsEnabled = false
                                NotificationService.shared.cancelReminder()
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(Color.recoveryGreen)
                }
                .padding(Spacing.lg)

                // Time picker — only visible when notifications are enabled
                if notificationsEnabled {
                    Divider()
                        .background(Color.darkGray2)

                    HStack(spacing: Spacing.md) {
                        Image(systemName: "clock")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.recoveryGreen)
                            .frame(width: 24)

                        Text("Reminder Time")
                            .font(.system(size: Typography.bodySize, weight: .medium))
                            .foregroundStyle(Color.pureWhite)

                        Spacer()

                        DatePicker(
                            "",
                            selection: Binding(
                                get: {
                                    Calendar.current.date(
                                        bySettingHour: notificationHour,
                                        minute: notificationMinute,
                                        second: 0,
                                        of: Date()
                                    ) ?? Date()
                                },
                                set: { newDate in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                    notificationHour = components.hour ?? 8
                                    notificationMinute = components.minute ?? 0
                                    NotificationService.shared.scheduleReminder(
                                        hour: notificationHour,
                                        minute: notificationMinute
                                    )
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                    .padding(Spacing.lg)
                }
            }
            .background(Color.darkGray1)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        }
        .task {
            // Sync toggle with actual system permission status.
            // Handles the case where the user disables notifications in system Settings.
            if notificationsEnabled {
                let status = await NotificationService.shared.checkAuthorizationStatus()
                if status == .denied {
                    notificationsEnabled = false
                }
            }
        }
        .alert("Notifications Disabled", isPresented: $showNotificationDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications for REPS in Settings → Notifications.")
        }
    }

    // MARK: - Appearance Section (Pro)

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("APPEARANCE")

            if store.isProUnlocked {
                HStack(spacing: Spacing.md) {
                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isDarkMode ? Color.performancePurple : Color.personalOrange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dark Mode")
                            .font(.system(size: Typography.bodySize, weight: .medium))
                            .foregroundStyle(Color.pureWhite)

                        Text(isDarkMode ? "Switch to light mode" : "Switch to dark mode")
                            .font(.system(size: Typography.captionSize, weight: .regular))
                            .foregroundStyle(Color.mediumGray)
                    }

                    Spacer()

                    Toggle("", isOn: $isDarkMode)
                        .labelsHidden()
                        .tint(Color.performancePurple)
                }
                .padding(Spacing.lg)
                .background(Color.darkGray1)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.mediumGray)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dark Mode")
                                .font(.system(size: Typography.bodySize, weight: .medium))
                                .foregroundStyle(Color.pureWhite)

                            Text("Dark / Light toggle — Pro feature")
                                .font(.system(size: Typography.captionSize, weight: .regular))
                                .foregroundStyle(Color.mediumGray)
                        }

                        Spacer()

                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.mediumGray)
                    }
                    .padding(Spacing.lg)
                    .background(Color.darkGray1)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - General Section

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("GENERAL")

            VStack(spacing: 0) {
                settingsToggleRow(
                    icon: "speaker.wave.2",
                    title: "Completion Sound",
                    subtitle: "Play sound when completing tasks",
                    isOn: $soundEnabled
                )

                Divider()
                    .background(Color.darkGray2)

                settingsToggleRow(
                    icon: "hand.tap",
                    title: "Haptic Feedback",
                    subtitle: "Vibration on interactions",
                    isOn: $hapticFeedbackEnabled
                )
            }
            .background(Color.darkGray1)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("DATA")

            Button {
                Task { await store.restore() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.recoveryGreen)

                    Text("Restore Purchases")
                        .font(.system(size: Typography.bodySize, weight: .medium))
                        .foregroundStyle(Color.pureWhite)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.mediumGray)
                }
                .padding(Spacing.lg)
                .background(Color.darkGray1)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("ABOUT")

            VStack(spacing: 0) {
                aboutRow(icon: "star", title: "Rate on App Store") {
                    if let url = URL(string: "https://apps.apple.com/app/id6758785466?action=write-review") {
                        UIApplication.shared.open(url)
                    }
                }
                Divider().background(Color.darkGray2)
                aboutRow(icon: "hand.raised", title: "Privacy Policy") {
                    showPrivacyPolicy = true
                }
                Divider().background(Color.darkGray2)
                aboutRow(icon: "doc.text", title: "Terms of Service") {
                    showTermsOfService = true
                }
                Divider().background(Color.darkGray2)
                aboutRow(icon: "envelope", title: "Contact / Feedback") {
                    if let url = URL(string: "mailto:repsdevs@gmail.com?subject=REPS%20Feedback") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .background(Color.darkGray1)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Debug Section (DEBUG only)

    #if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("DEBUG")

            Button {
                store.debugTogglePro()
            } label: {
                HStack {
                    Image(systemName: "ant.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.strainRed)
                        .frame(width: 24)

                    Text("Toggle Pro Status")
                        .font(.system(size: Typography.bodySize, weight: .medium))
                        .foregroundStyle(Color.pureWhite)

                    Spacer()

                    Text(store.isProUnlocked ? "ON" : "OFF")
                        .font(.system(size: Typography.captionSize, weight: .bold))
                        .foregroundStyle(store.isProUnlocked ? Color.recoveryGreen : Color.mediumGray)
                }
                .padding(Spacing.lg)
                .background(Color.darkGray1)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.standard)
                        .strokeBorder(Color.strainRed.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
    #endif

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: Spacing.xs) {
            Text("Made with dedication")
                .font(.system(size: Typography.captionSize, weight: .medium))
                .foregroundStyle(Color.mediumGray)

            Text(appVersion)
                .font(.system(size: Typography.captionSize, weight: .medium))
                .foregroundStyle(Color.mediumGray.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.lg)
    }

    // MARK: - Reusable Components

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Typography.labelSize, weight: .semibold))
            .foregroundStyle(Color.mediumGray)
            .tracking(0.8)
    }

    private func settingsToggleRow(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.recoveryGreen)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: Typography.bodySize, weight: .medium))
                    .foregroundStyle(Color.pureWhite)

                Text(subtitle)
                    .font(.system(size: Typography.captionSize, weight: .regular))
                    .foregroundStyle(Color.mediumGray)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.recoveryGreen)
        }
        .padding(Spacing.lg)
    }

    private func aboutRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.mediumGray)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: Typography.bodySize, weight: .medium))
                    .foregroundStyle(Color.pureWhite)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.mediumGray)
            }
            .padding(Spacing.lg)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}

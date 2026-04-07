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

    // MARK: - Store

    @ObservedObject private var store = StoreKitService.shared

    // MARK: - Sheet State

    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showPaywall = false
    @State private var showNotificationDeniedAlert = false
    @State private var notificationTime: Date = Date()

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
                        memberStatusSection
                        preferencesSection
                        aboutSection
                        #if DEBUG
                        debugSection
                        #endif
                        dangerZoneSection
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
                    Text("SETTINGS")
                        .font(.system(size: 17, weight: .black))
                        .italic()
                        .foregroundStyle(Color.pureWhite)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.pureWhite)
                            .frame(width: 36, height: 36)
                            .background(Color.darkGray1)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .toolbarBackground(Color.brandBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(spacing: 6) {
            Text("REPS")
                .font(.system(size: 48, weight: .black))
                .italic()
                .foregroundStyle(Color.recoveryGreen)

            Text("LOCKED IN.")
                .font(.system(size: 13, weight: .bold))
                .tracking(3)
                .foregroundStyle(Color.pureWhite.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Member Status Section

    private var memberStatusSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("MEMBER STATUS")

            Button {
                if !store.isProUnlocked { showPaywall = true }
            } label: {
                HStack(spacing: Spacing.md) {
                    settingsIcon("crown.fill", bg: Color(hex: "3D2800"), fg: Color(hex: "FFB800"))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.isProUnlocked ? "REPS Pro" : "Free Plan")
                            .font(.system(size: Typography.bodySize, weight: .bold))
                            .italic()
                            .foregroundStyle(Color.pureWhite)
                        Text(store.isProUnlocked ? "PREMIUM TIER" : "FREE TIER")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(Color.pureWhite.opacity(0.4))
                    }

                    Spacer()

                    Text(store.isProUnlocked ? "ACTIVE" : "UPGRADE")
                        .font(.system(size: 12, weight: .black))
                        .italic()
                        .foregroundStyle(Color.recoveryGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.recoveryGreen.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.recoveryGreen.opacity(0.4), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(Spacing.lg)
                .background(Color.darkGray1)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
            }
            .buttonStyle(.plain)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Preferences Section (iCloud + Notifications + General)

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("PREFERENCES")

            VStack(spacing: 0) {
                // iCloud Sync
                if store.isProUnlocked {
                    let isActive = UserDefaults.standard.bool(forKey: "cloudKitActiveOnLaunch")
                    HStack(spacing: Spacing.md) {
                        settingsIcon("icloud.fill", bg: Color(hex: "1A2E50"), fg: Color(hex: "4A90E2"))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("iCloud Sync")
                                .font(.system(size: Typography.bodySize, weight: .bold))
                                .italic()
                                .foregroundStyle(Color.pureWhite)
                            Text("MULTI-DEVICE")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(Color.pureWhite.opacity(0.4))
                        }

                        Spacer()

                        Toggle("", isOn: .constant(isActive))
                            .labelsHidden()
                            .tint(Color.recoveryGreen)
                            .disabled(true)
                    }
                    .padding(Spacing.lg)

                    settingsDivider
                }

                // Nudges
                HStack(spacing: Spacing.md) {
                    settingsIcon("bell.fill", bg: Color(hex: "0C2E1A"), fg: Color.recoveryGreen)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Nudges")
                            .font(.system(size: Typography.bodySize, weight: .bold))
                            .italic()
                            .foregroundStyle(Color.pureWhite)
                        Text("DAILY REMINDERS")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(Color.pureWhite.opacity(0.4))
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

                // Notification Time Picker (shown when notifications are enabled)
                if notificationsEnabled {
                    settingsDivider

                    HStack(spacing: Spacing.md) {
                        settingsIcon("clock.fill", bg: Color(hex: "0C2E1A"), fg: Color.recoveryGreen)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Reminder Time")
                                .font(.system(size: Typography.bodySize, weight: .bold))
                                .italic()
                                .foregroundStyle(Color.pureWhite)
                            Text("DAILY NUDGE")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(Color.pureWhite.opacity(0.4))
                        }

                        Spacer()

                        DatePicker("", selection: $notificationTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .onChange(of: notificationTime) { _, newTime in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                                notificationHour = components.hour ?? 8
                                notificationMinute = components.minute ?? 0
                                NotificationService.shared.scheduleReminder(
                                    hour: notificationHour,
                                    minute: notificationMinute
                                )
                            }
                    }
                    .padding(Spacing.lg)
                }

                settingsDivider

                // Completion Sound
                HStack(spacing: Spacing.md) {
                    settingsIcon("music.note", bg: Color(hex: "22153A"), fg: Color(hex: "9B7FFF"))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Sound")
                            .font(.system(size: Typography.bodySize, weight: .bold))
                            .italic()
                            .foregroundStyle(Color.pureWhite)
                        Text("COMPLETION FEEDBACK")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(Color.pureWhite.opacity(0.4))
                    }

                    Spacer()

                    Toggle("", isOn: $soundEnabled)
                        .labelsHidden()
                        .tint(Color.recoveryGreen)
                }
                .padding(Spacing.lg)

                settingsDivider

                // Haptics
                HStack(spacing: Spacing.md) {
                    settingsIcon("iphone.radiowaves.left.and.right", bg: Color(hex: "3A1020"), fg: Color(hex: "FF5C8A"))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Haptics")
                            .font(.system(size: Typography.bodySize, weight: .bold))
                            .italic()
                            .foregroundStyle(Color.pureWhite)
                        Text("TACTILE RESPONSE")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(Color.pureWhite.opacity(0.4))
                    }

                    Spacer()

                    Toggle("", isOn: $hapticFeedbackEnabled)
                        .labelsHidden()
                        .tint(Color.recoveryGreen)
                }
                .padding(Spacing.lg)
            }
            .background(Color.darkGray1)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        }
        .task {
            var components = DateComponents()
            components.hour = notificationHour
            components.minute = notificationMinute
            notificationTime = Calendar.current.date(from: components) ?? Date()

            if notificationsEnabled {
                let status = await NotificationService.shared.checkAuthorizationStatus()
                if status == .denied { notificationsEnabled = false }
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

    // MARK: - Danger Zone Section

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("DANGER ZONE")

            Button {
                Task { await store.restore() }
            } label: {
                HStack(spacing: Spacing.md) {
                    settingsIcon("arrow.clockwise", bg: Color(hex: "3A0A0A"), fg: Color(hex: "FF4444"))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Restore Purchases")
                            .font(.system(size: Typography.bodySize, weight: .bold))
                            .italic()
                            .foregroundStyle(Color(hex: "FF4444"))
                        Text("RECOVER YOUR PRO ACCESS")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(Color(hex: "FF4444").opacity(0.5))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "FF4444").opacity(0.5))
                }
                .padding(Spacing.lg)
                .background(Color(hex: "FF4444").opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.standard)
                        .strokeBorder(Color(hex: "FF4444").opacity(0.2), lineWidth: 1)
                )
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
                aboutRow(icon: "star.fill", title: "Rate on App Store") {
                    if let url = URL(string: "https://apps.apple.com/app/id6758785466?action=write-review") {
                        UIApplication.shared.open(url)
                    }
                }
                settingsDivider
                aboutRow(icon: "hand.raised.fill", title: "Privacy Policy") {
                    showPrivacyPolicy = true
                }
                settingsDivider
                aboutRow(icon: "doc.text.fill", title: "Terms of Service") {
                    showTermsOfService = true
                }
                settingsDivider
                aboutRow(icon: "envelope.fill", title: "Contact") {
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

    private var settingsDivider: some View {
        Rectangle()
            .fill(Color.pureWhite.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, 60)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color.pureWhite.opacity(0.35))
            .tracking(1.2)
    }

    private func settingsIcon(_ systemName: String, bg: Color, fg: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(bg)
                .frame(width: 42, height: 42)
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(fg)
        }
    }

    private func aboutRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.pureWhite.opacity(0.4))
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: Typography.bodySize, weight: .bold))
                    .italic()
                    .foregroundStyle(Color.pureWhite)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.pureWhite.opacity(0.2))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}

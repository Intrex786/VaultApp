// SettingsView.swift
// Password Manager — Settings: Travel Mode, Auto-Lock, iCloud Sync

import SwiftUI

// MARK: - Auto-Lock Interval

enum AutoLockInterval: String, CaseIterable, Identifiable {
    case immediately  = "Immediately"
    case oneMinute    = "1 Minute"
    case fiveMinutes  = "5 Minutes"
    case fifteenMins  = "15 Minutes"
    case oneHour      = "1 Hour"
    case never        = "Never"

    var id: String { rawValue }

    var seconds: Int? {
        switch self {
        case .immediately: return 0
        case .oneMinute:   return 60
        case .fiveMinutes: return 300
        case .fifteenMins: return 900
        case .oneHour:     return 3600
        case .never:       return nil
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @AppStorage("autoLockInterval")    private var autoLockRaw: String     = AutoLockInterval.fiveMinutes.rawValue
    @AppStorage("iCloudSyncEnabled")   private var iCloudSyncEnabled: Bool = false
    @AppStorage("clipboardTimeout")    private var clipboardTimeout: Int   = 60
    @AppStorage("travelModeEnabled")   private var travelModeEnabled: Bool = false

    @State private var travelModeAuthPending: Bool  = false
    @State private var travelModeError: String?     = nil
    @State private var showClearDataAlert: Bool      = false
    @State private var showAutoLockPicker: Bool      = false
    @State private var appeared: Bool                = false

    private let biometricGate = BiometricGate()

    private var autoLockInterval: AutoLockInterval {
        AutoLockInterval(rawValue: autoLockRaw) ?? .fiveMinutes
    }

    var body: some View {
        ZStack {
            Color.obsidianBase.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.lg) {

                    // ── Travel Mode ───────────────────────────────────────────
                    SettingsSection(title: "Travel Mode") {
                        VStack(spacing: 0) {
                            TravelModeRow(
                                isEnabled: travelModeEnabled,
                                isAuthPending: travelModeAuthPending,
                                errorMessage: travelModeError,
                                onToggle: handleTravelModeToggle
                            )

                            if travelModeEnabled {
                                Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)

                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: "airplane")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.accentIndigo)
                                    Text("Items marked as travel-hidden are not visible while Travel Mode is active.")
                                        .font(AppFont.bodySmall)
                                        .foregroundStyle(Color.textSecondary)
                                }
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .animation(AppAnimation.spring, value: travelModeEnabled)
                            }
                        }
                    }
                    .staggeredAppear(index: 0)

                    // ── Security ──────────────────────────────────────────────
                    SettingsSection(title: "Security") {
                        VStack(spacing: 0) {
                            // Auto-Lock
                            Button {
                                AppHaptics.selection()
                                withAnimation(AppAnimation.spring) { showAutoLockPicker.toggle() }
                            } label: {
                                SettingsDetailRow(
                                    icon: "lock.rotation",
                                    iconColor: .accentIndigo,
                                    label: "Auto-Lock",
                                    value: autoLockInterval.rawValue
                                )
                            }
                            .buttonStyle(.plain)

                            if showAutoLockPicker {
                                Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)
                                AutoLockPicker(selected: autoLockRaw) { interval in
                                    autoLockRaw = interval.rawValue
                                    AppHaptics.selection()
                                    withAnimation(AppAnimation.spring) { showAutoLockPicker = false }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)

                            // Clipboard Timeout
                            SettingsToggleRow(
                                icon: "doc.on.clipboard",
                                iconColor: Color(hex: "#64D2FF"),
                                label: "Clipboard Timeout",
                                subtitle: "Clear clipboard after \(clipboardTimeout)s",
                                isOn: .constant(clipboardTimeout > 0)
                            )

                            Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)

                            // Face ID
                            SettingsDetailRow(
                                icon: "faceid",
                                iconColor: .successGreen,
                                label: "Face ID",
                                value: "Enabled"
                            )
                        }
                    }
                    .staggeredAppear(index: 1)

                    // ── Sync & Backup ─────────────────────────────────────────
                    SettingsSection(title: "Sync & Backup") {
                        VStack(spacing: 0) {
                            SettingsToggleRow(
                                icon: "icloud.and.arrow.up",
                                iconColor: Color(hex: "#5AC8FA"),
                                label: "iCloud Sync",
                                subtitle: iCloudSyncEnabled ? "Vault syncs across your devices" : "Vault stored locally only",
                                isOn: $iCloudSyncEnabled,
                                onChange: { enabled in
                                    AppHaptics.selection()
                                }
                            )

                            Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)

                            Button {} label: {
                                SettingsDetailRow(
                                    icon: "square.and.arrow.down",
                                    iconColor: Color(hex: "#30D158"),
                                    label: "Export Vault",
                                    value: "Encrypted"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .staggeredAppear(index: 2)

                    // ── Appearance ────────────────────────────────────────────
                    SettingsSection(title: "Appearance") {
                        VStack(spacing: 0) {
                            SettingsDetailRow(
                                icon: "moon.fill",
                                iconColor: Color(hex: "#BF5AF2"),
                                label: "Theme",
                                value: "Obsidian Dark"
                            )
                            Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)
                            SettingsDetailRow(
                                icon: "textformat.size",
                                iconColor: Color(hex: "#FF9F0A"),
                                label: "App Icon",
                                value: "Default"
                            )
                        }
                    }
                    .staggeredAppear(index: 3)

                    // ── About ─────────────────────────────────────────────────
                    SettingsSection(title: "About") {
                        VStack(spacing: 0) {
                            SettingsDetailRow(
                                icon: "info.circle",
                                iconColor: Color.textSecondary,
                                label: "Version",
                                value: "1.0.0 (1)"
                            )
                            Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)
                            SettingsDetailRow(
                                icon: "doc.text",
                                iconColor: Color.textSecondary,
                                label: "Privacy Policy",
                                value: ""
                            )
                            Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)
                            SettingsDetailRow(
                                icon: "checkmark.seal",
                                iconColor: Color.textSecondary,
                                label: "Security Audit",
                                value: "2024"
                            )
                        }
                    }
                    .staggeredAppear(index: 4)

                    // ── Danger Zone ───────────────────────────────────────────
                    SettingsSection(title: "Danger Zone") {
                        Button {
                            AppHaptics.destructive()
                            showClearDataAlert = true
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: AppRadius.xs)
                                        .fill(Color.dangerRed.opacity(0.15))
                                        .frame(width: 30, height: 30)
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.dangerRed)
                                }
                                Text("Clear All Vault Data")
                                    .font(AppFont.bodyMedium)
                                    .foregroundStyle(Color.dangerRed)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.textTertiary)
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm + 2)
                        }
                        .buttonStyle(.plain)
                    }
                    .staggeredAppear(index: 5)

                    Spacer(minLength: AppSpacing.xl2)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Clear All Vault Data?", isPresented: $showClearDataAlert) {
            Button("Delete Everything", role: .destructive) {
                Task {
                    try? await VaultStore.shared.deleteAll()
                    AppHaptics.success()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all items from your vault. This action cannot be undone.")
        }
    }

    // MARK: - Travel Mode

    private func handleTravelModeToggle(_ newValue: Bool) {
        guard newValue else {
            // Disabling travel mode requires biometric confirmation too
            travelModeAuthPending = true
            Task {
                do {
                    try await biometricGate.authenticateWithFallback(reason: "Disable Travel Mode")
                    await MainActor.run {
                        travelModeAuthPending = false
                        travelModeError = nil
                        withAnimation(AppAnimation.spring) { travelModeEnabled = false }
                        AppHaptics.success()
                    }
                } catch {
                    await MainActor.run {
                        travelModeAuthPending = false
                        travelModeError = (error as? BiometricError)?.errorDescription
                        AppHaptics.error()
                    }
                }
            }
            return
        }

        travelModeAuthPending = true
        travelModeError = nil

        Task {
            do {
                try await biometricGate.authenticateWithFallback(reason: "Enable Travel Mode")
                await MainActor.run {
                    travelModeAuthPending = false
                    withAnimation(AppAnimation.spring) { travelModeEnabled = true }
                    AppHaptics.success()
                }
            } catch {
                await MainActor.run {
                    travelModeAuthPending = false
                    travelModeError = (error as? BiometricError)?.errorDescription
                    AppHaptics.error()
                }
            }
        }
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title.uppercased())
                .font(AppFont.labelMedium)
                .foregroundStyle(Color.textSecondary)
                .kerning(0.6)
                .padding(.horizontal, AppSpacing.xs)

            content
                .glassCard(cornerRadius: AppRadius.lg)
        }
    }
}

// MARK: - Settings Row

private struct SettingsDetailRow: View {
    let icon:      String
    let iconColor: Color
    let label:     String
    let value:     String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.xs)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(label)
                .font(AppFont.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            if !value.isEmpty {
                Text(value)
                    .font(AppFont.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
    }
}

// MARK: - Settings Toggle Row

private struct SettingsToggleRow: View {
    let icon:      String
    let iconColor: Color
    let label:     String
    let subtitle:  String
    @Binding var isOn: Bool
    var onChange: ((Bool) -> Void)? = nil

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.xs)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppFont.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
                Text(subtitle)
                    .font(AppFont.labelSmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(Color.accentIndigo)
                .onChange(of: isOn) { _, newValue in onChange?(newValue) }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
    }
}

// MARK: - Travel Mode Row

private struct TravelModeRow: View {
    let isEnabled:      Bool
    let isAuthPending:  Bool
    let errorMessage:   String?
    let onToggle:       (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs2) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.xs)
                        .fill(Color.accentIndigo.opacity(0.15))
                        .frame(width: 30, height: 30)
                    Image(systemName: isEnabled ? "airplane.circle.fill" : "airplane")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.accentIndigo)
                        .animation(AppAnimation.spring, value: isEnabled)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Travel Mode")
                        .font(AppFont.bodyMedium)
                        .foregroundStyle(Color.textPrimary)
                    Text(isEnabled ? "Active — sensitive items hidden" : "Requires Face ID to activate")
                        .font(AppFont.labelSmall)
                        .foregroundStyle(isEnabled ? Color.accentIndigo : Color.textSecondary)
                        .animation(AppAnimation.spring, value: isEnabled)
                }

                Spacer()

                if isAuthPending {
                    ProgressView()
                        .tint(Color.accentIndigo)
                        .scaleEffect(0.8)
                } else {
                    Toggle("", isOn: Binding(
                        get: { isEnabled },
                        set: { onToggle($0) }
                    ))
                    .tint(Color.accentIndigo)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + 2)

            if let error = errorMessage {
                Text(error)
                    .font(AppFont.labelSmall)
                    .foregroundStyle(Color.dangerRed)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xs)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(AppAnimation.spring, value: errorMessage)
    }
}

// MARK: - Auto-Lock Picker

private struct AutoLockPicker: View {
    let selected: String
    let onSelect: (AutoLockInterval) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(AutoLockInterval.allCases) { interval in
                Button {
                    onSelect(interval)
                } label: {
                    HStack {
                        Text(interval.rawValue)
                            .font(AppFont.bodyMedium)
                            .foregroundStyle(interval.rawValue == selected ? Color.accentIndigo : Color.textPrimary)
                        Spacer()
                        if interval.rawValue == selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.accentIndigo)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md + AppSpacing.lg)
                    .padding(.vertical, AppSpacing.xs + 2)
                }
                .buttonStyle(.plain)

                if interval != AutoLockInterval.allCases.last {
                    Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)
                }
            }
        }
        .padding(.bottom, AppSpacing.xs)
    }
}

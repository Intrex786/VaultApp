// ItemDetailView.swift
// Password Manager — Item Detail with blur→reveal, DNA art, Watchtower banner

import SwiftUI

// MARK: - Watchtower Status

enum WatchtowerStatus {
    case safe, weak, breached, reused

    var label: String {
        switch self {
        case .safe:     return "Secure"
        case .weak:     return "Weak Password"
        case .breached: return "Found in Breach"
        case .reused:   return "Password Reused"
        }
    }
    var icon: String {
        switch self {
        case .safe:     return "checkmark.shield.fill"
        case .weak:     return "exclamationmark.triangle.fill"
        case .breached: return "xmark.shield.fill"
        case .reused:   return "arrow.triangle.2.circlepath"
        }
    }
    var color: Color {
        switch self {
        case .safe:     return .successGreen
        case .weak:     return .warningAmber
        case .breached: return .dangerRed
        case .reused:   return .warningAmber
        }
    }
}

// MARK: - ItemDetailView

struct ItemDetailView: View {
    let item: DisplayVaultItem
    @Environment(\.dismiss) private var dismiss

    @State private var passwordRevealed: Bool     = false
    @State private var usernameCopied: Bool        = false
    @State private var passwordCopied: Bool        = false
    @State private var showDeleteAlert: Bool       = false
    @State private var appeared: Bool              = false
    @State private var watchtowerStatus: WatchtowerStatus = .safe

    var body: some View {
        ZStack(alignment: .top) {
            Color.obsidianBase.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.lg) {
                    // ── DNA Art Hero ──────────────────────────────────────────
                    DNAArtView(seed: item.password)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.xl)
                                .stroke(Color.obsidianBorder, lineWidth: 0.5)
                        )
                        .overlay(alignment: .bottomLeading) {
                            HStack(spacing: AppSpacing.sm) {
                                ItemIconBadge(item: item, size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(AppFont.displaySmall)
                                        .foregroundStyle(Color.textPrimary)
                                    Text(item.category.rawValue)
                                        .font(AppFont.labelMedium)
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                            .padding(AppSpacing.md)
                        }
                        .staggeredAppear(index: 0)

                    // ── Watchtower Banner ─────────────────────────────────────
                    if watchtowerStatus != .safe {
                        WatchtowerBanner(status: watchtowerStatus)
                            .staggeredAppear(index: 1)
                    }

                    // ── Fields Card ───────────────────────────────────────────
                    VStack(spacing: 0) {
                        // Username
                        FieldRow(
                            label: "USERNAME",
                            value: item.username,
                            isSecret: false,
                            revealed: .constant(true),
                            copied: $usernameCopied,
                            onCopy: {
                                UIPasteboard.general.string = item.username
                                AppHaptics.success()
                                withAnimation(AppAnimation.spring) { usernameCopied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation(AppAnimation.spring) { usernameCopied = false }
                                }
                            }
                        )

                        Divider()
                            .background(Color.obsidianBorder)
                            .padding(.horizontal, AppSpacing.md)

                        // Password
                        FieldRow(
                            label: "PASSWORD",
                            value: item.password,
                            isSecret: true,
                            revealed: $passwordRevealed,
                            copied: $passwordCopied,
                            onCopy: {
                                UIPasteboard.general.string = item.password
                                AppHaptics.success()
                                withAnimation(AppAnimation.spring) { passwordCopied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation(AppAnimation.spring) { passwordCopied = false }
                                }
                            }
                        )
                    }
                    .glassCard()
                    .staggeredAppear(index: 2)

                    // ── Metadata ──────────────────────────────────────────────
                    VStack(spacing: 0) {
                        MetaRow(label: "CATEGORY", value: item.category.rawValue)
                        Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)
                        MetaRow(label: "LAST MODIFIED",
                                value: item.lastModified.formatted(date: .abbreviated, time: .shortened))
                        Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)
                        MetaRow(label: "ITEM ID", value: item.id.uuidString.prefix(8).uppercased() + "…")
                    }
                    .glassCard()
                    .staggeredAppear(index: 3)

                    // ── Delete ────────────────────────────────────────────────
                    Button {
                        AppHaptics.destructive()
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Item", systemImage: "trash")
                            .font(AppFont.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.dangerRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                    }
                    .glassCard()
                    .staggeredAppear(index: 4)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xl2)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    AppHaptics.selection()
                } label: {
                    Image(systemName: item.isFavourite ? "star.fill" : "star")
                        .foregroundStyle(item.isFavourite ? Color.warningAmber : Color.textSecondary)
                }
            }
        }
        .alert("Delete \"\(item.title)\"?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This item will be permanently removed from your vault.")
        }
        .onAppear {
            // Determine watchtower status from password heuristics
            watchtowerStatus = evaluateWatchtower(item.password)
        }
    }

    private func evaluateWatchtower(_ password: String) -> WatchtowerStatus {
        if password.count < 8 { return .weak }
        let lowerSymbols = CharacterSet.lowercaseLetters
        let hasUpper = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasDigit = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasLower = password.rangeOfCharacter(from: lowerSymbols) != nil
        if !hasUpper || !hasDigit || !hasLower { return .weak }
        return .safe
    }
}

// MARK: - Watchtower Banner

private struct WatchtowerBanner: View {
    let status: WatchtowerStatus

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: status.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(status.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(status.label)
                    .font(AppFont.labelLarge)
                    .foregroundStyle(status.color)
                Text("Tap to view Watchtower details")
                    .font(AppFont.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(status.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(status.color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Field Row

private struct FieldRow: View {
    let label: String
    let value: String
    let isSecret: Bool
    @Binding var revealed: Bool
    @Binding var copied: Bool
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(AppFont.labelSmall)
                    .foregroundStyle(Color.textSecondary)
                    .kerning(0.5)

                if isSecret {
                    PasswordDots(revealed: revealed, password: value)
                } else {
                    Text(value.isEmpty ? "—" : value)
                        .font(AppFont.bodyMedium)
                        .foregroundStyle(value.isEmpty ? Color.textTertiary : Color.textPrimary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: AppSpacing.xs) {
                if isSecret {
                    Button {
                        AppHaptics.selection()
                        withAnimation(AppAnimation.spring) { revealed.toggle() }
                    } label: {
                        Image(systemName: revealed ? "eye.slash" : "eye")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: 32, height: 32)
                    }
                }

                Button(action: onCopy) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 15))
                        .foregroundStyle(copied ? Color.successGreen : Color.accentIndigo)
                        .frame(width: 32, height: 32)
                        .animation(AppAnimation.spring, value: copied)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - Meta Row

private struct MetaRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppFont.labelSmall)
                .foregroundStyle(Color.textSecondary)
                .kerning(0.5)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(AppFont.bodySmall)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

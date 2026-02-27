// AddItemView.swift
// Password Manager — Add / Edit Vault Item

import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss)       private var dismiss
    @EnvironmentObject            private var vm: VaultViewModel

    // Form state
    @State private var title          = ""
    @State private var username       = ""
    @State private var password       = ""
    @State private var notes          = ""
    @State private var category:      ItemCategory = .login
    @State private var showPassword   = false
    @State private var isSaving       = false
    @State private var errorMsg:      String? = nil
    @State private var showGenerator  = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.obsidianBase.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {

                        // ── Category Picker ───────────────────────────────────
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.xs) {
                                ForEach(ItemCategory.allCases) { cat in
                                    Button {
                                        AppHaptics.selection()
                                        withAnimation(AppAnimation.spring) { category = cat }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 12, weight: .semibold))
                                            Text(cat.rawValue)
                                                .font(AppFont.labelMedium)
                                        }
                                        .foregroundStyle(category == cat ? Color.textPrimary : Color.textSecondary)
                                        .padding(.horizontal, AppSpacing.sm)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule().fill(
                                                category == cat
                                                    ? cat.color.opacity(0.22)
                                                    : Color.obsidianSurface
                                            )
                                            .overlay(
                                                Capsule().stroke(
                                                    category == cat
                                                        ? cat.color.opacity(0.5)
                                                        : Color.obsidianBorder,
                                                    lineWidth: 0.5
                                                )
                                            )
                                        )
                                    }
                                    .buttonStyle(PressScaleStyle())
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                        }

                        // ── Fields Card ───────────────────────────────────────
                        VStack(spacing: 0) {
                            AddFieldRow(label: "TITLE", placeholder: "e.g. GitHub", text: $title)
                            ObsidianDivider()
                            AddFieldRow(label: "USERNAME / EMAIL", placeholder: "you@example.com", text: $username, keyboardType: .emailAddress)
                            ObsidianDivider()

                            // Password row + generator button
                            HStack(spacing: AppSpacing.sm) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("PASSWORD")
                                        .font(AppFont.labelSmall)
                                        .foregroundStyle(Color.textSecondary)
                                        .kerning(0.5)

                                    Group {
                                        if showPassword {
                                            TextField("Enter password", text: $password)
                                        } else {
                                            SecureField("Enter password", text: $password)
                                        }
                                    }
                                    .font(AppFont.passwordMedium)
                                    .foregroundStyle(Color.textPrimary)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                }

                                HStack(spacing: 6) {
                                    Button {
                                        AppHaptics.selection()
                                        withAnimation { showPassword.toggle() }
                                    } label: {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .font(.system(size: 15))
                                            .foregroundStyle(Color.textSecondary)
                                            .frame(width: 32, height: 32)
                                    }

                                    Button {
                                        AppHaptics.selection()
                                        showGenerator = true
                                    } label: {
                                        Image(systemName: "dice.fill")
                                            .font(.system(size: 15))
                                            .foregroundStyle(Color.accentIndigo)
                                            .frame(width: 32, height: 32)
                                    }
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)

                            ObsidianDivider()
                            AddFieldRow(label: "NOTES (optional)", placeholder: "Add a note…", text: $notes)
                        }
                        .glassCard()
                        .padding(.horizontal, AppSpacing.md)

                        // ── Error ─────────────────────────────────────────────
                        if let err = errorMsg {
                            Text(err)
                                .font(AppFont.bodySmall)
                                .foregroundStyle(Color.dangerRed)
                                .padding(.horizontal, AppSpacing.md)
                        }

                        // ── Save Button ───────────────────────────────────────
                        Button { handleSave() } label: {
                            ZStack {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Save to Vault")
                                        .font(AppFont.labelLarge)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm + 4)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .fill(canSave ? AppGradients.accentGlow : .init(Color.obsidianRaised))
                            )
                        }
                        .disabled(!canSave || isSaving)
                        .buttonStyle(PressScaleStyle())
                        .padding(.horizontal, AppSpacing.md)
                        .animation(AppAnimation.spring, value: canSave)
                    }
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .sheet(isPresented: $showGenerator) {
                PasswordGeneratorView { generated in
                    password = generated
                }
                .presentationBackground(Color.obsidianBase)
                .presentationDetents([.large])
            }
        }
    }

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    private func handleSave() {
        guard canSave else { return }
        isSaving = true
        errorMsg = nil
        // Use a generated password if none entered
        let finalPwd = password.isEmpty
            ? CryptoEngine.generateRandomBytes(count: 20).base64EncodedString()
            : password
        Task {
            do {
                try await vm.addItem(
                    title:    title.trimmingCharacters(in: .whitespaces),
                    username: username,
                    password: finalPwd,
                    notes:    notes,
                    category: category
                )
                AppHaptics.success()
                dismiss()
            } catch {
                errorMsg = error.localizedDescription
                isSaving = false
            }
        }
    }
}

// MARK: - Helpers

private struct AddFieldRow: View {
    let label:       String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFont.labelSmall)
                .foregroundStyle(Color.textSecondary)
                .kerning(0.5)
            TextField(placeholder, text: $text)
                .font(AppFont.bodyMedium)
                .foregroundStyle(Color.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(keyboardType)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

private struct ObsidianDivider: View {
    var body: some View {
        Divider()
            .background(Color.obsidianBorder)
            .padding(.horizontal, AppSpacing.md)
    }
}

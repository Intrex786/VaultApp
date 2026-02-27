// PasswordGeneratorView.swift
// Password Manager — Password Generator with live DNA visualizer

import SwiftUI

// MARK: - PasswordGeneratorView

struct PasswordGeneratorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var length: Double         = 20
    @State private var useUppercase: Bool     = true
    @State private var useLowercase: Bool     = true
    @State private var useDigits: Bool        = true
    @State private var useSymbols: Bool       = true
    @State private var avoidAmbiguous: Bool   = false
    @State private var generatedPassword: String = ""
    @State private var copied: Bool           = false
    @State private var appeared: Bool         = false
    @State private var regeneratePulse: Bool  = false

    var onSelect: ((String) -> Void)?

    var body: some View {
        ZStack {
            Color.obsidianBase.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Handle ────────────────────────────────────────────────────
                RoundedRectangle(cornerRadius: AppRadius.full)
                    .fill(Color.obsidianBorder)
                    .frame(width: 36, height: 4)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.md)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {
                        // ── Header ────────────────────────────────────────────
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Password Generator")
                                    .font(AppFont.displaySmall)
                                    .foregroundStyle(Color.textPrimary)
                                Text("Cryptographically secure")
                                    .font(AppFont.bodySmall)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            Spacer()
                            Button {
                                AppHaptics.impact(.light)
                                withAnimation(AppAnimation.spring) { dismiss() }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(Color.textTertiary)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .staggeredAppear(index: 0)

                        // ── DNA Visualizer ────────────────────────────────────
                        DNAArtView(seed: generatedPassword)
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.lg)
                                    .stroke(Color.obsidianBorder, lineWidth: 0.5)
                            )
                            .padding(.horizontal, AppSpacing.lg)
                            .scaleEffect(regeneratePulse ? 1.02 : 1.0)
                            .animation(AppAnimation.spring, value: regeneratePulse)
                            .staggeredAppear(index: 1)

                        // ── Generated Password Display ────────────────────────
                        VStack(spacing: AppSpacing.sm) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(generatedPassword)
                                    .font(AppFont.passwordLarge)
                                    .foregroundStyle(Color.textPrimary)
                                    .padding(.horizontal, AppSpacing.md)
                                    .id(generatedPassword)
                                    .transition(.blurReplace)
                                    .animation(AppAnimation.spring, value: generatedPassword)
                            }
                            .frame(height: 36)

                            // Strength Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: AppRadius.full)
                                        .fill(Color.obsidianBorder)
                                        .frame(height: 4)
                                    RoundedRectangle(cornerRadius: AppRadius.full)
                                        .fill(AppGradients.strengthBar(strength: passwordStrength))
                                        .frame(width: geo.size.width * strengthFraction, height: 4)
                                        .animation(AppAnimation.spring, value: strengthFraction)
                                }
                            }
                            .frame(height: 4)
                            .padding(.horizontal, AppSpacing.md)

                            HStack {
                                Text(passwordStrength == .weak ? "Weak" :
                                        passwordStrength == .fair ? "Fair" : "Strong")
                                    .font(AppFont.labelSmall)
                                    .foregroundStyle(strengthColor)
                                Spacer()
                                Text("\(generatedPassword.count) characters")
                                    .font(AppFont.labelSmall)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(.horizontal, AppSpacing.md)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .glassCard()
                        .padding(.horizontal, AppSpacing.lg)
                        .staggeredAppear(index: 2)

                        // ── Length Slider ─────────────────────────────────────
                        VStack(spacing: AppSpacing.sm) {
                            HStack {
                                Text("LENGTH")
                                    .font(AppFont.labelMedium)
                                    .foregroundStyle(Color.textSecondary)
                                    .kerning(0.6)
                                Spacer()
                                Text("\(Int(length))")
                                    .font(AppFont.labelLarge)
                                    .foregroundStyle(Color.accentIndigo)
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                                    .animation(AppAnimation.spring, value: length)
                            }

                            HStack(spacing: AppSpacing.xs) {
                                Text("8")
                                    .font(AppFont.labelSmall)
                                    .foregroundStyle(Color.textTertiary)
                                Slider(value: $length, in: 8...64, step: 1)
                                    .tint(Color.accentIndigo)
                                    .onChange(of: length) { _, _ in
                                        AppHaptics.selection()
                                        regenerate()
                                    }
                                Text("64")
                                    .font(AppFont.labelSmall)
                                    .foregroundStyle(Color.textTertiary)
                            }
                        }
                        .padding(AppSpacing.md)
                        .glassCard()
                        .padding(.horizontal, AppSpacing.lg)
                        .staggeredAppear(index: 3)

                        // ── Toggles ───────────────────────────────────────────
                        VStack(spacing: 0) {
                            GeneratorToggleRow(
                                label: "Uppercase",
                                subtitle: "A–Z",
                                icon: "textformat.alt",
                                isOn: $useUppercase
                            ) { regenerate() }

                            Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)

                            GeneratorToggleRow(
                                label: "Lowercase",
                                subtitle: "a–z",
                                icon: "textformat",
                                isOn: $useLowercase
                            ) { regenerate() }

                            Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)

                            GeneratorToggleRow(
                                label: "Digits",
                                subtitle: "0–9",
                                icon: "number",
                                isOn: $useDigits
                            ) { regenerate() }

                            Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)

                            GeneratorToggleRow(
                                label: "Symbols",
                                subtitle: "!@#$%^&*",
                                icon: "asterisk",
                                isOn: $useSymbols
                            ) { regenerate() }

                            Divider().background(Color.obsidianBorder).padding(.horizontal, AppSpacing.md)

                            GeneratorToggleRow(
                                label: "Avoid Ambiguous",
                                subtitle: "Skip 0, O, l, 1",
                                icon: "eye.slash",
                                isOn: $avoidAmbiguous
                            ) { regenerate() }
                        }
                        .glassCard()
                        .padding(.horizontal, AppSpacing.lg)
                        .staggeredAppear(index: 4)

                        // ── Action Buttons ────────────────────────────────────
                        HStack(spacing: AppSpacing.sm) {
                            Button {
                                AppHaptics.impact(.medium)
                                regenerate()
                            } label: {
                                Label("Regenerate", systemImage: "arrow.clockwise")
                                    .font(AppFont.bodyMedium)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.accentIndigo)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.sm)
                            }
                            .glassCard()
                            .buttonStyle(PressScaleStyle())

                            Button {
                                UIPasteboard.general.string = generatedPassword
                                AppHaptics.success()
                                withAnimation(AppAnimation.spring) { copied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation(AppAnimation.spring) { copied = false }
                                }
                            } label: {
                                Label(copied ? "Copied!" : "Copy",
                                      systemImage: copied ? "checkmark" : "doc.on.doc")
                                    .font(AppFont.bodyMedium)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(copied ? Color.successGreen : Color.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.sm)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.lg)
                                    .fill(AppGradients.accentGlow)
                            )
                            .appShadow(AppShadow.accentGlow)
                            .buttonStyle(PressScaleStyle())
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .staggeredAppear(index: 5)

                        if let onSelect {
                            Button {
                                AppHaptics.success()
                                onSelect(generatedPassword)
                                withAnimation(AppAnimation.spring) { dismiss() }
                            } label: {
                                Text("Use This Password")
                                    .font(AppFont.bodyLarge)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.sm)
                            }
                            .glassCard()
                            .padding(.horizontal, AppSpacing.lg)
                            .buttonStyle(PressScaleStyle())
                            .staggeredAppear(index: 6)
                        }

                        Spacer(minLength: AppSpacing.xl2)
                    }
                    .padding(.top, AppSpacing.xs)
                }
            }
        }
        .onAppear {
            regenerate()
            withAnimation(AppAnimation.sheetAppear) { appeared = true }
        }
    }

    // MARK: - Password Generation

    private func regenerate() {
        var charset = ""
        if useUppercase    { charset += avoidAmbiguous ? "ABCDEFGHJKLMNPQRSTUVWXYZ" : "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if useLowercase    { charset += avoidAmbiguous ? "abcdefghjkmnpqrstuvwxyz"  : "abcdefghijklmnopqrstuvwxyz" }
        if useDigits       { charset += avoidAmbiguous ? "23456789"                  : "0123456789" }
        if useSymbols      { charset += "!@#$%^&*-_=+?" }
        if charset.isEmpty { charset = "abcdefghijklmnopqrstuvwxyz" }

        let chars  = Array(charset)
        let count  = Int(length)
        let bytes  = CryptoEngine.generateRandomBytes(count: count)
        var result = ""
        for byte in bytes {
            result.append(chars[Int(byte) % chars.count])
        }
        withAnimation(AppAnimation.spring) { generatedPassword = result }
        withAnimation(AppAnimation.microBounce) {
            regeneratePulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                regeneratePulse = false
            }
        }
    }

    // MARK: - Strength

    private var passwordStrength: PasswordStrength {
        let p = generatedPassword
        var score = 0
        if p.count >= 12 { score += 1 }
        if p.count >= 16 { score += 1 }
        if p.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if p.rangeOfCharacter(from: .decimalDigits) != nil    { score += 1 }
        let sym = CharacterSet.alphanumerics.union(.whitespaces).inverted
        if p.rangeOfCharacter(from: sym) != nil               { score += 1 }
        switch score {
        case 0...2: return .weak
        case 3:     return .fair
        default:    return .strong
        }
    }

    private var strengthFraction: Double {
        switch passwordStrength {
        case .weak:   return 0.25
        case .fair:   return 0.6
        case .strong: return 1.0
        }
    }

    private var strengthColor: Color {
        switch passwordStrength {
        case .weak:   return .dangerRed
        case .fair:   return .warningAmber
        case .strong: return .successGreen
        }
    }
}

// MARK: - Generator Toggle Row

private struct GeneratorToggleRow: View {
    let label:    String
    let subtitle: String
    let icon:     String
    @Binding var isOn: Bool
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.xs)
                    .fill(Color.accentIndigoMuted)
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentIndigo)
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
                .onChange(of: isOn) { _, _ in
                    AppHaptics.selection()
                    onChange()
                }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs + 2)
    }
}

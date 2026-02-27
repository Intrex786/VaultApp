// OnboardingView.swift
// Password Manager — 3-Step Onboarding

import SwiftUI

// MARK: - Onboarding Step

private enum OnboardingStep: Int, CaseIterable {
    case masterPassword = 0
    case secretKey      = 1
    case biometric      = 2
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @State private var currentStep: OnboardingStep = .masterPassword
    @State private var masterPassword: String      = ""
    @State private var confirmPassword: String     = ""
    @State private var secretKey: String           = ""
    @State private var biometricEnabled: Bool      = false
    @State private var isLoading: Bool             = false
    @State private var errorMessage: String?       = nil
    @State private var stepOffset: CGFloat         = 0
    @State private var appeared: Bool              = false

    var onComplete: (() -> Void)?

    private let biometricGate = BiometricGate()

    var body: some View {
        ZStack {
            Color.obsidianBase.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Progress Dots ─────────────────────────────────────────────
                HStack(spacing: AppSpacing.xs) {
                    ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                        Capsule()
                            .fill(step.rawValue <= currentStep.rawValue
                                  ? Color.accentIndigo
                                  : Color.obsidianBorder)
                            .frame(width: step == currentStep ? 24 : 8, height: 8)
                            .animation(AppAnimation.spring, value: currentStep)
                    }
                }
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.lg)

                // ── Step Content ──────────────────────────────────────────────
                TabView(selection: .init(
                    get: { currentStep.rawValue },
                    set: { _ in }
                )) {
                    MasterPasswordStep(
                        password: $masterPassword,
                        confirmPassword: $confirmPassword,
                        errorMessage: errorMessage
                    )
                    .tag(0)

                    SecretKeyStep(secretKey: $secretKey)
                        .tag(1)

                    BiometricStep(
                        biometricEnabled: $biometricEnabled,
                        isLoading: isLoading
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(AppAnimation.sheetAppear, value: currentStep)

                // ── CTA Button ────────────────────────────────────────────────
                Button(action: handleNext) {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .tint(Color.textPrimary)
                        } else {
                            Text(ctaLabel)
                                .font(AppFont.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.textPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.full)
                            .fill(AppGradients.accentGlow)
                    )
                    .appShadow(AppShadow.accentGlow)
                }
                .buttonStyle(PressScaleStyle())
                .disabled(isLoading || !canProceed)
                .opacity(canProceed ? 1 : 0.45)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
                .animation(AppAnimation.spring, value: canProceed)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .onAppear {
            withAnimation(AppAnimation.sheetAppear) { appeared = true }
        }
    }

    // MARK: - Logic

    private var ctaLabel: String {
        switch currentStep {
        case .masterPassword: return "Continue"
        case .secretKey:      return "I've Saved My Key"
        case .biometric:      return biometricEnabled ? "Enable & Finish" : "Skip for Now"
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case .masterPassword:
            return masterPassword.count >= 8 && masterPassword == confirmPassword
        case .secretKey:
            return !secretKey.isEmpty
        case .biometric:
            return true
        }
    }

    private func handleNext() {
        AppHaptics.impact(.light)
        errorMessage = nil

        switch currentStep {
        case .masterPassword:
            withAnimation(AppAnimation.spring) { currentStep = .secretKey }
            let raw = CryptoEngine.generateRandomBytes(count: 32)
            secretKey = raw.base64EncodedString()

        case .secretKey:
            withAnimation(AppAnimation.spring) { currentStep = .biometric }

        case .biometric:
            if biometricEnabled {
                isLoading = true
                Task {
                    do {
                        try await biometricGate.authenticate(reason: "Enable Face ID for vault access")
                        await MainActor.run {
                            isLoading = false
                            AppHaptics.success()
                            onComplete?()
                        }
                    } catch {
                        await MainActor.run {
                            isLoading = false
                            AppHaptics.error()
                            errorMessage = (error as? BiometricError)?.errorDescription ?? error.localizedDescription
                        }
                    }
                }
            } else {
                onComplete?()
            }
        }
    }
}

// MARK: - Step 1: Master Password

private struct MasterPasswordStep: View {
    @Binding var password: String
    @Binding var confirmPassword: String
    var errorMessage: String?
    @State private var showPassword: Bool = false
    @State private var strength: PasswordStrength = .weak
    @State private var ringProgress: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Create Master Password")
                        .font(AppFont.displayMedium)
                        .foregroundStyle(Color.textPrimary)
                    Text("This is the only password you'll ever need to remember.")
                        .font(AppFont.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                }
                .staggeredAppear(index: 0)

                // Strength Ring
                HStack(spacing: AppSpacing.lg) {
                    ZStack {
                        Circle()
                            .stroke(Color.obsidianBorder, lineWidth: 6)
                            .frame(width: 72, height: 72)
                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(
                                strengthColor,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 72, height: 72)
                            .rotationEffect(.degrees(-90))
                            .animation(AppAnimation.spring, value: ringProgress)
                        Text(strengthLabel)
                            .font(AppFont.labelSmall)
                            .foregroundStyle(strengthColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password Strength")
                            .font(AppFont.labelLarge)
                            .foregroundStyle(Color.textPrimary)
                        Text(strengthHint)
                            .font(AppFont.bodySmall)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .padding(AppSpacing.md)
                .glassCard()
                .staggeredAppear(index: 1)

                // Password Field
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("MASTER PASSWORD")
                        .font(AppFont.labelMedium)
                        .foregroundStyle(Color.textSecondary)
                        .kerning(0.6)

                    HStack {
                        Group {
                            if showPassword {
                                TextField("At least 8 characters", text: $password)
                            } else {
                                SecureField("At least 8 characters", text: $password)
                            }
                        }
                        .font(AppFont.passwordMedium)
                        .foregroundStyle(Color.textPrimary)
                        .tint(Color.accentIndigo)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: password) { _, new in
                            updateStrength(new)
                        }

                        Button {
                            showPassword.toggle()
                            AppHaptics.selection()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .padding(AppSpacing.md)
                    .glassCard(cornerRadius: AppRadius.md)
                }
                .staggeredAppear(index: 2)

                // Confirm Field
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("CONFIRM PASSWORD")
                        .font(AppFont.labelMedium)
                        .foregroundStyle(Color.textSecondary)
                        .kerning(0.6)

                    HStack {
                        SecureField("Repeat master password", text: $confirmPassword)
                            .font(AppFont.passwordMedium)
                            .foregroundStyle(Color.textPrimary)
                            .tint(Color.accentIndigo)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        if !confirmPassword.isEmpty {
                            Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(password == confirmPassword ? Color.successGreen : Color.dangerRed)
                                .transition(.scale.combined(with: .opacity))
                                .animation(AppAnimation.spring, value: password == confirmPassword)
                        }
                    }
                    .padding(AppSpacing.md)
                    .glassCard(cornerRadius: AppRadius.md)
                }
                .staggeredAppear(index: 3)

                if let error = errorMessage {
                    Text(error)
                        .font(AppFont.bodySmall)
                        .foregroundStyle(Color.dangerRed)
                        .padding(.horizontal, AppSpacing.xs)
                        .staggeredAppear(index: 4)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
    }

    private var strengthColor: Color {
        switch strength {
        case .weak:   return .dangerRed
        case .fair:   return .warningAmber
        case .strong: return .successGreen
        }
    }
    private var strengthLabel: String {
        switch strength {
        case .weak:   return "Weak"
        case .fair:   return "Fair"
        case .strong: return "Strong"
        }
    }
    private var strengthHint: String {
        switch strength {
        case .weak:   return "Add numbers & symbols"
        case .fair:   return "Try uppercase + symbols"
        case .strong: return "Excellent password"
        }
    }

    private func updateStrength(_ p: String) {
        var score = 0
        if p.count >= 8  { score += 1 }
        if p.count >= 12 { score += 1 }
        if p.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if p.rangeOfCharacter(from: .decimalDigits) != nil    { score += 1 }
        let symbols = CharacterSet.alphanumerics.union(.whitespaces).inverted
        if p.rangeOfCharacter(from: symbols) != nil { score += 1 }

        switch score {
        case 0...1: strength = .weak;   ringProgress = 0.2
        case 2...3: strength = .fair;   ringProgress = 0.55
        default:    strength = .strong; ringProgress = 1.0
        }
    }
}

// MARK: - Step 2: Secret Key

private struct SecretKeyStep: View {
    @Binding var secretKey: String
    @State private var copied: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "key.fill")
                            .foregroundStyle(Color.warningAmber)
                        Text("Your Secret Key")
                            .font(AppFont.displayMedium)
                            .foregroundStyle(Color.textPrimary)
                    }
                    Text("This key encrypts your vault. Save it somewhere safe — it cannot be recovered.")
                        .font(AppFont.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                }
                .staggeredAppear(index: 0)

                // Warning Banner
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.warningAmber)
                        .font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Never share this key")
                            .font(AppFont.labelLarge)
                            .foregroundStyle(Color.textPrimary)
                        Text("Without it, your vault cannot be restored.")
                            .font(AppFont.bodySmall)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(Color.warningAmber.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(Color.warningAmber.opacity(0.3), lineWidth: 0.5)
                        )
                )
                .staggeredAppear(index: 1)

                // Key Display
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("SECRET KEY")
                        .font(AppFont.labelMedium)
                        .foregroundStyle(Color.textSecondary)
                        .kerning(0.6)

                    VStack(spacing: AppSpacing.sm) {
                        Text(secretKey)
                            .font(AppFont.passwordSmall)
                            .foregroundStyle(Color.textPrimary)
                            .lineBreakMode(.byCharWrapping)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()
                            .background(Color.obsidianBorder)

                        Button {
                            UIPasteboard.general.string = secretKey
                            AppHaptics.success()
                            withAnimation(AppAnimation.spring) { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(AppAnimation.spring) { copied = false }
                            }
                        } label: {
                            Label(copied ? "Copied!" : "Copy to Clipboard",
                                  systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(AppFont.labelLarge)
                                .foregroundStyle(copied ? Color.successGreen : Color.accentIndigo)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(AppSpacing.md)
                    .glassCard(cornerRadius: AppRadius.md)
                }
                .staggeredAppear(index: 2)

                Text("Tip: Save this to a password manager emergency kit, printed paper, or secure cloud note.")
                    .font(AppFont.bodySmall)
                    .foregroundStyle(Color.textTertiary)
                    .padding(.horizontal, AppSpacing.xs)
                    .staggeredAppear(index: 3)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
    }
}

// MARK: - Step 3: Biometric

private struct BiometricStep: View {
    @Binding var biometricEnabled: Bool
    var isLoading: Bool

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Face ID Icon
            ZStack {
                Circle()
                    .fill(Color.accentIndigoMuted)
                    .frame(width: 120, height: 120)
                Circle()
                    .stroke(Color.accentIndigo.opacity(0.35), lineWidth: 1)
                    .frame(width: 120, height: 120)
                Image(systemName: "faceid")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundStyle(Color.accentIndigo)
            }
            .staggeredAppear(index: 0)

            VStack(spacing: AppSpacing.xs) {
                Text("Enable Face ID")
                    .font(AppFont.displayMedium)
                    .foregroundStyle(Color.textPrimary)
                Text("Unlock your vault instantly with a glance. Your biometric data never leaves your device.")
                    .font(AppFont.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }
            .staggeredAppear(index: 1)

            // Toggle Card
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use Face ID to unlock")
                        .font(AppFont.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                    Text("Recommended for daily use")
                        .font(AppFont.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $biometricEnabled)
                    .tint(Color.accentIndigo)
                    .onChange(of: biometricEnabled) { _, _ in
                        AppHaptics.selection()
                    }
            }
            .padding(AppSpacing.md)
            .glassCard()
            .padding(.horizontal, AppSpacing.lg)
            .staggeredAppear(index: 2)

            Spacer()
            Spacer()
        }
    }
}

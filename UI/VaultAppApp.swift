// VaultAppApp.swift
// App entry point with onboarding / lock gate.

import SwiftUI

@main
struct VaultAppApp: App {
    @StateObject private var vm = VaultViewModel.shared

    var body: some Scene {
        WindowGroup {
            RootGateView()
                .environmentObject(vm)
                .preferredColorScheme(.dark)
                .task { await vm.checkSetup() }
        }
    }
}

// MARK: - Root Gate

private struct RootGateView: View {
    @EnvironmentObject private var vm: VaultViewModel

    var body: some View {
        Group {
            if !vm.isOnboarded {
                OnboardingView { password in
                    Task {
                        do { try await vm.setup(masterPassword: password) }
                        catch { vm.errorMessage = error.localizedDescription }
                    }
                }
                .transition(.opacity)
            } else if !vm.isUnlocked {
                LockView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(AppAnimation.spring, value: vm.isOnboarded)
        .animation(AppAnimation.spring, value: vm.isUnlocked)
    }
}

// MARK: - Lock Screen

struct LockView: View {
    @EnvironmentObject private var vm: VaultViewModel
    @State private var appeared  = false
    @State private var unlocking = false

    var body: some View {
        ZStack {
            Color.obsidianBase.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // App Icon / logo
                ZStack {
                    Circle()
                        .fill(Color.accentIndigoMuted)
                        .frame(width: 110, height: 110)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentIndigo, Color(hex: "#A78BFA")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: AppSpacing.xs) {
                    Text("VaultApp")
                        .font(AppFont.displayMedium)
                        .foregroundStyle(Color.textPrimary)
                    Text("Unlock to access your vault")
                        .font(AppFont.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                Spacer()

                if let err = vm.errorMessage {
                    Text(err)
                        .font(AppFont.bodySmall)
                        .foregroundStyle(Color.dangerRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                }

                Button {
                    AppHaptics.impact(.light)
                    unlocking = true
                    vm.errorMessage = nil
                    Task { await vm.unlock(); unlocking = false }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        if unlocking {
                            ProgressView().tint(.white).scaleEffect(0.85)
                        } else {
                            Image(systemName: "faceid")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Unlock with Face ID")
                                .font(AppFont.bodyLarge)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.full)
                            .fill(AppGradients.accentGlow)
                    )
                    .appShadow(AppShadow.accentGlow)
                }
                .buttonStyle(PressScaleStyle())
                .disabled(unlocking)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl2)
            }
        }
        .onAppear {
            withAnimation(AppAnimation.sheetAppear) { appeared = true }
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await vm.unlock()
            }
        }
    }
}

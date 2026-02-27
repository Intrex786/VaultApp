// ContentView.swift
// Password Manager — Root TabView Shell

import SwiftUI

// MARK: - Tab Definition

enum AppTab: Int, CaseIterable {
    case home      = 0
    case allItems  = 1
    case generator = 2
    case settings  = 3

    var label: String {
        switch self {
        case .home:      return "Home"
        case .allItems:  return "Vault"
        case .generator: return "Generate"
        case .settings:  return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home:      return "house.fill"
        case .allItems:  return "rectangle.stack.fill"
        case .generator: return "dice.fill"
        case .settings:  return "gearshape.fill"
        }
    }
}

// MARK: - Root Content View

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var previousTab: AppTab = .home
    @State private var tabBarOffset: CGFloat = 0
    @State private var showNewItemSheet: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Background canvas ─────────────────────────────────────────────
            Color.obsidianBase
                .ignoresSafeArea()

            // ── Tab content ───────────────────────────────────────────────────
            TabView(selection: $selectedTab) {
                HomeView(showNewItemSheet: $showNewItemSheet)
                    .tag(AppTab.home)

                AllItemsView(showNewItemSheet: $showNewItemSheet)
                    .tag(AppTab.allItems)

                GeneratorPlaceholderView()
                    .tag(AppTab.generator)

                SettingsPlaceholderView()
                    .tag(AppTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(AppAnimation.spring, value: selectedTab)

            // ── Custom Tab Bar ────────────────────────────────────────────────
            CustomTabBar(selectedTab: $selectedTab)
                .offset(y: tabBarOffset)
                .animation(AppAnimation.spring, value: tabBarOffset)
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showNewItemSheet) {
            NewItemPlaceholderSheet()
        }
        .onChange(of: selectedTab) { _, newTab in
            AppHaptics.selection()
            previousTab = newTab
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var tabIndicator

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: tabIndicator
                ) {
                    withAnimation(AppAnimation.spring) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.lg)
        .background(
            // Frosted glass tab bar
            ZStack {
                Color.obsidianSurface
                    .opacity(0.92)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.obsidianBorder.opacity(0.6), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 0.5)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .ignoresSafeArea()
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.obsidianBorder.opacity(0.5))
                .frame(height: 0.5)
        }
    }
}

// MARK: - Tab Bar Item

struct TabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(Color.accentIndigoMuted)
                            .frame(width: 46, height: 28)
                            .matchedGeometryEffect(id: "tabIndicator", in: namespace)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.accentIndigo : Color.textSecondary)
                        .scaleEffect(isSelected ? 1.08 : 1.0)
                        .animation(AppAnimation.spring, value: isSelected)
                }
                .frame(width: 46, height: 28)

                Text(tab.label)
                    .font(AppFont.labelSmall)
                    .foregroundStyle(isSelected ? Color.accentIndigo : Color.textTertiary)
                    .animation(AppAnimation.spring, value: isSelected)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder Views (Generator & Settings stubs)

struct GeneratorPlaceholderView: View {
    @State private var generatedPassword = "X9#mK2@pLqR5"
    @State private var length: Double = 16
    @State private var includeSymbols = true
    @State private var includeNumbers = true
    @State private var includeUppercase = true
    @State private var copied = false

    var body: some View {
        ZStack {
            Color.obsidianBase.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    VStack(spacing: AppSpacing.xs) {
                        Text("Generator")
                            .font(AppFont.displayMedium)
                            .foregroundStyle(Color.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Create strong, unique passwords")
                            .font(AppFont.bodyMedium)
                            .foregroundStyle(Color.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.xl)

                    // Password display
                    VStack(spacing: AppSpacing.sm) {
                        Text(generatedPassword)
                            .font(AppFont.passwordLarge)
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding()

                        HStack(spacing: AppSpacing.sm) {
                            Button {
                                AppHaptics.success()
                                copied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copied = false
                                }
                            } label: {
                                Label(copied ? "Copied!" : "Copy",
                                      systemImage: copied ? "checkmark" : "doc.on.doc")
                                    .font(AppFont.labelLarge)
                                    .foregroundStyle(Color.textPrimary)
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(
                                        Capsule().fill(Color.accentIndigoMuted)
                                    )
                            }
                            .buttonStyle(PressScaleStyle())
                            .animation(AppAnimation.spring, value: copied)

                            Button {
                                AppHaptics.impact(.light)
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                                    .font(AppFont.labelLarge)
                                    .foregroundStyle(Color.textSecondary)
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(
                                        Capsule().fill(Color.obsidianRaised)
                                    )
                            }
                            .buttonStyle(PressScaleStyle())
                        }
                    }
                    .glassCard()
                    .padding(.horizontal, AppSpacing.md)

                    // Options card
                    VStack(spacing: AppSpacing.md) {
                        // Length slider
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            HStack {
                                Text("Length")
                                    .font(AppFont.bodyMedium)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                Text("\(Int(length))")
                                    .font(AppFont.passwordMedium)
                                    .foregroundStyle(Color.accentIndigo)
                            }
                            Slider(value: $length, in: 8...64, step: 1)
                                .tint(Color.accentIndigo)
                        }

                        Divider().background(Color.obsidianBorder)

                        ToggleRow(label: "Symbols", icon: "at", isOn: $includeSymbols)
                        ToggleRow(label: "Numbers", icon: "number", isOn: $includeNumbers)
                        ToggleRow(label: "Uppercase", icon: "textformat.alt", isOn: $includeUppercase)
                    }
                    .padding(AppSpacing.md)
                    .glassCard()
                    .padding(.horizontal, AppSpacing.md)
                }
                .padding(.bottom, 120)
            }
        }
    }
}

struct ToggleRow: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 20)

            Text(label)
                .font(AppFont.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(Color.accentIndigo)
                .labelsHidden()
        }
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.obsidianBase.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                Text("Settings")
                    .font(AppFont.displayMedium)
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.xl)

                VStack(spacing: 0) {
                    ForEach(settingsRows, id: \.title) { row in
                        SettingsRow(icon: row.icon, title: row.title, color: row.color)
                        if row.title != settingsRows.last?.title {
                            Divider()
                                .background(Color.obsidianBorder)
                                .padding(.leading, 52)
                        }
                    }
                }
                .glassCard()
                .padding(.horizontal, AppSpacing.md)

                Spacer()
            }
        }
    }

    private var settingsRows: [(icon: String, title: String, color: Color)] {
        [
            ("faceid",             "Biometric Lock",   .accentIndigo),
            ("lock.rotation",      "Auto-Lock",         Color(hex: "#30D158")),
            ("icloud.fill",        "iCloud Sync",       Color(hex: "#64D2FF")),
            ("key.fill",           "Master Password",   Color(hex: "#FF9F0A")),
            ("exclamationmark.shield.fill", "Security Audit", Color(hex: "#FF453A")),
        ]
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.xs)
                    .fill(color.opacity(0.18))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(AppFont.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - New Item Sheet Placeholder

struct NewItemPlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.obsidianBase.ignoresSafeArea()

                VStack(spacing: AppSpacing.lg) {
                    Text("Choose Type")
                        .font(AppFont.displaySmall)
                        .foregroundStyle(Color.textPrimary)
                        .padding(.top, AppSpacing.lg)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                              spacing: AppSpacing.sm) {
                        ForEach(Array(ItemCategory.allCases.enumerated()), id: \.element) { idx, cat in
                            Button {
                                AppHaptics.impact(.medium)
                                dismiss()
                            } label: {
                                VStack(spacing: AppSpacing.xs) {
                                    CategoryBadge(category: cat, size: 44)
                                    Text(cat.rawValue)
                                        .font(AppFont.labelLarge)
                                        .foregroundStyle(Color.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(AppSpacing.md)
                                .glassCard()
                            }
                            .buttonStyle(PressScaleStyle())
                            .staggeredAppear(index: idx)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.accentIndigo)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.obsidianBase)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

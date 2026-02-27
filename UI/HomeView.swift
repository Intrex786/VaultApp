// HomeView.swift
// Password Manager — Home Dashboard

import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @Binding var showNewItemSheet: Bool
    @EnvironmentObject private var vm: VaultViewModel

    @State private var greeting = Self.buildGreeting()
    @State private var showSecurityScore = false
    @State private var selectedItem: DisplayVaultItem? = nil

    private var pinnedItems: [DisplayVaultItem] { vm.items.filter { $0.isPinned } }
    private var recentItems: [DisplayVaultItem] { Array(vm.items.prefix(6)) }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.obsidianBase.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.xl) {
                        heroSection
                        securityBanner.staggeredAppear(index: 0)
                        pinnedSection.staggeredAppear(index: 1)
                        recentSection.staggeredAppear(index: 2)
                    }
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)

                FABButton { showNewItemSheet = true }
                    .padding(.trailing, AppSpacing.lg)
                    .padding(.bottom, 80)
            }
            .navigationDestination(item: $selectedItem) { item in
                ItemDetailView(item: item)
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            AppGradients.heroBanner
                .clipShape(RoundedRectangle(cornerRadius: 0))
                .frame(height: 200)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.accentIndigo.opacity(0.18))
                        .frame(width: 160, height: 160)
                        .blur(radius: 48)
                        .offset(x: 30, y: -30)
                }

            VStack(alignment: .leading, spacing: AppSpacing.xs2) {
                Text(greeting)
                    .font(AppFont.labelLarge)
                    .foregroundStyle(Color.textSecondary)
                    .kerning(0.4)
                Text("Your Vault")
                    .font(AppFont.displayLarge)
                    .foregroundStyle(Color.textPrimary)
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.successGreen)
                    Text("\(vm.items.count) item\(vm.items.count == 1 ? "" : "s") secured")
                        .font(AppFont.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.lg)
        }
    }

    // MARK: - Security Banner

    private var securityBanner: some View {
        Button {
            withAnimation(AppAnimation.spring) { showSecurityScore.toggle() }
            AppHaptics.selection()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .stroke(Color.accentIndigo.opacity(0.25), lineWidth: 3)
                        .frame(width: 48, height: 48)
                    Circle()
                        .trim(from: 0, to: CGFloat(vm.securityScore) / 100)
                        .stroke(Color.accentIndigo,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-90))
                        .animation(AppAnimation.spring, value: vm.securityScore)
                    Text("\(vm.securityScore)")
                        .font(AppFont.captionBold)
                        .foregroundStyle(Color.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Security Score")
                        .font(AppFont.labelLarge)
                        .foregroundStyle(Color.textPrimary)
                    Text(vm.securityScore >= 80 ? "Vault is in great shape"
                         : vm.securityScore >= 50 ? "Some items need attention"
                         : "Action required")
                        .font(AppFont.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Image(systemName: showSecurityScore ? "chevron.up" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .animation(AppAnimation.spring, value: showSecurityScore)
            }
            .padding(AppSpacing.md)
            .glassCard()
            .padding(.horizontal, AppSpacing.md)
        }
        .buttonStyle(PressScaleStyle())
    }

    // MARK: - Pinned Section

    private var pinnedSection: some View {
        VStack(spacing: AppSpacing.sm) {
            SectionHeader(title: "Pinned") {}

            if pinnedItems.isEmpty {
                EmptyStateView(
                    icon: "pin.slash",
                    title: "Nothing Pinned",
                    subtitle: "Long-press any item to pin it here."
                )
                .frame(height: 120)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(Array(pinnedItems.enumerated()), id: \.element.id) { idx, item in
                            Button { selectedItem = item } label: {
                                PinnedCard(item: item)
                                    .staggeredAppear(index: idx)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(spacing: AppSpacing.sm) {
            SectionHeader(title: "Recently Added") {}

            if recentItems.isEmpty {
                EmptyStateView(
                    icon: "plus.rectangle.on.rectangle",
                    title: "Vault is Empty",
                    subtitle: "Tap + to add your first item."
                )
                .frame(height: 120)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentItems.enumerated()), id: \.element.id) { idx, item in
                        Button { selectedItem = item } label: {
                            VaultRow(item: item)
                                .staggeredAppear(index: idx + 4)
                                .background(Color.obsidianSurface)
                        }
                        .buttonStyle(.plain)
                        .contextMenu { contextMenuItems(for: item) }

                        if item.id != recentItems.last?.id {
                            Divider()
                                .background(Color.obsidianBorder)
                                .padding(.leading, 70)
                        }
                    }
                }
                .glassCard()
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuItems(for item: DisplayVaultItem) -> some View {
        Button {
            UIPasteboard.general.string = item.password
            AppHaptics.success()
        } label: {
            Label("Copy Password", systemImage: "doc.on.doc")
        }

        Button {
            UIPasteboard.general.string = item.username
            AppHaptics.success()
        } label: {
            Label("Copy Username", systemImage: "person.crop.circle")
        }

        Divider()

        Button {
            AppHaptics.selection()
            Task { await vm.togglePin(item) }
        } label: {
            Label(item.isPinned ? "Unpin" : "Pin to Home",
                  systemImage: item.isPinned ? "pin.slash" : "pin")
        }

        Button(role: .destructive) {
            AppHaptics.destructive()
            Task { await vm.deleteItem(id: item.id) }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Helpers

    private static func buildGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }
}

// HomeView.swift
// Password Manager — Home Dashboard

import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @Binding var showNewItemSheet: Bool

    // Placeholder state
    @State private var pinnedItems: [DisplayVaultItem] = SampleVault.pinned
    @State private var recentItems: [DisplayVaultItem] = SampleVault.recent
    @State private var greeting: String = Self.buildGreeting()
    @State private var scrollOffset: CGFloat = 0
    @State private var heroOpacity: Double = 1
    @State private var showSecurityScore = false
    @State private var securityScore: Int = 82

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.obsidianBase.ignoresSafeArea()

            // ── Scrollable content ────────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.xl) {

                    heroSection
                        .opacity(heroOpacity)

                    securityBanner
                        .staggeredAppear(index: 0)

                    pinnedSection
                        .staggeredAppear(index: 1)

                    recentSection
                        .staggeredAppear(index: 2)
                }
                .padding(.bottom, 120)           // clear FAB + tab bar
            }
            .scrollIndicators(.hidden)

            // ── FAB ───────────────────────────────────────────────────────────
            FABButton {
                showNewItemSheet = true
            }
            .padding(.trailing, AppSpacing.lg)
            .padding(.bottom, 80)               // sit above tab bar
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient blob
            AppGradients.heroBanner
                .clipShape(RoundedRectangle(cornerRadius: 0))
                .frame(height: 200)
                .overlay(alignment: .topTrailing) {
                    // Decorative blur orb
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

                    Text("\(SampleVault.items.count) items secured")
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
            withAnimation(AppAnimation.spring) {
                showSecurityScore.toggle()
            }
            AppHaptics.selection()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .stroke(Color.accentIndigo.opacity(0.25), lineWidth: 3)
                        .frame(width: 48, height: 48)

                    Circle()
                        .trim(from: 0, to: CGFloat(securityScore) / 100)
                        .stroke(Color.accentIndigo, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-90))
                        .animation(AppAnimation.spring, value: securityScore)

                    Text("\(securityScore)")
                        .font(AppFont.captionBold)
                        .foregroundStyle(Color.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Security Score")
                        .font(AppFont.labelLarge)
                        .foregroundStyle(Color.textPrimary)
                    Text(securityScore >= 80 ? "Your vault is in great shape"
                         : securityScore >= 50 ? "Some items need attention"
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
            SectionHeader(title: "Pinned") {
                // Navigate to all items — wired in ContentView via tab switch
            }

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
                            PinnedCard(item: item)
                                .staggeredAppear(index: idx)
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
            SectionHeader(title: "Recently Used") {
                // Future nav
            }

            if recentItems.isEmpty {
                EmptyStateView(
                    icon: "clock.badge.xmark",
                    title: "No Recent Items",
                    subtitle: "Items you view will appear here."
                )
                .frame(height: 120)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentItems.enumerated()), id: \.element.id) { idx, item in
                        VaultRow(item: item)
                            .staggeredAppear(index: idx + 4) // offset from above sections
                            .background(Color.obsidianSurface)
                            .contextMenu {
                                contextMenuItems(for: item)
                            }

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
            AppHaptics.success()
        } label: {
            Label("Copy Password", systemImage: "doc.on.doc")
        }

        Button {
            AppHaptics.success()
        } label: {
            Label("Copy Username", systemImage: "person.crop.circle")
        }

        Divider()

        Button {
            AppHaptics.selection()
            togglePin(item)
        } label: {
            Label(item.isPinned ? "Unpin" : "Pin to Home",
                  systemImage: item.isPinned ? "pin.slash" : "pin")
        }

        Button(role: .destructive) {
            AppHaptics.destructive()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Actions

    private func togglePin(_ item: DisplayVaultItem) {
        if let idx = recentItems.firstIndex(where: { $0.id == item.id }) {
            withAnimation(AppAnimation.spring) {
                var updated = recentItems[idx]
                updated = DisplayVaultItem(
                    id: updated.id,
                    title: updated.title,
                    username: updated.username,
                    password: updated.password,
                    category: updated.category,
                    isPinned: !updated.isPinned,
                    iconName: updated.iconName,
                    iconColor: updated.iconColor,
                    lastModified: updated.lastModified,
                    isFavourite: updated.isFavourite
                )
                recentItems[idx] = updated
            }
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

// MARK: - Preview

#Preview {
    HomeView(showNewItemSheet: .constant(false))
        .preferredColorScheme(.dark)
}

// DesignSystem.swift
// Password Manager — Component Library & Typography

import SwiftUI

// MARK: - Typography

struct AppFont {
    // ── Headlines (SF Pro Display) ────────────────────────────────────────────
    static let displayLarge  = Font.system(size: 34, weight: .bold,   design: .default)
    static let displayMedium = Font.system(size: 28, weight: .bold,   design: .default)
    static let displaySmall  = Font.system(size: 22, weight: .semibold, design: .default)

    // ── Body ─────────────────────────────────────────────────────────────────
    static let bodyLarge  = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall  = Font.system(size: 13, weight: .regular, design: .default)

    // ── Labels ────────────────────────────────────────────────────────────────
    static let labelLarge  = Font.system(size: 13, weight: .semibold, design: .default)
    static let labelMedium = Font.system(size: 11, weight: .semibold, design: .default)
    static let labelSmall  = Font.system(size: 10, weight: .medium,   design: .default)

    // ── Monospace — Password fields (SF Mono weight 500) ─────────────────────
    static let passwordLarge  = Font.system(size: 17, weight: .medium, design: .monospaced)
    static let passwordMedium = Font.system(size: 15, weight: .medium, design: .monospaced)
    static let passwordSmall  = Font.system(size: 13, weight: .medium, design: .monospaced)

    // ── Caption ───────────────────────────────────────────────────────────────
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionBold = Font.system(size: 12, weight: .semibold, design: .default)
}

// MARK: - Vault Item Model (Placeholder)

struct DisplayVaultItem: Identifiable, Equatable {
    let id: UUID
    var title: String
    var username: String
    var password: String
    var category: ItemCategory
    var isPinned: Bool
    var iconName: String          // SF Symbol name
    var iconColor: Color
    var lastModified: Date
    var isFavourite: Bool

    static let placeholder = DisplayVaultItem(
        id: UUID(),
        title: "Example Login",
        username: "user@example.com",
        password: "••••••••••••",
        category: .login,
        isPinned: false,
        iconName: "globe",
        iconColor: .accentIndigo,
        lastModified: Date(),
        isFavourite: false
    )
}

enum ItemCategory: String, CaseIterable, Identifiable {
    case login    = "Login"
    case card     = "Card"
    case identity = "Identity"
    case note     = "Secure Note"
    case wifi     = "Wi-Fi"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .login:    return "key.fill"
        case .card:     return "creditcard.fill"
        case .identity: return "person.crop.rectangle.fill"
        case .note:     return "lock.doc.fill"
        case .wifi:     return "wifi"
        }
    }

    var color: Color {
        switch self {
        case .login:    return .accentIndigo
        case .card:     return Color(hex: "#FF9F0A")
        case .identity: return Color(hex: "#30D158")
        case .note:     return Color(hex: "#64D2FF")
        case .wifi:     return Color(hex: "#BF5AF2")
        }
    }
}

// MARK: - Sample Data

struct SampleVault {
    static let items: [DisplayVaultItem] = [
        DisplayVaultItem(id: UUID(), title: "GitHub",
                  username: "dev@example.com", password: "Gh•••••••••",
                  category: .login, isPinned: true,
                  iconName: "chevron.left.forwardslash.chevron.right",
                  iconColor: Color(hex: "#F0F0F0"), lastModified: .distantPast, isFavourite: true),

        DisplayVaultItem(id: UUID(), title: "Apple ID",
                  username: "me@icloud.com", password: "Ap•••••••••",
                  category: .login, isPinned: true,
                  iconName: "apple.logo",
                  iconColor: Color(hex: "#F2F2F7"), lastModified: .distantPast, isFavourite: true),

        DisplayVaultItem(id: UUID(), title: "Visa Platinum",
                  username: "•••• •••• •••• 4291", password: "•••",
                  category: .card, isPinned: true,
                  iconName: "creditcard.fill",
                  iconColor: Color(hex: "#FFD60A"), lastModified: .distantPast, isFavourite: false),

        DisplayVaultItem(id: UUID(), title: "Netflix",
                  username: "family@example.com", password: "Nf•••••••••",
                  category: .login, isPinned: false,
                  iconName: "play.rectangle.fill",
                  iconColor: Color(hex: "#E50914"), lastModified: Date(), isFavourite: false),

        DisplayVaultItem(id: UUID(), title: "1Password Recovery",
                  username: "", password: "XXXXX-XXXXX-XXXXX-XXXXX",
                  category: .note, isPinned: false,
                  iconName: "lock.doc.fill",
                  iconColor: Color(hex: "#64D2FF"), lastModified: Date(), isFavourite: false),

        DisplayVaultItem(id: UUID(), title: "Home Wi-Fi",
                  username: "SSID: Obsidian_5G", password: "Wf•••••••••",
                  category: .wifi, isPinned: false,
                  iconName: "wifi",
                  iconColor: Color(hex: "#BF5AF2"), lastModified: Date(), isFavourite: false),

        DisplayVaultItem(id: UUID(), title: "Figma",
                  username: "design@example.com", password: "Fg•••••••••",
                  category: .login, isPinned: false,
                  iconName: "square.on.square",
                  iconColor: Color(hex: "#FF7262"), lastModified: Date(), isFavourite: false),

        DisplayVaultItem(id: UUID(), title: "Passport",
                  username: "John Appleseed", password: "••••••••",
                  category: .identity, isPinned: false,
                  iconName: "person.crop.rectangle.fill",
                  iconColor: Color(hex: "#30D158"), lastModified: Date(), isFavourite: false),
    ]

    static var pinned: [DisplayVaultItem] { items.filter { $0.isPinned } }
    static var recent: [DisplayVaultItem] { Array(items.filter { !$0.isPinned }.prefix(5)) }
}

// MARK: - Icon Badge

struct CategoryBadge: View {
    let category: ItemCategory
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(category.color.opacity(0.18))
                .frame(width: size, height: size)
            Image(systemName: category.icon)
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundStyle(category.color)
        }
    }
}

struct ItemIconBadge: View {
    let item: DisplayVaultItem
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(item.iconColor.opacity(0.18))
                .frame(width: size, height: size)
            Image(systemName: item.iconName)
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundStyle(item.iconColor)
        }
    }
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = AppRadius.lg

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.obsidianSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.obsidianBorder, lineWidth: 0.5)
                    )
            )
            .appShadow(AppShadow.cardDefault)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = AppRadius.lg) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Accent Glass Card

struct AccentGlassCard: ViewModifier {
    var cornerRadius: CGFloat = AppRadius.lg

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.accentIndigoMuted)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.accentIndigo.opacity(0.35), lineWidth: 0.5)
                    )
            )
            .appShadow(AppShadow.accentGlow)
    }
}

extension View {
    func accentCard(cornerRadius: CGFloat = AppRadius.lg) -> some View {
        modifier(AccentGlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Vault Row

struct VaultRow: View {
    let item: DisplayVaultItem
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ItemIconBadge(item: item, size: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(AppFont.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Text(item.username.isEmpty ? item.category.rawValue : item.username)
                    .font(AppFont.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if item.isFavourite {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.warningAmber.opacity(0.8))
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .contentShape(Rectangle())
    }
}

// MARK: - Pinned Grid Card

struct PinnedCard: View {
    let item: DisplayVaultItem
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ItemIconBadge(item: item, size: 40)
                .padding(.bottom, 2)

            Text(item.title)
                .font(AppFont.labelLarge)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            Text(item.category.rawValue)
                .font(AppFont.labelSmall)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(width: 110, height: 110)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .glassCard(cornerRadius: AppRadius.md)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(AppAnimation.microBounce, value: isPressed)
        .onTapGesture {
            AppHaptics.selection()
        }
        ._onButtonGesture { pressing in
            isPressed = pressing
        } perform: {}
    }
}

// MARK: - FAB Button

struct FABButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            AppHaptics.impact(.medium)
            action()
        }) {
            ZStack {
                Circle()
                    .fill(AppGradients.accentGlow)
                    .frame(width: 58, height: 58)
                    .appShadow(AppShadow.accentGlow)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .rotationEffect(.degrees(isPressed ? 45 : 0))
                    .animation(AppAnimation.spring, value: isPressed)
            }
        }
        .buttonStyle(PressScaleStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Press Scale Button Style

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(AppAnimation.microBounce, value: configuration.isPressed)
    }
}

// MARK: - Search Bar

struct ObsidianSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search vault…"

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            TextField(placeholder, text: $text)
                .font(AppFont.bodyMedium)
                .foregroundStyle(Color.textPrimary)
                .tint(Color.accentIndigo)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button {
                    withAnimation(AppAnimation.spring) { text = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textTertiary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs + 2)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.full)
                .fill(Color.obsidianSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.full)
                        .stroke(Color.obsidianBorder, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(AppFont.labelMedium)
                .foregroundStyle(Color.textSecondary)
                .kerning(0.8)

            Spacer()

            if let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(AppFont.labelMedium)
                        .foregroundStyle(Color.accentIndigo)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.textTertiary)
                .padding(.bottom, AppSpacing.xs)

            Text(title)
                .font(AppFont.displaySmall)
                .foregroundStyle(Color.textPrimary)

            Text(subtitle)
                .font(AppFont.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, AppSpacing.xl2)
    }
}

// MARK: - Staggered Appear Modifier

struct StaggeredAppear: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(AppAnimation.stagger(index), value: appeared)
            .onAppear { appeared = true }
            .onDisappear { appeared = false }
    }
}

extension View {
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppear(index: index))
    }
}

// MARK: - Password Dots

struct PasswordDots: View {
    let revealed: Bool
    let password: String

    var body: some View {
        Group {
            if revealed {
                Text(password)
                    .font(AppFont.passwordMedium)
                    .foregroundStyle(Color.textPrimary)
                    .transition(.blurReplace)
            } else {
                Text(String(repeating: "•", count: min(password.count, 12)))
                    .font(AppFont.passwordMedium)
                    .foregroundStyle(Color.textSecondary)
                    .transition(.blurReplace)
            }
        }
        .animation(AppAnimation.spring, value: revealed)
    }
}

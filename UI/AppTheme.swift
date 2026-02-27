// AppTheme.swift
// Password Manager — Obsidian Glass Theme

import SwiftUI

// MARK: - Color Palette

extension Color {
    // ── Backgrounds ──────────────────────────────────────────────────────────
    static let obsidianBase    = Color(hex: "#0D0D12")   // root canvas
    static let obsidianSurface = Color(hex: "#16161F")   // cards / sheets
    static let obsidianRaised  = Color(hex: "#1C1C28")   // elevated cards
    static let obsidianBorder  = Color(hex: "#252535")   // dividers / strokes

    // ── Accent ───────────────────────────────────────────────────────────────
    static let accentIndigo      = Color(hex: "#5B5BD6")
    static let accentIndigoMuted = Color(hex: "#5B5BD6").opacity(0.18)
    static let accentIndigoGlow  = Color(hex: "#5B5BD6").opacity(0.35)

    // ── Semantic Colours ─────────────────────────────────────────────────────
    static let dangerRed   = Color(hex: "#FF453A")
    static let warningAmber = Color(hex: "#FFD60A")
    static let successGreen = Color(hex: "#30D158")

    // ── Typography ────────────────────────────────────────────────────────────
    static let textPrimary   = Color(hex: "#F2F2F7")
    static let textSecondary = Color(hex: "#8E8EA0")
    static let textTertiary  = Color(hex: "#48485A")

    // MARK: Hex initialiser
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8  & 0xFF,
                            int       & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradient Library

struct AppGradients {
    // Hero banner shimmer
    static let heroBanner = LinearGradient(
        colors: [Color(hex: "#1E1E30"), Color.obsidianBase],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Accent glow for FAB / active states
    static let accentGlow = LinearGradient(
        colors: [Color(hex: "#7B7BE8"), Color.accentIndigo],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Card surface shimmer
    static let cardShimmer = LinearGradient(
        colors: [Color.obsidianSurface, Color.obsidianRaised],
        startPoint: .top,
        endPoint: .bottom
    )

    // Danger destructive
    static let danger = LinearGradient(
        colors: [Color(hex: "#FF6B6B"), Color.dangerRed],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Password strength bar
    static func strengthBar(strength: PasswordStrength) -> LinearGradient {
        switch strength {
        case .weak:
            return LinearGradient(colors: [Color.dangerRed, Color(hex: "#FF6B6B")],
                                  startPoint: .leading, endPoint: .trailing)
        case .fair:
            return LinearGradient(colors: [Color.warningAmber, Color(hex: "#FFE066")],
                                  startPoint: .leading, endPoint: .trailing)
        case .strong:
            return LinearGradient(colors: [Color.successGreen, Color(hex: "#5FE89A")],
                                  startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - Password Strength

enum PasswordStrength {
    case weak, fair, strong
}

// MARK: - Animation Constants

struct AppAnimation {
    /// Primary spring — used for ALL motion in this app
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)

    /// Staggered entry delay factor
    static let staggerStep: Double = 0.05

    static func stagger(_ index: Int) -> Animation {
        spring.delay(Double(index) * staggerStep)
    }

    /// Micro-interaction for button press
    static let microBounce = Animation.spring(response: 0.25, dampingFraction: 0.65)

    /// Sheet / modal appear
    static let sheetAppear = Animation.spring(response: 0.5, dampingFraction: 0.82)
}

// MARK: - Haptics

struct AppHaptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func destructive() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// MARK: - Shadow Styles

struct AppShadow {
    struct Style {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    static let cardDefault = Style(color: Color.black.opacity(0.45),
                                   radius: 20, x: 0, y: 8)
    static let accentGlow  = Style(color: Color.accentIndigo.opacity(0.45),
                                   radius: 16, x: 0, y: 4)
    static let subtleDepth = Style(color: Color.black.opacity(0.25),
                                   radius: 8,  x: 0, y: 2)
}

extension View {
    func appShadow(_ style: AppShadow.Style) -> some View {
        self.shadow(color: style.color,
                    radius: style.radius,
                    x: style.x,
                    y: style.y)
    }
}

// MARK: - Corner Radius Scale

enum AppRadius {
    static let xs:   CGFloat = 6
    static let sm:   CGFloat = 10
    static let md:   CGFloat = 14
    static let lg:   CGFloat = 20
    static let xl:   CGFloat = 28
    static let full: CGFloat = 999
}

// MARK: - Spacing Scale

enum AppSpacing {
    static let xs2:  CGFloat = 4
    static let xs:   CGFloat = 8
    static let sm:   CGFloat = 12
    static let md:   CGFloat = 16
    static let lg:   CGFloat = 24
    static let xl:   CGFloat = 32
    static let xl2:  CGFloat = 48
}

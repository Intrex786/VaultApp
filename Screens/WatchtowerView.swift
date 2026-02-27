// WatchtowerView.swift
// Password Manager — Security Health Dashboard with animated ring + swipe-to-resolve

import SwiftUI

// MARK: - Risk Severity

enum RiskSeverity: String {
    case critical = "Critical"
    case high     = "High"
    case medium   = "Medium"
    case low      = "Low"

    var color: Color {
        switch self {
        case .critical: return .dangerRed
        case .high:     return Color(hex: "#FF6B6B")
        case .medium:   return .warningAmber
        case .low:      return .successGreen
        }
    }
    var icon: String {
        switch self {
        case .critical: return "xmark.shield.fill"
        case .high:     return "exclamationmark.triangle.fill"
        case .medium:   return "exclamationmark.circle.fill"
        case .low:      return "info.circle.fill"
        }
    }
}

// MARK: - Risk Card Model

struct RiskCard: Identifiable {
    let id: UUID
    let title: String
    let itemTitle: String
    let description: String
    let severity: RiskSeverity
    var resolved: Bool
}

// MARK: - WatchtowerView

struct WatchtowerView: View {
    @State private var healthScore: Double    = 0
    @State private var targetScore: Double    = 72
    @State private var ringAnimated: Bool     = false
    @State private var riskCards: [RiskCard]  = Self.sampleRisks
    @State private var appeared: Bool         = false

    private static let sampleRisks: [RiskCard] = [
        RiskCard(id: UUID(), title: "Compromised Password",
                 itemTitle: "LinkedIn",
                 description: "This password was found in a known data breach. Change it immediately.",
                 severity: .critical, resolved: false),
        RiskCard(id: UUID(), title: "Weak Password",
                 itemTitle: "Netflix",
                 description: "Password is shorter than 8 characters and lacks complexity.",
                 severity: .high, resolved: false),
        RiskCard(id: UUID(), title: "Reused Password",
                 itemTitle: "Twitter",
                 description: "This password is used for 3 other accounts in your vault.",
                 severity: .medium, resolved: false),
        RiskCard(id: UUID(), title: "Old Password",
                 itemTitle: "GitHub",
                 description: "Password hasn't been updated in over 12 months.",
                 severity: .low, resolved: false),
        RiskCard(id: UUID(), title: "Reused Password",
                 itemTitle: "Spotify",
                 description: "This password matches another login in your vault.",
                 severity: .medium, resolved: false),
    ]

    private var unresolvedCount: Int { riskCards.filter { !$0.resolved }.count }
    private var resolvedCount:   Int { riskCards.filter { $0.resolved  }.count }

    var body: some View {
        ZStack {
            Color.obsidianBase.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.lg) {
                    // ── Health Ring Hero ──────────────────────────────────────
                    HealthRingHero(
                        score: ringAnimated ? targetScore : 0,
                        unresolvedCount: unresolvedCount,
                        resolvedCount: resolvedCount
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    .staggeredAppear(index: 0)

                    // ── Summary Chips ─────────────────────────────────────────
                    HStack(spacing: AppSpacing.sm) {
                        SummaryChip(
                            value: "\(riskCards.filter { $0.severity == .critical && !$0.resolved }.count)",
                            label: "Critical",
                            color: .dangerRed
                        )
                        SummaryChip(
                            value: "\(riskCards.filter { $0.severity == .high && !$0.resolved }.count)",
                            label: "High",
                            color: Color(hex: "#FF6B6B")
                        )
                        SummaryChip(
                            value: "\(riskCards.filter { $0.severity == .medium && !$0.resolved }.count)",
                            label: "Medium",
                            color: .warningAmber
                        )
                        SummaryChip(
                            value: "\(resolvedCount)",
                            label: "Resolved",
                            color: .successGreen
                        )
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .staggeredAppear(index: 1)

                    // ── Risk Cards List ───────────────────────────────────────
                    VStack(spacing: AppSpacing.xs) {
                        SectionHeader(title: "Security Risks")
                            .padding(.bottom, AppSpacing.xs2)

                        ForEach(Array(riskCards.enumerated()), id: \.element.id) { idx, card in
                            if !card.resolved {
                                SwipeableRiskCard(card: card) {
                                    resolveCard(card.id)
                                }
                                .staggeredAppear(index: idx + 2)
                            }
                        }

                        if unresolvedCount == 0 {
                            EmptyStateView(
                                icon: "checkmark.shield.fill",
                                title: "All Clear",
                                subtitle: "No active security risks found in your vault."
                            )
                            .staggeredAppear(index: 2)
                        }
                    }

                    // ── Resolved Section ──────────────────────────────────────
                    if resolvedCount > 0 {
                        VStack(spacing: AppSpacing.xs) {
                            SectionHeader(title: "Resolved (\(resolvedCount))")
                                .padding(.bottom, AppSpacing.xs2)

                            ForEach(riskCards.filter { $0.resolved }) { card in
                                ResolvedCard(card: card)
                                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            }
                        }
                    }

                    Spacer(minLength: AppSpacing.xl2)
                }
                .padding(.top, AppSpacing.sm)
            }
        }
        .navigationTitle("Watchtower")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(Animation.spring(response: 1.2, dampingFraction: 0.75)) {
                    ringAnimated = true
                }
            }
        }
    }

    private func resolveCard(_ id: UUID) {
        AppHaptics.success()
        withAnimation(AppAnimation.spring) {
            if let idx = riskCards.firstIndex(where: { $0.id == id }) {
                riskCards[idx].resolved = true
            }
            // Recompute score
            let newScore = max(0, min(100, targetScore + Double(riskCards.filter { $0.resolved }.count) * 5))
            targetScore = newScore
        }
    }
}

// MARK: - Health Ring Hero

private struct HealthRingHero: View {
    let score: Double
    let unresolvedCount: Int
    let resolvedCount: Int

    private var scoreInt: Int { Int(score) }
    private var ringColor: Color {
        switch score {
        case 0..<40:  return .dangerRed
        case 40..<70: return .warningAmber
        default:      return .successGreen
        }
    }
    private var statusLabel: String {
        switch score {
        case 0..<40:  return "At Risk"
        case 40..<70: return "Needs Attention"
        default:      return "Good Standing"
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                // Track
                Circle()
                    .stroke(Color.obsidianBorder, lineWidth: 14)
                    .frame(width: 160, height: 160)

                // Progress
                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [ringColor.opacity(0.6), ringColor]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(Animation.spring(response: 1.2, dampingFraction: 0.75), value: score)

                // Score Text
                VStack(spacing: 2) {
                    Text("\(scoreInt)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(ringColor)
                        .contentTransition(.numericText())
                        .animation(AppAnimation.spring, value: scoreInt)
                    Text("/ 100")
                        .font(AppFont.labelMedium)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            VStack(spacing: AppSpacing.xs2) {
                Text(statusLabel)
                    .font(AppFont.displaySmall)
                    .foregroundStyle(Color.textPrimary)
                Text("\(unresolvedCount) issues to resolve")
                    .font(AppFont.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
        .glassCard()
    }
}

// MARK: - Summary Chip

private struct SummaryChip: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(AppFont.labelSmall)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(color.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Swipeable Risk Card

private struct SwipeableRiskCard: View {
    let card: RiskCard
    let onResolve: () -> Void

    @State private var offset: CGFloat     = 0
    @State private var expanded: Bool      = false
    private let resolveThreshold: CGFloat  = -100

    var body: some View {
        ZStack(alignment: .trailing) {
            // Resolve background
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.successGreen)
                    Text("Resolve")
                        .font(AppFont.labelSmall)
                        .foregroundStyle(Color.successGreen)
                }
                .frame(width: 80)
                .opacity(min(1, -offset / resolveThreshold))
            }
            .padding(.horizontal, AppSpacing.md)

            // Card
            RiskCardContent(card: card, expanded: $expanded)
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { value in
                            let x = value.translation.width
                            if x < 0 { offset = max(x, resolveThreshold * 1.3) }
                        }
                        .onEnded { value in
                            if offset < resolveThreshold {
                                withAnimation(AppAnimation.spring) { offset = -300 }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    onResolve()
                                }
                            } else {
                                withAnimation(AppAnimation.spring) { offset = 0 }
                            }
                        }
                )
        }
        .padding(.horizontal, AppSpacing.lg)
        .clipped()
    }
}

// MARK: - Risk Card Content

private struct RiskCardContent: View {
    let card: RiskCard
    @Binding var expanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                AppHaptics.selection()
                withAnimation(AppAnimation.spring) { expanded.toggle() }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(card.severity.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: card.severity.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(card.severity.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: AppSpacing.xs2) {
                            Text(card.severity.rawValue.uppercased())
                                .font(AppFont.labelSmall)
                                .foregroundStyle(card.severity.color)
                            Text("·")
                                .foregroundStyle(Color.textTertiary)
                            Text(card.itemTitle)
                                .font(AppFont.labelSmall)
                                .foregroundStyle(Color.textSecondary)
                        }
                        Text(card.title)
                            .font(AppFont.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textPrimary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                        .animation(AppAnimation.spring, value: expanded)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Divider()
                        .background(Color.obsidianBorder)
                        .padding(.horizontal, AppSpacing.md)

                    Text(card.description)
                        .font(AppFont.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, AppSpacing.md)

                    Text("Swipe left to mark as resolved")
                        .font(AppFont.captionBold)
                        .foregroundStyle(Color.successGreen.opacity(0.8))
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.sm)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassCard(cornerRadius: AppRadius.md)
    }
}

// MARK: - Resolved Card

private struct ResolvedCard: View {
    let card: RiskCard

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.successGreen.opacity(0.6))

            VStack(alignment: .leading, spacing: 2) {
                Text(card.title)
                    .font(AppFont.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textSecondary)
                    .strikethrough(true, color: Color.textTertiary)
                Text(card.itemTitle)
                    .font(AppFont.labelSmall)
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            Text("Resolved")
                .font(AppFont.labelSmall)
                .foregroundStyle(Color.successGreen.opacity(0.7))
        }
        .padding(AppSpacing.sm)
        .padding(.horizontal, AppSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Color.successGreen.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(Color.successGreen.opacity(0.15), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, AppSpacing.lg)
    }
}

// AllItemsView.swift
// Password Manager — Full Vault List with Search & Swipe Actions

import SwiftUI

// MARK: - AllItemsView

struct AllItemsView: View {
    @Binding var showNewItemSheet: Bool

    // Search & filter state
    @State private var searchText: String = ""
    @State private var selectedCategory: ItemCategory? = nil
    @State private var sortOrder: SortOrder = .alphabetical
    @State private var showSortMenu: Bool = false

    // List state
    @State private var items: [DisplayVaultItem] = SampleVault.items
    @State private var deletingItemID: UUID? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var pendingDeleteID: UUID? = nil

    // Reveal state map  id → revealed
    @State private var revealedPasswords: Set<UUID> = []

    // MARK: Computed

    private var filteredItems: [DisplayVaultItem] {
        var result = items

        // Category filter
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }

        // Search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.username.lowercased().contains(query) ||
                $0.category.rawValue.lowercased().contains(query)
            }
        }

        // Sort
        switch sortOrder {
        case .alphabetical:
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .recentlyModified:
            result.sort { $0.lastModified > $1.lastModified }
        case .category:
            result.sort { $0.category.rawValue < $1.category.rawValue }
        case .favourites:
            result.sort { ($0.isFavourite ? 0 : 1) < ($1.isFavourite ? 0 : 1) }
        }

        return result
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.obsidianBase.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                categoryFilterBar
                    .padding(.top, AppSpacing.xs)

                Divider()
                    .background(Color.obsidianBorder)
                    .padding(.top, AppSpacing.xs)

                itemListContent
            }

            FABButton {
                showNewItemSheet = true
            }
            .padding(.trailing, AppSpacing.lg)
            .padding(.bottom, 80)
        }
        .confirmationDialog(
            "Delete Item?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let id = pendingDeleteID {
                    performDelete(id: id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Vault")
                    .font(AppFont.displayMedium)
                    .foregroundStyle(Color.textPrimary)
                Text("\(items.count) items")
                    .font(AppFont.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            // Sort menu
            Menu {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Button {
                        withAnimation(AppAnimation.spring) {
                            sortOrder = order
                        }
                        AppHaptics.selection()
                    } label: {
                        HStack {
                            Text(order.label)
                            if sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(Color.obsidianSurface)
                    )
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.xl)
        .padding(.bottom, AppSpacing.sm)
        .overlay(alignment: .bottom) {
            ObsidianSearchBar(text: $searchText)
                .padding(.horizontal, AppSpacing.md)
                .offset(y: 36)
        }
        .padding(.bottom, AppSpacing.xl)
    }

    // MARK: - Category Filter Bar

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                // "All" pill
                CategoryPill(
                    label: "All",
                    icon: "square.grid.2x2.fill",
                    color: .accentIndigo,
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(AppAnimation.spring) {
                        selectedCategory = nil
                    }
                    AppHaptics.selection()
                }

                ForEach(ItemCategory.allCases) { cat in
                    CategoryPill(
                        label: cat.rawValue,
                        icon: cat.icon,
                        color: cat.color,
                        isSelected: selectedCategory == cat
                    ) {
                        withAnimation(AppAnimation.spring) {
                            selectedCategory = (selectedCategory == cat) ? nil : cat
                        }
                        AppHaptics.selection()
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
        }
    }

    // MARK: - Item List

    @ViewBuilder
    private var itemListContent: some View {
        if filteredItems.isEmpty {
            emptyResultsView
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { idx, item in
                        swipableRow(for: item, at: idx)

                        if item.id != filteredItems.last?.id {
                            Divider()
                                .background(Color.obsidianBorder)
                                .padding(.leading, 70)
                        }
                    }
                }
                .background(Color.obsidianSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(Color.obsidianBorder, lineWidth: 0.5)
                )
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 120)
            }
        }
    }

    // MARK: - Swipable Row

    private func swipableRow(for item: DisplayVaultItem, at index: Int) -> some View {
        VaultRow(item: item)
            .staggeredAppear(index: index)
            .background(Color.obsidianSurface)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                // Delete
                Button(role: .destructive) {
                    AppHaptics.destructive()
                    pendingDeleteID = item.id
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                }
                .tint(Color.dangerRed)

                // Edit
                Button {
                    AppHaptics.impact(.light)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(Color.accentIndigo)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                // Favourite
                Button {
                    AppHaptics.impact(.medium)
                    toggleFavourite(item)
                } label: {
                    Label(
                        item.isFavourite ? "Unfav" : "Fav",
                        systemImage: item.isFavourite ? "star.slash.fill" : "star.fill"
                    )
                }
                .tint(Color.warningAmber)
            }
            .contextMenu {
                contextMenu(for: item)
            }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenu(for item: DisplayVaultItem) -> some View {
        Section {
            Button {
                AppHaptics.success()
            } label: {
                Label("Copy Password", systemImage: "doc.on.doc.fill")
            }

            Button {
                AppHaptics.success()
            } label: {
                Label("Copy Username", systemImage: "person.crop.circle.fill")
            }
        }

        Section {
            Button {
                AppHaptics.selection()
                toggleFavourite(item)
            } label: {
                Label(
                    item.isFavourite ? "Remove Favourite" : "Add to Favourites",
                    systemImage: item.isFavourite ? "star.slash" : "star"
                )
            }

            Button {
                AppHaptics.selection()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }

        Section {
            Button(role: .destructive) {
                AppHaptics.destructive()
                pendingDeleteID = item.id
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyResultsView: some View {
        if searchText.isEmpty && selectedCategory == nil {
            EmptyStateView(
                icon: "rectangle.stack.badge.plus",
                title: "Vault is Empty",
                subtitle: "Tap + to add your first login, card, or note."
            )
        } else {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "No Results",
                subtitle: "Try a different search or category filter."
            )
        }
    }

    // MARK: - Mutations

    private func performDelete(id: UUID) {
        withAnimation(AppAnimation.spring) {
            items.removeAll { $0.id == id }
        }
        pendingDeleteID = nil
    }

    private func toggleFavourite(_ item: DisplayVaultItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        withAnimation(AppAnimation.spring) {
            let old = items[idx]
            items[idx] = DisplayVaultItem(
                id: old.id, title: old.title, username: old.username,
                password: old.password, category: old.category, isPinned: old.isPinned,
                iconName: old.iconName, iconColor: old.iconColor,
                lastModified: old.lastModified, isFavourite: !old.isFavourite
            )
        }
    }
}

// MARK: - Category Pill

struct CategoryPill: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(AppFont.labelMedium)
            }
            .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.22) : Color.obsidianSurface)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? color.opacity(0.5) : Color.obsidianBorder,
                                    lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(PressScaleStyle())
        .animation(AppAnimation.spring, value: isSelected)
    }
}

// MARK: - Sort Order

enum SortOrder: String, CaseIterable {
    case alphabetical     = "A–Z"
    case recentlyModified = "Recently Modified"
    case category         = "Category"
    case favourites       = "Favourites First"

    var label: String { rawValue }
}

// MARK: - Preview

#Preview {
    AllItemsView(showNewItemSheet: .constant(false))
        .preferredColorScheme(.dark)
}

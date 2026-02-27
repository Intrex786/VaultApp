// AllItemsView.swift
// Password Manager — Full Vault List with Search & Swipe Actions

import SwiftUI

struct AllItemsView: View {
    @Binding var showNewItemSheet: Bool
    @EnvironmentObject private var vm: VaultViewModel

    @State private var searchText        = ""
    @State private var selectedCategory: ItemCategory? = nil
    @State private var sortOrder:        SortOrder = .recentlyModified
    @State private var selectedItem:     DisplayVaultItem? = nil
    @State private var showDeleteDialog  = false
    @State private var pendingDeleteID:  UUID? = nil

    private var filteredItems: [DisplayVaultItem] {
        var r = vm.items
        if let cat = selectedCategory { r = r.filter { $0.category == cat } }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            r = r.filter { $0.title.lowercased().contains(q) || $0.username.lowercased().contains(q) }
        }
        switch sortOrder {
        case .alphabetical:     r.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .recentlyModified: r.sort { $0.lastModified > $1.lastModified }
        case .category:         r.sort { $0.category.rawValue < $1.category.rawValue }
        case .favourites:       r.sort { ($0.isFavourite ? 0 : 1) < ($1.isFavourite ? 0 : 1) }
        }
        return r
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.obsidianBase.ignoresSafeArea()
                VStack(spacing: 0) {
                    headerBar
                    categoryFilterBar.padding(.top, AppSpacing.xs)
                    Divider().background(Color.obsidianBorder).padding(.top, AppSpacing.xs)
                    itemListContent
                }
                FABButton { showNewItemSheet = true }
                    .padding(.trailing, AppSpacing.lg).padding(.bottom, 80)
            }
            .navigationDestination(item: $selectedItem) { ItemDetailView(item: $0) }
            .confirmationDialog("Delete Item?", isPresented: $showDeleteDialog, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let id = pendingDeleteID { Task { await vm.deleteItem(id: id) } }
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This action cannot be undone.") }
        }
    }

    // MARK: Header

    private var headerBar: some View {
        HStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Vault").font(AppFont.displayMedium).foregroundStyle(Color.textPrimary)
                Text("\(vm.items.count) items").font(AppFont.bodySmall).foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Menu {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Button {
                        withAnimation(AppAnimation.spring) { sortOrder = order }
                        AppHaptics.selection()
                    } label: {
                        HStack { Text(order.label); if sortOrder == order { Image(systemName: "checkmark") } }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 16, weight: .medium)).foregroundStyle(Color.textSecondary)
                    .frame(width: 36, height: 36).background(Circle().fill(Color.obsidianSurface))
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(.horizontal, AppSpacing.md).padding(.top, AppSpacing.xl).padding(.bottom, AppSpacing.sm)
        .overlay(alignment: .bottom) {
            ObsidianSearchBar(text: $searchText).padding(.horizontal, AppSpacing.md).offset(y: 36)
        }
        .padding(.bottom, AppSpacing.xl)
    }

    // MARK: Category Bar

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                CategoryPill(label: "All", icon: "square.grid.2x2.fill", color: .accentIndigo,
                             isSelected: selectedCategory == nil) {
                    withAnimation(AppAnimation.spring) { selectedCategory = nil }; AppHaptics.selection()
                }
                ForEach(ItemCategory.allCases) { cat in
                    CategoryPill(label: cat.rawValue, icon: cat.icon, color: cat.color,
                                 isSelected: selectedCategory == cat) {
                        withAnimation(AppAnimation.spring) {
                            selectedCategory = (selectedCategory == cat) ? nil : cat
                        }
                        AppHaptics.selection()
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md).padding(.vertical, AppSpacing.xs)
        }
    }

    // MARK: List

    @ViewBuilder private var itemListContent: some View {
        if vm.isLoading {
            Spacer(); ProgressView().tint(Color.accentIndigo); Spacer()
        } else if filteredItems.isEmpty {
            emptyView
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { idx, item in
                        row(item, at: idx)
                        if item.id != filteredItems.last?.id {
                            Divider().background(Color.obsidianBorder).padding(.leading, 70)
                        }
                    }
                }
                .background(Color.obsidianSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color.obsidianBorder, lineWidth: 0.5))
                .padding(.horizontal, AppSpacing.md).padding(.top, AppSpacing.md).padding(.bottom, 120)
            }
        }
    }

    private func row(_ item: DisplayVaultItem, at index: Int) -> some View {
        Button { selectedItem = item } label: {
            VaultRow(item: item).staggeredAppear(index: index).background(Color.obsidianSurface)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                AppHaptics.destructive(); pendingDeleteID = item.id; showDeleteDialog = true
            } label: { Label("Delete", systemImage: "trash.fill") }.tint(Color.dangerRed)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                AppHaptics.impact(.medium); Task { await vm.toggleFavourite(item) }
            } label: {
                Label(item.isFavourite ? "Unfav" : "Fav",
                      systemImage: item.isFavourite ? "star.slash.fill" : "star.fill")
            }.tint(Color.warningAmber)
        }
        .contextMenu {
            Button { UIPasteboard.general.string = item.password; AppHaptics.success() } label: {
                Label("Copy Password", systemImage: "doc.on.doc.fill")
            }
            Button { UIPasteboard.general.string = item.username; AppHaptics.success() } label: {
                Label("Copy Username", systemImage: "person.crop.circle.fill")
            }
            Divider()
            Button { Task { await vm.toggleFavourite(item) } } label: {
                Label(item.isFavourite ? "Remove Favourite" : "Add to Favourites",
                      systemImage: item.isFavourite ? "star.slash" : "star")
            }
            Divider()
            Button(role: .destructive) {
                AppHaptics.destructive(); pendingDeleteID = item.id; showDeleteDialog = true
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    @ViewBuilder private var emptyView: some View {
        if searchText.isEmpty && selectedCategory == nil {
            EmptyStateView(icon: "rectangle.stack.badge.plus", title: "Vault is Empty",
                           subtitle: "Tap + to add your first item.")
        } else {
            EmptyStateView(icon: "magnifyingglass", title: "No Results",
                           subtitle: "Try a different search or filter.")
        }
    }
}

// MARK: - Category Pill

struct CategoryPill: View {
    let label: String; let icon: String; let color: Color
    let isSelected: Bool; let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold))
                Text(label).font(AppFont.labelMedium)
            }
            .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
            .padding(.horizontal, AppSpacing.sm).padding(.vertical, 7)
            .background(
                Capsule().fill(isSelected ? color.opacity(0.22) : Color.obsidianSurface)
                    .overlay(Capsule().stroke(isSelected ? color.opacity(0.5) : Color.obsidianBorder, lineWidth: 0.5))
            )
        }
        .buttonStyle(PressScaleStyle()).animation(AppAnimation.spring, value: isSelected)
    }
}

// MARK: - Sort Order

enum SortOrder: String, CaseIterable {
    case alphabetical = "A–Z", recentlyModified = "Recently Modified"
    case category = "Category", favourites = "Favourites First"
    var label: String { rawValue }
}

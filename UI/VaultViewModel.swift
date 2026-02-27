// VaultViewModel.swift
// Central ObservableObject bridging the Security layer to the UI.

import SwiftUI
import CryptoKit

// MARK: - Persisted Item Payload

struct ItemPayload: Codable {
    var title:      String
    var username:   String
    var password:   String
    var notes:      String
    var category:   String
    var isPinned:   Bool
    var isFavourite: Bool
}

// MARK: - VaultViewModel

@MainActor
final class VaultViewModel: ObservableObject {

    static let shared = VaultViewModel()

    @Published var items:        [DisplayVaultItem] = []
    @Published var isUnlocked:   Bool = false
    @Published var isOnboarded:  Bool = false
    @Published var isLoading:    Bool = false
    @Published var errorMessage: String? = nil

    private var symmetricKey: SymmetricKey?
    private let keychain = KeychainManager()
    private let biometric = BiometricGate()

    private init() {}

    // MARK: - Boot Check

    func checkSetup() async {
        isOnboarded = await keychain.exists(account: "master.salt")
    }

    // MARK: - First-Time Setup

    func setup(masterPassword: String) async throws {
        let salt    = CryptoEngine.generateSalt()
        let key     = try await CryptoEngine.deriveKey(from: masterPassword, salt: salt)
        let keyData = key.withUnsafeBytes { Data($0) }
        try await keychain.save(salt,    account: "master.salt")
        try await keychain.save(keyData, account: "vault.key")
        symmetricKey = key
        isOnboarded  = true
        isUnlocked   = true
    }

    // MARK: - Unlock (biometric each launch)

    func unlock() async {
        do {
            try await biometric.authenticateWithFallback(reason: "Unlock your vault")
            let keyData  = try await keychain.load(account: "vault.key")
            symmetricKey = SymmetricKey(data: keyData)
            isUnlocked   = true
            await loadItems()
        } catch {
            errorMessage = (error as? BiometricError)?.errorDescription
                        ?? error.localizedDescription
        }
    }

    // MARK: - Lock

    func lock() {
        symmetricKey = nil
        isUnlocked   = false
        items        = []
    }

    // MARK: - Load & Decrypt All Items

    func loadItems() async {
        guard let key = symmetricKey else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let snapshots = try await VaultStore.shared.fetch()
            var result: [DisplayVaultItem] = []
            for snap in snapshots {
                guard
                    let encData = snap["encryptedData"] as? Data,
                    let iv      = snap["iv"]            as? Data,
                    let id      = snap["id"]            as? UUID,
                    let created = snap["createdAt"]     as? Date
                else { continue }
                do {
                    let plain   = try await CryptoEngine.decrypt(encData, iv: iv, using: key)
                    let payload = try JSONDecoder().decode(ItemPayload.self, from: plain)
                    let cat     = ItemCategory(rawValue: payload.category) ?? .login
                    result.append(DisplayVaultItem(
                        id:           id,
                        title:        payload.title,
                        username:     payload.username,
                        password:     payload.password,
                        category:     cat,
                        isPinned:     payload.isPinned,
                        iconName:     cat.icon,
                        iconColor:    cat.color,
                        lastModified: created,
                        isFavourite:  payload.isFavourite
                    ))
                } catch { continue }
            }
            items = result
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Add Item

    func addItem(
        title:    String,
        username: String,
        password: String,
        notes:    String = "",
        category: ItemCategory,
        isPinned: Bool = false
    ) async throws {
        guard let key = symmetricKey else { return }
        let payload = ItemPayload(
            title: title, username: username, password: password,
            notes: notes, category: category.rawValue,
            isPinned: isPinned, isFavourite: false
        )
        let data       = try JSONEncoder().encode(payload)
        let (enc, iv)  = try await CryptoEngine.encrypt(data, using: key)
        try await VaultStore.shared.insert(encryptedData: enc, iv: iv, vaultTag: category.rawValue)
        await loadItems()
    }

    // MARK: - Delete Item

    func deleteItem(id: UUID) async {
        do {
            try await VaultStore.shared.delete(id)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Toggle Favourite

    func toggleFavourite(_ item: DisplayVaultItem) async {
        await updatePayload(for: item.id) { $0.isFavourite.toggle() }
    }

    // MARK: - Toggle Pin

    func togglePin(_ item: DisplayVaultItem) async {
        await updatePayload(for: item.id) { $0.isPinned.toggle() }
    }

    // MARK: - Private: Patch Payload

    private func updatePayload(for id: UUID, mutate: (inout ItemPayload) -> Void) async {
        guard let key = symmetricKey else { return }
        do {
            let snaps = try await VaultStore.shared.fetch()
            guard
                let snap    = snaps.first(where: { $0["id"] as? UUID == id }),
                let encData = snap["encryptedData"] as? Data,
                let iv      = snap["iv"]            as? Data
            else { return }
            let plain       = try await CryptoEngine.decrypt(encData, iv: iv, using: key)
            var payload     = try JSONDecoder().decode(ItemPayload.self, from: plain)
            mutate(&payload)
            let newData     = try JSONEncoder().encode(payload)
            let (newEnc, newIV) = try await CryptoEngine.encrypt(newData, using: key)
            try await VaultStore.shared.update(id, encryptedData: newEnc, iv: newIV)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Security Score

    var securityScore: Int {
        guard !items.isEmpty else { return 100 }
        let scores = items.map { passwordScore($0.password) }
        return scores.reduce(0, +) / scores.count
    }

    private func passwordScore(_ pwd: String) -> Int {
        var s = 0
        if pwd.count >= 16 { s += 35 }
        else if pwd.count >= 12 { s += 25 }
        else if pwd.count >= 8  { s += 10 }
        if pwd.rangeOfCharacter(from: .uppercaseLetters) != nil  { s += 20 }
        if pwd.rangeOfCharacter(from: .decimalDigits)   != nil  { s += 20 }
        if pwd.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()-_=+[]{}|;:,.<>?")) != nil { s += 25 }
        return min(s, 100)
    }

    // Watchtower-style health counts
    var weakCount:    Int { items.filter { passwordScore($0.password) < 50 }.count }
    var reusedCount:  Int {
        let pwds = items.map { $0.password }
        return items.filter { item in pwds.filter { $0 == item.password }.count > 1 }.count
    }
}

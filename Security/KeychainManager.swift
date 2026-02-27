import Foundation
import Security

// MARK: - Errors

enum KeychainError: LocalizedError {
    case itemNotFound
    case duplicateItem
    case unexpectedData
    case unhandledError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .itemNotFound:           return "Item not found in Keychain."
        case .duplicateItem:          return "A duplicate item already exists in Keychain."
        case .unexpectedData:         return "Unexpected data format retrieved from Keychain."
        case .unhandledError(let s):  return "Keychain OSStatus error: \(s)."
        }
    }
}

// MARK: - KeychainManager

/// Thin async wrapper over the Security framework.
/// All items are stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
/// — they are never migrated to a new device and require an unlocked screen.
struct KeychainManager {

    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "com.d1.vault") {
        self.service = service
    }

    // MARK: - Save (upsert)

    /// Saves `data` for `account`. Overwrites silently if a previous value exists.
    func save(_ data: Data, account: String) async throws {
        let query: [CFString: Any] = [
            kSecClass:          kSecClassGenericPassword,
            kSecAttrService:    service,
            kSecAttrAccount:    account,
            kSecValueData:      data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            // Update in place rather than delete+add to avoid a brief missing-item window.
            try await update(data, account: account)
        default:
            throw KeychainError.unhandledError(status)
        }
    }

    // MARK: - Load

    /// Retrieves the raw `Data` stored under `account`.
    func load(account: String) async throws -> Data {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { throw KeychainError.unexpectedData }
            return data
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unhandledError(status)
        }
    }

    // MARK: - Update

    /// Updates an existing Keychain entry. Throws `itemNotFound` if no entry exists.
    func update(_ data: Data, account: String) async throws {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        let attributes: [CFString: Any] = [
            kSecValueData:      data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status == errSecSuccess else {
            throw status == errSecItemNotFound
                ? KeychainError.itemNotFound
                : KeychainError.unhandledError(status)
        }
    }

    // MARK: - Delete

    /// Deletes the entry for `account`. Succeeds silently if the item does not exist.
    func delete(account: String) async throws {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status)
        }
    }

    // MARK: - Existence Check

    /// Returns `true` if an entry exists for `account` without loading its data.
    func exists(account: String) async -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecMatchLimit:  kSecMatchLimitOne,
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Convenience: Symmetric Key

    /// Persists a CryptoKit `SymmetricKey` as raw bytes.
    func saveKey(_ key: consuming some ContiguousBytes, account: String) async throws {
        let data = key.withUnsafeBytes { Data($0) }
        try await save(data, account: account)
    }

    /// Loads raw bytes from Keychain. The caller is responsible for constructing the key type.
    func loadRawKey(account: String) async throws -> Data {
        try await load(account: account)
    }
}

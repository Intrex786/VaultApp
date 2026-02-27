import Foundation
import CryptoKit

// MARK: - Errors

enum CryptoError: LocalizedError {
    case invalidInput
    case encryptionFailed
    case decryptionFailed
    case invalidCiphertext

    var errorDescription: String? {
        switch self {
        case .invalidInput:        return "Invalid input data for cryptographic operation."
        case .encryptionFailed:    return "AES-GCM encryption failed."
        case .decryptionFailed:    return "AES-GCM decryption failed."
        case .invalidCiphertext:   return "Ciphertext is malformed or too short."
        }
    }
}

// MARK: - CryptoEngine

struct CryptoEngine {

    // AES-GCM tag is always 16 bytes; key is 256-bit (32 bytes).
    private static let tagByteCount:  Int = 16
    private static let saltByteCount: Int = 32
    private static let keyByteCount:  Int = 32

    // MARK: Key Derivation (HKDF-SHA256)

    /// Derives a 256-bit symmetric key from a UTF-8 password + random salt via HKDF-SHA256.
    static func deriveKey(from password: String, salt: Data) async throws -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8), !passwordData.isEmpty else {
            throw CryptoError.invalidInput
        }
        let ikm = SymmetricKey(data: passwordData)
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: ikm,
            salt: salt,
            info: Data("D1-vault-key-v1".utf8),
            outputByteCount: keyByteCount
        )
    }

    // MARK: Encryption

    /// Encrypts plaintext with AES-GCM-256.
    /// - Returns: `ciphertext` = encrypted bytes + 16-byte auth tag; `iv` = 12-byte nonce.
    static func encrypt(_ plaintext: Data, using key: SymmetricKey) async throws -> (ciphertext: Data, iv: Data) {
        guard !plaintext.isEmpty else { throw CryptoError.invalidInput }
        do {
            let nonce  = AES.GCM.Nonce()
            let sealed = try AES.GCM.seal(plaintext, using: key, nonce: nonce)
            let blob   = sealed.ciphertext + sealed.tag   // tag appended for compact storage
            return (blob, Data(nonce))
        } catch {
            throw CryptoError.encryptionFailed
        }
    }

    // MARK: Decryption

    /// Decrypts a blob produced by `encrypt(_:using:)`.
    /// - Parameters:
    ///   - ciphertext: encrypted bytes + 16-byte appended auth tag
    ///   - iv:         12-byte nonce produced during encryption
    static func decrypt(_ ciphertext: Data, iv: Data, using key: SymmetricKey) async throws -> Data {
        guard ciphertext.count > tagByteCount else {
            throw CryptoError.invalidCiphertext
        }
        do {
            let tag       = ciphertext.suffix(tagByteCount)
            let cipher    = ciphertext.dropLast(tagByteCount)
            let nonce     = try AES.GCM.Nonce(data: iv)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: cipher, tag: tag)
            return try AES.GCM.open(sealedBox, using: key)
        } catch let e as CryptoError {
            throw e
        } catch {
            throw CryptoError.decryptionFailed
        }
    }

    // MARK: Utilities

    static func generateSalt() -> Data {
        generateRandomBytes(count: saltByteCount)
    }

    static func generateRandomBytes(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }
}

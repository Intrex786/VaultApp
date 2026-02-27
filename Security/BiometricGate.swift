import Foundation
import LocalAuthentication

// MARK: - Errors

enum BiometricError: LocalizedError {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case cancelled
    case lockout
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:          return "Biometric authentication is not available on this device."
        case .notEnrolled:           return "No biometric credentials are enrolled. Please set up Face ID or Touch ID."
        case .authenticationFailed:  return "Authentication failed. Please try again."
        case .cancelled:             return "Authentication was cancelled."
        case .lockout:               return "Biometrics are locked out. Use your device passcode to unlock."
        case .unknown(let e):        return e.localizedDescription
        }
    }
}

// MARK: - BiometricGate

/// Actor-isolated gate that enforces Face ID / Touch ID before vault access.
actor BiometricGate {

    // Each call gets a fresh LAContext so invalidation cannot affect subsequent checks.
    private func makeContext() -> LAContext { LAContext() }

    // MARK: Availability

    /// Returns `true` if biometric hardware is present and enrolled.
    func isAvailable() -> Bool {
        makeContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    /// Returns the enrolled biometry type (.faceID / .touchID / .none).
    func biometryType() -> LABiometryType {
        let ctx = makeContext()
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return .none
        }
        return ctx.biometryType
    }

    // MARK: Authentication – biometrics only

    /// Authenticates with Face ID / Touch ID. Throws `BiometricError` on failure.
    func authenticate(reason: String = "Unlock your vault") async throws {
        let ctx = makeContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw map(error)
        }
        try await evaluate(ctx, policy: .deviceOwnerAuthenticationWithBiometrics, reason: reason)
    }

    // MARK: Authentication – biometrics + passcode fallback

    /// Authenticates with biometrics; falls back to device passcode if unavailable or locked out.
    func authenticateWithFallback(reason: String = "Unlock your vault") async throws {
        let ctx = makeContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw map(error)
        }
        try await evaluate(ctx, policy: .deviceOwnerAuthentication, reason: reason)
    }

    // MARK: Invalidation

    /// Explicitly invalidates the current LA session (e.g. on app background).
    func invalidate() {
        makeContext().invalidate()
    }

    // MARK: Private

    private func evaluate(
        _ ctx: LAContext,
        policy: LAPolicy,
        reason: String
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ctx.evaluatePolicy(policy, localizedReason: reason) { success, authError in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: self.map(authError as NSError?))
                }
            }
        }
    }

    private func map(_ error: NSError?) -> BiometricError {
        guard let error else { return .authenticationFailed }
        switch LAError.Code(rawValue: error.code) {
        case .biometryNotAvailable:                     return .notAvailable
        case .biometryNotEnrolled:                      return .notEnrolled
        case .authenticationFailed:                     return .authenticationFailed
        case .userCancel, .appCancel, .systemCancel:    return .cancelled
        case .biometryLockout:                          return .lockout
        default:                                        return .unknown(error)
        }
    }
}

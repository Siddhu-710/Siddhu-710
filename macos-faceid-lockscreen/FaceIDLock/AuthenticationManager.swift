import LocalAuthentication

/// Device-owner authentication, abstracted so the view model can be tested without system UI.
nonisolated protocol DeviceOwnerAuthenticating: Sendable {
    func availability() -> AuthenticationAvailability
    func authenticate(reason: String) async -> AuthenticationOutcome
}

/// Performs real authentication through Apple's LocalAuthentication framework.
///
/// Uses `.deviceOwnerAuthentication`, which lets macOS choose the best method it has — Touch ID,
/// an Apple Watch, or the account password — in its own secure system dialog. This app never
/// sees the password or any biometric data; it only learns whether the owner was verified.
nonisolated struct AuthenticationManager: DeviceOwnerAuthenticating {
    private static let policy: LAPolicy = .deviceOwnerAuthentication

    func availability() -> AuthenticationAvailability {
        let context = LAContext()

        var ownerError: NSError?
        let canAuthenticate = context.canEvaluatePolicy(Self.policy, error: &ownerError)

        var biometryError: NSError?
        let isBiometryReady = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &biometryError)

        // `biometryType` is only meaningful after a `canEvaluatePolicy` call.
        return AuthenticationAvailability(
            canAuthenticate: canAuthenticate,
            biometry: BiometryKind(context.biometryType),
            isBiometryReady: isBiometryReady,
            unavailableReason: canAuthenticate ? nil : Self.unavailableReason(for: ownerError)
        )
    }

    /// Presents the system authentication dialog. Cancelling the calling task dismisses it.
    ///
    /// - Parameter reason: Completes the sentence "<App> is trying to …", e.g. "unlock the demo".
    func authenticate(reason: String) async -> AuthenticationOutcome {
        // A fresh context per attempt, so a previous success is never silently reused.
        let context = LAContext()
        context.localizedCancelTitle = String(localized: "Cancel")

        var error: NSError?
        guard context.canEvaluatePolicy(Self.policy, error: &error) else {
            return .unavailable(reason: Self.unavailableReason(for: error))
        }

        return await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<AuthenticationOutcome, Never>) in
                context.evaluatePolicy(Self.policy, localizedReason: reason) { success, error in
                    continuation.resume(returning: success ? .success : Self.outcome(for: error))
                }
            }
        } onCancel: {
            context.invalidate()
        }
    }

    // MARK: - Error mapping

    /// Maps LocalAuthentication errors to lock-screen outcomes.
    static func outcome(for error: Error?) -> AuthenticationOutcome {
        guard let error else {
            return .failed(reason: String(localized: "Authentication didn't complete. Please try again."))
        }
        guard let laError = error as? LAError else {
            return .failed(reason: error.localizedDescription)
        }

        switch laError.code {
        case .userCancel, .appCancel, .systemCancel, .userFallback:
            return .cancelled
        case .authenticationFailed:
            return .failed(reason: String(localized: "Your identity couldn't be verified. Please try again."))
        case .biometryLockout:
            return .failed(reason: String(localized: "Touch ID is locked after too many attempts. Use your password to unlock it."))
        case .invalidContext:
            return .failed(reason: String(localized: "The authentication session expired. Please try again."))
        case .passcodeNotSet, .notInteractive, .biometryNotAvailable, .biometryNotEnrolled:
            return .unavailable(reason: unavailableReason(for: laError))
        default:
            return .failed(reason: laError.localizedDescription)
        }
    }

    static func unavailableReason(for error: Error?) -> String {
        guard let laError = error as? LAError else {
            return error?.localizedDescription
                ?? String(localized: "Authentication isn't available on this Mac.")
        }
        switch laError.code {
        case .passcodeNotSet:
            return String(localized: "Set a login password for your Mac account to use authentication.")
        case .notInteractive:
            return String(localized: "macOS can't show the authentication dialog right now.")
        case .biometryNotAvailable, .biometryNotEnrolled:
            return String(localized: "Touch ID isn't available. Use your password instead.")
        default:
            return laError.localizedDescription
        }
    }
}

extension BiometryKind {
    nonisolated init(_ type: LABiometryType) {
        switch type {
        case .none:
            self = .unavailable
        case .touchID:
            self = .touchID
        case .faceID:
            self = .faceID
        default:
            self = .other
        }
    }
}

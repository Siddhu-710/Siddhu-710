import Foundation

/// The biometric sensor macOS reports for this Mac.
///
/// Macs have no Face ID hardware. On a MacBook Air with Apple silicon this is `.touchID`
/// (or `.unavailable` when the lid is closed and no Touch ID keyboard is attached).
nonisolated enum BiometryKind: Equatable, Sendable {
    case unavailable
    case touchID
    case faceID
    case other
}

/// What LocalAuthentication can do on this Mac right now.
nonisolated struct AuthenticationAvailability: Equatable, Sendable {
    /// Whether device-owner authentication (biometrics, Apple Watch, or the login password) can run.
    var canAuthenticate: Bool
    var biometry: BiometryKind
    /// Whether biometrics are enrolled and usable, as opposed to merely present.
    var isBiometryReady: Bool
    var unavailableReason: String?

    /// Used before the first real check; assumes the common case so the UI doesn't flash an error.
    static let assumed = AuthenticationAvailability(
        canAuthenticate: true,
        biometry: .unavailable,
        isBiometryReady: false,
        unavailableReason: nil
    )

    /// A short phrase for UI copy, e.g. "Touch ID or your password".
    var methodDescription: String {
        guard isBiometryReady else { return String(localized: "your password") }
        switch biometry {
        case .touchID:
            return String(localized: "Touch ID or your password")
        case .faceID:
            return String(localized: "Face ID or your password")
        case .unavailable, .other:
            return String(localized: "your password")
        }
    }
}

/// The result of one LocalAuthentication evaluation, reduced to what the lock screen needs.
nonisolated enum AuthenticationOutcome: Equatable, Sendable {
    case success
    case failed(reason: String)
    case cancelled
    case unavailable(reason: String)
}

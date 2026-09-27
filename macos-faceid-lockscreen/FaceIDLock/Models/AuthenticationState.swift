import Foundation

/// Every state the lock screen can be in.
///
/// The happy path is:
/// `locked → requestingCamera → searchingForFace → faceDetected → authenticating → authenticated → unlocked`
///
/// Everything else is a recoverable detour. Transitions are defined in one place,
/// ``AuthenticationStateMachine``, so the rules can be unit-tested without a camera or UI.
enum AuthenticationState: Equatable, Sendable {
    case locked
    case requestingCamera
    case searchingForFace
    case faceDetected
    case authenticating
    case authenticated
    case unlocked

    case cameraPermissionDenied
    case cameraUnavailable(reason: String)
    case authenticationFailed(reason: String)
    case authenticationCancelled
    case authenticationUnavailable(reason: String)
    case timeout

    /// States in which the camera may be (or is about to be) running.
    var usesCamera: Bool {
        switch self {
        case .requestingCamera, .searchingForFace:
            return true
        default:
            return false
        }
    }

    /// States from which a new face scan can be started.
    var canStartFaceScan: Bool {
        AuthenticationStateMachine.nextState(from: self, on: .startFaceScan) != nil
    }

    /// States from which the user can skip the face scan and go straight to system authentication.
    var canUsePasswordFallback: Bool {
        AuthenticationStateMachine.nextState(from: self, on: .beginAuthentication) != nil
            && self != .faceDetected
    }

    /// States where the view should offer a retry.
    var isRecoverableFailure: Bool {
        switch self {
        case .cameraPermissionDenied, .cameraUnavailable, .authenticationFailed,
             .authenticationCancelled, .authenticationUnavailable, .timeout:
            return true
        default:
            return false
        }
    }
}

/// Inputs that drive ``AuthenticationStateMachine``.
enum AuthenticationEvent: Equatable, Sendable {
    case startFaceScan
    case cameraAccessGranted
    case cameraAccessDenied
    case cameraFailed(reason: String)
    case faceFound
    case scanTimedOut
    case beginAuthentication
    case authenticationSucceeded
    case authenticationFailed(reason: String)
    case authenticationCancelled
    case authenticationUnavailable(reason: String)
    case finishUnlock
    case lock
}

/// Pure transition table for the lock screen. Returns `nil` for transitions that are not allowed,
/// which lets callers ignore stale or out-of-order events safely.
enum AuthenticationStateMachine {
    static func nextState(from state: AuthenticationState, on event: AuthenticationEvent) -> AuthenticationState? {
        switch (state, event) {
        // Locking is always allowed; it is how every flow is reset.
        case (_, .lock):
            return .locked

        // Starting (or restarting) a face scan.
        case (.locked, .startFaceScan),
             (.cameraPermissionDenied, .startFaceScan),
             (.cameraUnavailable, .startFaceScan),
             (.authenticationFailed, .startFaceScan),
             (.authenticationCancelled, .startFaceScan),
             (.authenticationUnavailable, .startFaceScan),
             (.timeout, .startFaceScan):
            return .requestingCamera

        // Camera setup.
        case (.requestingCamera, .cameraAccessGranted):
            return .searchingForFace
        case (.requestingCamera, .cameraAccessDenied):
            return .cameraPermissionDenied
        case (.requestingCamera, .cameraFailed(let reason)),
             (.searchingForFace, .cameraFailed(let reason)):
            return .cameraUnavailable(reason: reason)

        // Face search.
        case (.searchingForFace, .faceFound):
            return .faceDetected
        case (.searchingForFace, .scanTimedOut):
            return .timeout

        // System authentication, either after a detected face or as a password fallback.
        case (.faceDetected, .beginAuthentication),
             (.locked, .beginAuthentication),
             (.requestingCamera, .beginAuthentication),
             (.searchingForFace, .beginAuthentication),
             (.cameraPermissionDenied, .beginAuthentication),
             (.cameraUnavailable, .beginAuthentication),
             (.authenticationFailed, .beginAuthentication),
             (.authenticationCancelled, .beginAuthentication),
             (.timeout, .beginAuthentication):
            return .authenticating

        // Authentication results.
        case (.authenticating, .authenticationSucceeded):
            return .authenticated
        case (.authenticating, .authenticationFailed(let reason)):
            return .authenticationFailed(reason: reason)
        case (.authenticating, .authenticationCancelled):
            return .authenticationCancelled
        case (.authenticating, .authenticationUnavailable(let reason)):
            return .authenticationUnavailable(reason: reason)

        // Success animation finished.
        case (.authenticated, .finishUnlock):
            return .unlocked

        default:
            return nil
        }
    }
}

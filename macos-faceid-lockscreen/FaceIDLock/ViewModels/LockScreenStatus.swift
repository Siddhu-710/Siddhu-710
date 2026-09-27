import Foundation

/// Visual phase of the scan glyph.
enum GlyphPhase: Equatable {
    case idle
    case searching
    case detected
    case authenticating
    case success
    case failure
    case inactive
}

/// Buttons the lock screen can offer.
enum LockScreenAction: Hashable, Identifiable {
    case scanFace
    case tryAgain
    case usePassword
    case cancel
    case openCameraSettings

    var id: Self { self }

    func title(for availability: AuthenticationAvailability) -> String {
        switch self {
        case .scanFace:
            return String(localized: "Scan Face")
        case .tryAgain:
            return String(localized: "Try Again")
        case .usePassword:
            return availability.isBiometryReady && availability.biometry == .touchID
                ? String(localized: "Touch ID or Password")
                : String(localized: "Use Password")
        case .cancel:
            return String(localized: "Cancel")
        case .openCameraSettings:
            return String(localized: "Open Camera Settings")
        }
    }

    var systemImage: String {
        switch self {
        case .scanFace: return "viewfinder"
        case .tryAgain: return "arrow.clockwise"
        case .usePassword: return "key.fill"
        case .cancel: return "xmark"
        case .openCameraSettings: return "gearshape"
        }
    }
}

/// Everything the lock screen shows for a given state: copy, glyph phase, and buttons.
///
/// Pure presentation logic, derived from the view model's published values and unit-tested.
struct LockScreenStatus: Equatable {
    var title: String
    var detail: String?
    var glyph: GlyphPhase
    var actions: [LockScreenAction]
    /// Triggered by Return.
    var defaultAction: LockScreenAction?
    /// Triggered by Escape.
    var cancelAction: LockScreenAction?

    init(
        title: String,
        detail: String?,
        glyph: GlyphPhase,
        actions: [LockScreenAction] = [],
        defaultAction: LockScreenAction? = nil,
        cancelAction: LockScreenAction? = nil
    ) {
        self.title = title
        self.detail = detail
        self.glyph = glyph
        self.actions = actions
        self.defaultAction = defaultAction
        self.cancelAction = cancelAction
    }

    init(state: AuthenticationState, guidance: FaceGuidance, availability: AuthenticationAvailability) {
        let method = availability.methodDescription

        switch state {
        case .locked:
            self.init(
                title: String(localized: "Locked"),
                detail: String(localized: "Press Return to scan your face"),
                glyph: .idle,
                actions: [.scanFace, .usePassword],
                defaultAction: .scanFace
            )

        case .requestingCamera:
            self.init(
                title: String(localized: "Starting camera…"),
                detail: String(localized: "Frames are analyzed on this Mac and never saved"),
                glyph: .idle,
                actions: [.usePassword, .cancel],
                defaultAction: .usePassword,
                cancelAction: .cancel
            )

        case .searchingForFace:
            let title: String
            switch guidance {
            case .noFace: title = String(localized: "Looking for your face…")
            case .moveCloser: title = String(localized: "Move a little closer")
            case .ready: title = String(localized: "Hold still…")
            }
            self.init(
                title: title,
                detail: String(localized: "Face ID-style demo · Press Return to use \(method)"),
                glyph: .searching,
                actions: [.usePassword, .cancel],
                defaultAction: .usePassword,
                cancelAction: .cancel
            )

        case .faceDetected:
            self.init(
                title: String(localized: "Face detected"),
                detail: String(localized: "Hold still…"),
                glyph: .detected
            )

        case .authenticating:
            self.init(
                title: String(localized: "Authenticating…"),
                detail: String(localized: "Confirm with \(method)"),
                glyph: .authenticating
            )

        case .authenticated, .unlocked:
            self.init(
                title: String(localized: "Welcome"),
                detail: String(localized: "Unlocking…"),
                glyph: .success
            )

        case .cameraPermissionDenied:
            self.init(
                title: String(localized: "Camera access is off"),
                detail: String(localized: "Allow Face ID Lock in System Settings › Privacy & Security › Camera, or use \(method)."),
                glyph: .inactive,
                actions: [.openCameraSettings, .usePassword],
                defaultAction: .usePassword
            )

        case .cameraUnavailable(let reason):
            self.init(
                title: String(localized: "Camera unavailable"),
                detail: reason,
                glyph: .inactive,
                actions: [.tryAgain, .usePassword],
                defaultAction: .usePassword
            )

        case .authenticationFailed(let reason):
            self.init(
                title: String(localized: "Authentication failed"),
                detail: reason,
                glyph: .failure,
                actions: [.tryAgain, .usePassword],
                defaultAction: .tryAgain
            )

        case .authenticationCancelled:
            self.init(
                title: String(localized: "Authentication cancelled"),
                detail: String(localized: "Scan again or use \(method)."),
                glyph: .idle,
                actions: [.tryAgain, .usePassword],
                defaultAction: .tryAgain
            )

        case .authenticationUnavailable(let reason):
            self.init(
                title: String(localized: "Authentication unavailable"),
                detail: reason,
                glyph: .inactive,
                actions: [.tryAgain],
                defaultAction: .tryAgain
            )

        case .timeout:
            self.init(
                title: String(localized: "No face detected"),
                detail: String(localized: "Make sure your face is well lit and in view of the camera."),
                glyph: .failure,
                actions: [.tryAgain, .usePassword],
                defaultAction: .tryAgain
            )
        }
    }
}

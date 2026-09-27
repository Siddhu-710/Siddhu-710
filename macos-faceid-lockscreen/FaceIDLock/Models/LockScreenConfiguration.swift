import CoreGraphics
import Foundation

/// UserDefaults keys shared by `@AppStorage` in the views and ``LockScreenConfiguration``.
enum PreferenceKey {
    static let displayName = "displayName"
    static let startsScanAutomatically = "startsScanAutomatically"
    static let opensInFullScreen = "opensInFullScreen"
    static let faceSearchTimeoutSeconds = "faceSearchTimeoutSeconds"
    static let textSize = "textSize"
}

enum PreferenceDefaults {
    static let startsScanAutomatically = true
    static let opensInFullScreen = true
    static let faceSearchTimeoutSeconds = 10
    static let timeoutChoices = [5, 10, 15, 30]

    static func register(in defaults: UserDefaults = .standard) {
        defaults.register(defaults: [
            PreferenceKey.startsScanAutomatically: startsScanAutomatically,
            PreferenceKey.opensInFullScreen: opensInFullScreen,
            PreferenceKey.faceSearchTimeoutSeconds: faceSearchTimeoutSeconds,
            PreferenceKey.textSize: TextSizePreference.standard.rawValue,
        ])
    }
}

/// An in-app text size preference.
///
/// macOS does not expose a system-wide Dynamic Type setting to SwiftUI the way iOS does, so the
/// lock screen multiplies this with any `dynamicTypeSize` the environment provides.
enum TextSizePreference: String, CaseIterable, Identifiable, Sendable {
    case standard
    case large
    case extraLarge

    var id: String { rawValue }

    var scale: CGFloat {
        switch self {
        case .standard: return 1.0
        case .large: return 1.15
        case .extraLarge: return 1.3
        }
    }

    var title: String {
        switch self {
        case .standard: return String(localized: "Standard")
        case .large: return String(localized: "Large")
        case .extraLarge: return String(localized: "Extra Large")
        }
    }
}

/// Timing and threshold knobs for the lock screen flow.
struct LockScreenConfiguration: Equatable, Sendable {
    var startsScanAutomatically: Bool
    /// How long to look for a face before giving up and turning the camera off.
    var faceSearchTimeout: Duration
    /// Consecutive analysed frames that must contain a qualifying face (debounces flicker).
    var requiredConsecutiveDetections: Int
    /// Fraction of the frame height the face must fill.
    var minimumFaceHeight: CGFloat
    /// How long "Face detected" stays on screen before system authentication starts.
    var faceDetectedPause: Duration
    /// How long the success checkmark stays on screen before unlocking.
    var successPause: Duration
    /// Delay before automatically scanning again after locking.
    var relockScanDelay: Duration

    static let standard = LockScreenConfiguration(
        startsScanAutomatically: PreferenceDefaults.startsScanAutomatically,
        faceSearchTimeout: .seconds(PreferenceDefaults.faceSearchTimeoutSeconds),
        requiredConsecutiveDetections: 3,
        minimumFaceHeight: FaceDetectionResult.defaultMinimumFaceHeight,
        faceDetectedPause: .milliseconds(700),
        successPause: .milliseconds(1100),
        relockScanDelay: .milliseconds(600)
    )

    /// Reads the user-adjustable values from `defaults`, falling back to ``standard``.
    static func load(from defaults: UserDefaults = .standard) -> LockScreenConfiguration {
        var configuration = LockScreenConfiguration.standard
        if let startsAutomatically = defaults.object(forKey: PreferenceKey.startsScanAutomatically) as? Bool {
            configuration.startsScanAutomatically = startsAutomatically
        }
        let seconds = defaults.integer(forKey: PreferenceKey.faceSearchTimeoutSeconds)
        if seconds > 0 {
            configuration.faceSearchTimeout = .seconds(seconds)
        }
        return configuration
    }
}

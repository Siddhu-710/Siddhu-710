import CoreGraphics
import Foundation
import XCTest
@testable import FaceIDLock

/// A controllable stand-in for the camera + Vision pipeline.
@MainActor
final class MockFaceScanner: FaceScanning {
    var cameraAuthorization: CameraAuthorization = .authorized
    var grantsAccessOnRequest = true
    var startError: Error?

    private(set) var requestAccessCount = 0
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private var onEvent: (@Sendable (FaceScanEvent) -> Void)?
    /// The most recent callback, kept even after `stopScanning()` to simulate late frames.
    private(set) var lastEventHandler: (@Sendable (FaceScanEvent) -> Void)?

    var isScanning: Bool { onEvent != nil }

    func requestCameraAccess() async -> Bool {
        requestAccessCount += 1
        cameraAuthorization = grantsAccessOnRequest ? .authorized : .denied
        return grantsAccessOnRequest
    }

    func startScanning(minimumFaceHeight: CGFloat, onEvent: @escaping @Sendable (FaceScanEvent) -> Void) async throws {
        startCount += 1
        if let startError {
            throw startError
        }
        self.onEvent = onEvent
        lastEventHandler = onEvent
    }

    func stopScanning() {
        stopCount += 1
        onEvent = nil
    }

    func emit(_ event: FaceScanEvent) {
        onEvent?(event)
    }

    func emitFace(height: CGFloat = 0.4) {
        emit(.detection(Self.face(height: height)))
    }

    static func face(height: CGFloat = 0.4) -> FaceDetectionResult {
        let bounds = CGRect(x: 0.3, y: 0.3, width: height * 0.75, height: height)
        return FaceDetectionResult.evaluate(faceBounds: [bounds], minimumFaceHeight: 0.12)
    }
}

/// A controllable stand-in for LocalAuthentication.
final class MockAuthenticator: DeviceOwnerAuthenticating, @unchecked Sendable {
    private let lock = NSLock()
    private var _outcome: AuthenticationOutcome
    private var _authenticateCount = 0
    private let _availability: AuthenticationAvailability

    init(
        outcome: AuthenticationOutcome = .success,
        availability: AuthenticationAvailability = AuthenticationAvailability(
            canAuthenticate: true,
            biometry: .touchID,
            isBiometryReady: true,
            unavailableReason: nil
        )
    ) {
        _outcome = outcome
        _availability = availability
    }

    var outcome: AuthenticationOutcome {
        get { lock.withLock { _outcome } }
        set { lock.withLock { _outcome = newValue } }
    }

    var authenticateCount: Int {
        lock.withLock { _authenticateCount }
    }

    func availability() -> AuthenticationAvailability {
        _availability
    }

    func authenticate(reason: String) async -> AuthenticationOutcome {
        lock.withLock {
            _authenticateCount += 1
            return _outcome
        }
    }
}

extension LockScreenConfiguration {
    /// No pauses, so tests run quickly and deterministically.
    static func testing(
        startsScanAutomatically: Bool = false,
        faceSearchTimeout: Duration = .seconds(30)
    ) -> LockScreenConfiguration {
        LockScreenConfiguration(
            startsScanAutomatically: startsScanAutomatically,
            faceSearchTimeout: faceSearchTimeout,
            requiredConsecutiveDetections: 2,
            minimumFaceHeight: 0.12,
            faceDetectedPause: .zero,
            successPause: .zero,
            relockScanDelay: .zero
        )
    }
}

extension XCTestCase {
    /// Polls `condition` on the main actor until it is true or `timeout` elapses.
    @MainActor
    func waitUntil(
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() > deadline {
                XCTFail("Timed out waiting for condition", file: file, line: line)
                return
            }
            try? await Task.sleep(for: .milliseconds(5))
        }
    }
}

import CoreGraphics

/// Events produced while the camera is scanning.
nonisolated enum FaceScanEvent: Sendable {
    case detection(FaceDetectionResult)
    case failure(CameraError)
}

/// What the view model needs from the camera + Vision pipeline. Mocked in unit tests.
@MainActor
protocol FaceScanning: AnyObject {
    var cameraAuthorization: CameraAuthorization { get }
    func requestCameraAccess() async -> Bool
    /// Starts the camera. `onEvent` may be called on any thread.
    func startScanning(minimumFaceHeight: CGFloat, onEvent: @escaping @Sendable (FaceScanEvent) -> Void) async throws
    func stopScanning()
}

/// Connects ``CameraManager`` (frames) to ``FaceDetectionManager`` (Vision).
@MainActor
final class FaceScanner: FaceScanning {
    private let camera: CameraManager
    /// Held strongly while scanning; AVFoundation only keeps a weak reference to the delegate.
    private var detector: FaceDetectionManager?

    init(camera: CameraManager = CameraManager()) {
        self.camera = camera
    }

    var cameraAuthorization: CameraAuthorization {
        camera.authorizationStatus
    }

    func requestCameraAccess() async -> Bool {
        await camera.requestAccess()
    }

    func startScanning(minimumFaceHeight: CGFloat, onEvent: @escaping @Sendable (FaceScanEvent) -> Void) async throws {
        let detector = FaceDetectionManager(minimumFaceHeight: minimumFaceHeight) { result in
            onEvent(.detection(result))
        }
        self.detector = detector
        try await camera.start(frameDelegate: detector) { error in
            onEvent(.failure(error))
        }
    }

    func stopScanning() {
        camera.stop()
        detector = nil
    }
}

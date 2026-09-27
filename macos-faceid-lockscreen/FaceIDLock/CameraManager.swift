import AVFoundation

/// Camera permission, decoupled from AVFoundation so the view model can be tested.
nonisolated enum CameraAuthorization: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted

    init(_ status: AVAuthorizationStatus) {
        switch status {
        case .authorized: self = .authorized
        case .notDetermined: self = .notDetermined
        case .denied: self = .denied
        case .restricted: self = .restricted
        @unknown default: self = .denied
        }
    }
}

nonisolated enum CameraError: LocalizedError, Equatable, Sendable {
    case noCameraAvailable
    case configurationFailed(String)
    case runtimeFailure(String)

    var errorDescription: String? {
        switch self {
        case .noCameraAvailable:
            return String(localized: "No camera was found. If your MacBook is closed in clamshell mode, open the lid or connect a camera.")
        case .configurationFailed(let detail):
            return String(localized: "The camera couldn't be started. \(detail)")
        case .runtimeFailure(let detail):
            return String(localized: "The camera stopped unexpectedly. \(detail)")
        }
    }
}

/// Owns the `AVCaptureSession`.
///
/// All session work happens on a private serial queue because `startRunning()` blocks and
/// AVFoundation expects configuration to be serialised. Frames are delivered to a delegate on a
/// separate queue and are never retained by this class.
nonisolated final class CameraManager: @unchecked Sendable {
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "FaceIDLock.CameraManager.session")
    private let frameQueue = DispatchQueue(label: "FaceIDLock.CameraManager.frames", qos: .userInitiated)

    // Mutable state below is only touched on `sessionQueue`.
    private var isConfigured = false
    private var runtimeErrorHandler: (@Sendable (CameraError) -> Void)?
    private var runtimeErrorObserver: NSObjectProtocol?

    init() {
        runtimeErrorObserver = NotificationCenter.default.addObserver(
            forName: .AVCaptureSessionRuntimeError,
            object: session,
            queue: nil
        ) { [weak self] notification in
            let error = notification.userInfo?[AVCaptureSessionErrorKey] as? Error
            let message = error?.localizedDescription ?? String(localized: "Unknown camera error.")
            guard let self else { return }
            self.sessionQueue.async {
                self.resetConfiguration()
                self.runtimeErrorHandler?(.runtimeFailure(message))
            }
        }
    }

    deinit {
        if let runtimeErrorObserver {
            NotificationCenter.default.removeObserver(runtimeErrorObserver)
        }
    }

    var authorizationStatus: CameraAuthorization {
        CameraAuthorization(AVCaptureDevice.authorizationStatus(for: .video))
    }

    /// Shows the system camera prompt the first time; afterwards returns the stored decision.
    func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    /// Configures the session if needed and starts streaming frames to `frameDelegate`.
    /// Returns once the camera is actually running.
    func start(
        frameDelegate: any AVCaptureVideoDataOutputSampleBufferDelegate & Sendable,
        onRuntimeError: @escaping @Sendable (CameraError) -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async {
                do {
                    try self.configureIfNeeded()
                    self.runtimeErrorHandler = onRuntimeError
                    self.videoOutput.setSampleBufferDelegate(frameDelegate, queue: self.frameQueue)
                    if !self.session.isRunning {
                        self.session.startRunning()
                    }
                    guard self.session.isRunning else {
                        self.videoOutput.setSampleBufferDelegate(nil, queue: nil)
                        self.runtimeErrorHandler = nil
                        throw CameraError.configurationFailed(String(localized: "The capture session did not start."))
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Stops the camera (and the green camera indicator). Safe to call repeatedly.
    func stop() {
        sessionQueue.async {
            self.runtimeErrorHandler = nil
            self.videoOutput.setSampleBufferDelegate(nil, queue: nil)
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    // MARK: - Session configuration (sessionQueue only)

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }
        guard let device = Self.preferredCamera() else { throw CameraError.noCameraAvailable }

        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            throw CameraError.configurationFailed(error.localizedDescription)
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        guard session.canAddInput(input) else {
            throw CameraError.configurationFailed(String(localized: "The camera input could not be added."))
        }
        session.addInput(input)

        // Face presence detection needs very little resolution; a small preset keeps Vision fast
        // and avoids handling more image data than necessary.
        if session.canSetSessionPreset(.vga640x480) {
            session.sessionPreset = .vga640x480
        } else if session.canSetSessionPreset(.medium) {
            session.sessionPreset = .medium
        }

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        guard session.canAddOutput(videoOutput) else {
            session.removeInput(input)
            throw CameraError.configurationFailed(String(localized: "The video output could not be added."))
        }
        session.addOutput(videoOutput)
        isConfigured = true
    }

    private func resetConfiguration() {
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        session.commitConfiguration()
        isConfigured = false
    }

    private static func preferredCamera() -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        return discovery.devices.first ?? AVCaptureDevice.default(for: .video)
    }
}

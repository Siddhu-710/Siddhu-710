import Foundation

/// Drives the lock screen: owns the state machine and coordinates the camera, Vision, and
/// LocalAuthentication.
///
/// Every state change goes through ``send(_:)``, which consults ``AuthenticationStateMachine``.
/// Async work (camera start-up, timeouts, authentication) is tagged with a scan generation so a
/// late callback from an abandoned attempt can never move the UI.
@MainActor
final class LockScreenViewModel: ObservableObject {
    @Published private(set) var state: AuthenticationState = .locked
    @Published private(set) var guidance: FaceGuidance = .noFace
    @Published private(set) var isCameraActive = false
    @Published private(set) var availability: AuthenticationAvailability = .assumed
    @Published private(set) var unlockedAt: Date?

    private let faceScanner: any FaceScanning
    private let authenticator: any DeviceOwnerAuthenticating
    private let loadConfiguration: @MainActor () -> LockScreenConfiguration
    private var configuration: LockScreenConfiguration

    private var scanTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var transitionTask: Task<Void, Never>?
    private var authenticationTask: Task<Void, Never>?

    private var scanGeneration = 0
    private var consecutiveQualifiedFrames = 0

    init(
        faceScanner: any FaceScanning,
        authenticator: any DeviceOwnerAuthenticating,
        loadConfiguration: @escaping @MainActor () -> LockScreenConfiguration = { LockScreenConfiguration.load() }
    ) {
        self.faceScanner = faceScanner
        self.authenticator = authenticator
        self.loadConfiguration = loadConfiguration
        self.configuration = loadConfiguration()
    }

    static func live() -> LockScreenViewModel {
        LockScreenViewModel(faceScanner: FaceScanner(), authenticator: AuthenticationManager())
    }

    var status: LockScreenStatus {
        LockScreenStatus(state: state, guidance: guidance, availability: availability)
    }

    // MARK: - Intents

    /// Call once when the lock screen appears.
    func start() {
        refreshAvailability()
        configuration = loadConfiguration()
        if configuration.startsScanAutomatically {
            beginFaceScan()
        }
    }

    func beginFaceScan() {
        guard state.canStartFaceScan else { return }
        cancelPendingWork()
        stopCamera()
        configuration = loadConfiguration()
        refreshAvailability()
        guard send(.startFaceScan) else { return }

        guidance = .noFace
        let generation = scanGeneration
        scanTask = Task { [weak self] in
            await self?.runFaceScan(generation: generation)
        }
    }

    /// Skips (or abandons) the face scan and asks macOS to authenticate the device owner.
    func usePassword() {
        guard state.canUsePasswordFallback else { return }
        cancelPendingWork()
        stopCamera()
        authenticate()
    }

    /// Stops an in-progress scan and returns to the idle lock screen without rescanning.
    func cancelScan() {
        guard state.usesCamera || state == .faceDetected else { return }
        cancelPendingWork()
        stopCamera()
        send(.lock)
    }

    /// Returns to the lock screen from anywhere, e.g. ⌘L or when the Mac sleeps.
    func lock(rescan: Bool = true) {
        cancelPendingWork()
        stopCamera()
        unlockedAt = nil
        guidance = .noFace
        send(.lock)

        configuration = loadConfiguration()
        guard rescan, configuration.startsScanAutomatically else { return }
        let delay = configuration.relockScanDelay
        transitionTask = Task { [weak self] in
            do { try await Task.sleep(for: delay) } catch { return }
            guard let self, self.state == .locked else { return }
            self.beginFaceScan()
        }
    }

    // MARK: - App and system lifecycle

    /// Turns the camera off when the app loses focus. System dialogs (the camera prompt and the
    /// authentication sheet) also deactivate the app, so those states are left alone.
    func appDidResignActive() {
        switch state {
        case .searchingForFace, .faceDetected:
            cancelPendingWork()
            stopCamera()
            send(.lock)
        case .locked:
            // Don't let a pending automatic rescan turn the camera on in the background.
            cancelPendingWork()
        default:
            break
        }
    }

    func appDidBecomeActive() {
        guard state == .locked else { return }
        configuration = loadConfiguration()
        if configuration.startsScanAutomatically {
            beginFaceScan()
        }
    }

    /// Like macOS, the demo locks whenever the Mac or its display goes to sleep.
    func systemWillSleep() {
        lock(rescan: false)
    }

    /// Rescans on wake only if the demo is frontmost; otherwise ``appDidBecomeActive()`` will.
    func systemDidWake(appIsActive: Bool) {
        lock(rescan: appIsActive)
    }

    // MARK: - Face scan

    private func runFaceScan(generation: Int) async {
        let granted: Bool
        switch faceScanner.cameraAuthorization {
        case .authorized:
            granted = true
        case .notDetermined:
            granted = await faceScanner.requestCameraAccess()
        case .denied, .restricted:
            granted = false
        }

        guard isCurrent(generation), state == .requestingCamera else { return }
        guard granted else {
            send(.cameraAccessDenied)
            return
        }

        do {
            try await faceScanner.startScanning(minimumFaceHeight: configuration.minimumFaceHeight) { [weak self] event in
                Task { @MainActor [weak self] in
                    self?.handle(event, generation: generation)
                }
            }
        } catch {
            guard isCurrent(generation), state == .requestingCamera else { return }
            send(.cameraFailed(reason: error.localizedDescription))
            return
        }

        guard isCurrent(generation), state == .requestingCamera else {
            // The attempt was abandoned while the camera was starting. Make sure it is off,
            // unless a newer scan now owns it.
            if !state.usesCamera {
                faceScanner.stopScanning()
            }
            return
        }

        isCameraActive = true
        send(.cameraAccessGranted)
        startTimeout(generation: generation)
    }

    private func handle(_ event: FaceScanEvent, generation: Int) {
        guard isCurrent(generation) else { return }
        switch event {
        case .failure(let error):
            guard state.usesCamera else { return }
            cancelPendingWork()
            stopCamera()
            send(.cameraFailed(reason: error.localizedDescription))
        case .detection(let result):
            process(result)
        }
    }

    private func process(_ result: FaceDetectionResult) {
        guard state == .searchingForFace else { return }
        if guidance != result.guidance {
            guidance = result.guidance
        }
        consecutiveQualifiedFrames = result.isQualified ? consecutiveQualifiedFrames + 1 : 0
        guard consecutiveQualifiedFrames >= configuration.requiredConsecutiveDetections else { return }

        // Face presence is all the camera is for, so turn it off before authenticating.
        cancelPendingWork()
        stopCamera()
        guard send(.faceFound) else { return }

        let pause = configuration.faceDetectedPause
        transitionTask = Task { [weak self] in
            do { try await Task.sleep(for: pause) } catch { return }
            guard let self, self.state == .faceDetected else { return }
            self.authenticate()
        }
    }

    private func startTimeout(generation: Int) {
        timeoutTask?.cancel()
        let timeout = configuration.faceSearchTimeout
        timeoutTask = Task { [weak self] in
            do { try await Task.sleep(for: timeout) } catch { return }
            guard let self, self.isCurrent(generation), self.state == .searchingForFace else { return }
            self.stopCamera()
            self.send(.scanTimedOut)
        }
    }

    // MARK: - Authentication

    private func authenticate() {
        guard send(.beginAuthentication) else { return }
        let reason = String(localized: "unlock the Face ID Lock demo")
        let authenticator = self.authenticator
        authenticationTask = Task { [weak self] in
            let outcome = await authenticator.authenticate(reason: reason)
            guard !Task.isCancelled, let self, self.state == .authenticating else { return }
            self.finishAuthentication(with: outcome)
        }
    }

    private func finishAuthentication(with outcome: AuthenticationOutcome) {
        switch outcome {
        case .success:
            send(.authenticationSucceeded)
            let pause = configuration.successPause
            transitionTask = Task { [weak self] in
                do { try await Task.sleep(for: pause) } catch { return }
                guard let self, self.state == .authenticated else { return }
                self.unlockedAt = Date()
                self.send(.finishUnlock)
            }
        case .failed(let reason):
            send(.authenticationFailed(reason: reason))
        case .cancelled:
            send(.authenticationCancelled)
        case .unavailable(let reason):
            refreshAvailability()
            send(.authenticationUnavailable(reason: reason))
        }
    }

    // MARK: - Helpers

    @discardableResult
    private func send(_ event: AuthenticationEvent) -> Bool {
        guard let next = AuthenticationStateMachine.nextState(from: state, on: event) else { return false }
        state = next
        return true
    }

    private func refreshAvailability() {
        availability = authenticator.availability()
    }

    private func isCurrent(_ generation: Int) -> Bool {
        generation == scanGeneration
    }

    /// Turns the camera off and invalidates callbacks from the current scan.
    private func stopCamera() {
        scanGeneration += 1
        consecutiveQualifiedFrames = 0
        timeoutTask?.cancel()
        timeoutTask = nil
        faceScanner.stopScanning()
        isCameraActive = false
    }

    /// Cancels timers, pending transitions and any in-flight authentication (which dismisses
    /// the system dialog).
    private func cancelPendingWork() {
        scanTask?.cancel()
        timeoutTask?.cancel()
        transitionTask?.cancel()
        authenticationTask?.cancel()
        scanTask = nil
        timeoutTask = nil
        transitionTask = nil
        authenticationTask = nil
    }
}

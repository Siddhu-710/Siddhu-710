import XCTest
@testable import FaceIDLock

@MainActor
final class LockScreenViewModelTests: XCTestCase {
    // Default arguments are evaluated outside the main actor, so the main-actor mock is
    // created in the body instead.
    private func makeViewModel(
        scanner: MockFaceScanner? = nil,
        authenticator: MockAuthenticator = MockAuthenticator(),
        configuration: LockScreenConfiguration = .testing()
    ) -> LockScreenViewModel {
        LockScreenViewModel(
            faceScanner: scanner ?? MockFaceScanner(),
            authenticator: authenticator,
            loadConfiguration: { configuration }
        )
    }

    func testFaceScanUnlocksAndTurnsCameraOff() async {
        let scanner = MockFaceScanner()
        let authenticator = MockAuthenticator(outcome: .success)
        let viewModel = makeViewModel(scanner: scanner, authenticator: authenticator)

        viewModel.beginFaceScan()
        XCTAssertEqual(viewModel.state, .requestingCamera)
        await waitUntil { viewModel.state == .searchingForFace }
        XCTAssertTrue(viewModel.isCameraActive)
        XCTAssertTrue(scanner.isScanning)

        scanner.emitFace()
        scanner.emitFace()

        await waitUntil { viewModel.state == .unlocked }
        XCTAssertEqual(authenticator.authenticateCount, 1)
        XCTAssertFalse(scanner.isScanning, "The camera must be off once a face has been found")
        XCTAssertFalse(viewModel.isCameraActive)
        XCTAssertNotNil(viewModel.unlockedAt)
    }

    func testSingleDetectionIsNotEnough() async {
        let scanner = MockFaceScanner()
        let viewModel = makeViewModel(scanner: scanner)

        viewModel.beginFaceScan()
        await waitUntil { viewModel.state == .searchingForFace }

        scanner.emitFace()
        scanner.emit(.detection(.empty))
        scanner.emitFace()
        await waitUntil { viewModel.guidance == .ready }

        XCTAssertEqual(viewModel.state, .searchingForFace, "Detections must be consecutive")
    }

    func testSmallFaceAsksUserToMoveCloser() async {
        let scanner = MockFaceScanner()
        let viewModel = makeViewModel(scanner: scanner)

        viewModel.beginFaceScan()
        await waitUntil { viewModel.state == .searchingForFace }

        scanner.emitFace(height: 0.05)
        await waitUntil { viewModel.guidance == .moveCloser }
        XCTAssertEqual(viewModel.state, .searchingForFace)
        XCTAssertEqual(viewModel.status.title, "Move a little closer")
    }

    func testDeniedCameraNeverStartsSession() async {
        let scanner = MockFaceScanner()
        scanner.cameraAuthorization = .denied
        let viewModel = makeViewModel(scanner: scanner)

        viewModel.beginFaceScan()
        await waitUntil { viewModel.state == .cameraPermissionDenied }

        XCTAssertEqual(scanner.startCount, 0)
        XCTAssertEqual(scanner.requestAccessCount, 0)
        XCTAssertTrue(viewModel.status.actions.contains(.openCameraSettings))
    }

    func testFirstLaunchRequestsCameraAccess() async {
        let scanner = MockFaceScanner()
        scanner.cameraAuthorization = .notDetermined
        let viewModel = makeViewModel(scanner: scanner)

        viewModel.beginFaceScan()
        await waitUntil { viewModel.state == .searchingForFace }
        XCTAssertEqual(scanner.requestAccessCount, 1)
    }

    func testDecliningCameraPromptShowsPermissionState() async {
        let scanner = MockFaceScanner()
        scanner.cameraAuthorization = .notDetermined
        scanner.grantsAccessOnRequest = false
        let viewModel = makeViewModel(scanner: scanner)

        viewModel.beginFaceScan()
        await waitUntil { viewModel.state == .cameraPermissionDenied }
        XCTAssertEqual(scanner.startCount, 0)
    }

    func testCameraStartFailureShowsCameraUnavailable() async {
        let scanner = MockFaceScanner()
        scanner.startError = CameraError.noCameraAvailable
        let viewModel = makeViewModel(scanner: scanner)

        viewModel.beginFaceScan()
        await waitUntil {
            if case .cameraUnavailable = viewModel.state { return true }
            return false
        }
        XCTAssertFalse(viewModel.isCameraActive)
    }

    func testCameraRuntimeErrorStopsScanning() async {
        let scanner = MockFaceScanner()
        let viewModel = makeViewModel(scanner: scanner)

        viewModel.beginFaceScan()
        await waitUntil { viewModel.state == .searchingForFace }

        scanner.emit(.failure(.runtimeFailure("unplugged")))
        await waitUntil {
            if case .cameraUnavailable = viewModel.state { return true }
            return false
        }
        XCTAssertFalse(scanner.isScanning)
        XCTAssertFalse(viewModel.isCameraActive)
    }

    func testTimeoutTurnsCameraOff() async {
        let scanner = MockFaceScanner()
        let viewModel = makeViewModel(scanner: scanner, configuration: .testing(faceSearchTimeout: .milliseconds(50)))

        viewModel.beginFaceScan()
        await waitUntil { viewModel.state == .timeout }

        XCTAssertFalse(scanner.isScanning)
        XCTAssertFalse(viewModel.isCameraActive)
        XCTAssertEqual(viewModel.status.defaultAction, .tryAgain)
    }

    func testPasswordFallbackSkipsFaceScan() async {
        let scanner = MockFaceScanner()
        let authenticator = MockAuthenticator(outcome: .success)
        let viewModel = makeViewModel(scanner: scanner, authenticator: authenticator)

        viewModel.beginFaceScan()
        await waitUntil { viewModel.state == .searchingForFace }

        viewModel.usePassword()
        XCTAssertFalse(scanner.isScanning, "Choosing the password fallback must stop the camera immediately")

        await waitUntil { viewModel.state == .unlocked }
        XCTAssertEqual(authenticator.authenticateCount, 1)
    }

    func testPasswordFallbackFromIdleLockScreen() async {
        let scanner = MockFaceScanner()
        let authenticator = MockAuthenticator(outcome: .success)
        let viewModel = makeViewModel(scanner: scanner, authenticator: authenticator)

        viewModel.usePassword()
        await waitUntil { viewModel.state == .unlocked }
        XCTAssertEqual(scanner.startCount, 0)
    }

    func testCancelledAuthentication() async {
        let authenticator = MockAuthenticator(outcome: .cancelled)
        let viewModel = makeViewModel(authenticator: authenticator)

        viewModel.usePassword()
        await waitUntil { viewModel.state == .authenticationCancelled }
        XCTAssertEqual(viewModel.status.defaultAction, .tryAgain)
    }

    func testFailedAuthenticationKeepsReason() async {
        let authenticator = MockAuthenticator(outcome: .failed(reason: "Nope"))
        let viewModel = makeViewModel(authenticator: authenticator)

        viewModel.usePassword()
        await waitUntil { viewModel.state == .authenticationFailed(reason: "Nope") }
        XCTAssertEqual(viewModel.status.detail, "Nope")
        XCTAssertEqual(viewModel.status.glyph, .failure)
    }

    func testUnavailableAuthentication() async {
        let authenticator = MockAuthenticator(outcome: .unavailable(reason: "No password set"))
        let viewModel = makeViewModel(authenticator: authenticator)

        viewModel.usePassword()
        await waitUntil { viewModel.state == .authenticationUnavailable(reason: "No password set") }
        XCTAssertFalse(viewModel.state.canUsePasswordFallback)
    }

    func testRetryAfterFailureScansAgain() async {
        let scanner = MockFaceScanner()
        let authenticator = MockAuthenticator(outcome: .failed(reason: "x"))
        let viewModel = makeViewModel(scanner: scanner, authenticator: authenticator)

        viewModel.usePassword()
        await waitUntil { viewModel.state == .authenticationFailed(reason: "x") }

        authenticator.outcome = .success
        viewModel.beginFaceScan()
        await waitUntil { viewModel.state == .searchingForFace }
        XCTAssertEqual(scanner.startCount, 1)
    }

    func testCancelScanReturnsToIdleWithCameraOff() async {
        let scanner = MockFaceScanner()
        let viewModel = makeViewModel(scanner: scanner)

        viewModel.beginFaceScan()
        await waitUntil { viewModel.state == .searchingForFace }

        viewModel.cancelScan()
        XCTAssertEqual(viewModel.state, .locked)
        XCTAssertFalse(scanner.isScanning)
    }

    func testLosingFocusWhileSearchingStopsCamera() async {
        let scanner = MockFaceScanner()
        let viewModel = makeViewModel(scanner: scanner)

        viewModel.beginFaceScan()
        await waitUntil { viewModel.state == .searchingForFace }

        viewModel.appDidResignActive()
        XCTAssertEqual(viewModel.state, .locked)
        XCTAssertFalse(scanner.isScanning)
    }

    func testLockFromUnlockedResetsState() async {
        let viewModel = makeViewModel()

        viewModel.usePassword()
        await waitUntil { viewModel.state == .unlocked }

        viewModel.lock()
        XCTAssertEqual(viewModel.state, .locked)
        XCTAssertNil(viewModel.unlockedAt)
    }

    func testLockRescansWhenAutomaticScanningIsOn() async {
        let scanner = MockFaceScanner()
        let viewModel = makeViewModel(scanner: scanner, configuration: .testing(startsScanAutomatically: true))

        viewModel.lock()
        await waitUntil { viewModel.state == .searchingForFace }
        XCTAssertEqual(scanner.startCount, 1)
    }

    func testSleepLocksWithoutRescanning() async {
        let scanner = MockFaceScanner()
        let viewModel = makeViewModel(scanner: scanner, configuration: .testing(startsScanAutomatically: true))

        viewModel.usePassword()
        await waitUntil { viewModel.state == .unlocked }

        viewModel.systemWillSleep()
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(viewModel.state, .locked)
        XCTAssertEqual(scanner.startCount, 0)
    }

    func testLateFramesFromAnAbandonedScanAreIgnored() async {
        let scanner = MockFaceScanner()
        let viewModel = makeViewModel(scanner: scanner)

        viewModel.beginFaceScan()
        await waitUntil { viewModel.state == .searchingForFace }
        let staleHandler = scanner.lastEventHandler

        // Cancel and start a fresh scan; frames still in flight from the first one must not count.
        viewModel.cancelScan()
        viewModel.beginFaceScan()
        await waitUntil { viewModel.state == .searchingForFace }

        staleHandler?(.detection(MockFaceScanner.face()))
        staleHandler?(.detection(MockFaceScanner.face()))
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(viewModel.state, .searchingForFace)
        XCTAssertEqual(scanner.startCount, 2)
    }
}

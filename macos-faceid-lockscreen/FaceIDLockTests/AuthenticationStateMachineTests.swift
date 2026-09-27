import XCTest
@testable import FaceIDLock

final class AuthenticationStateMachineTests: XCTestCase {
    private func next(_ state: AuthenticationState, _ event: AuthenticationEvent) -> AuthenticationState? {
        AuthenticationStateMachine.nextState(from: state, on: event)
    }

    func testHappyPathReachesUnlocked() {
        let events: [AuthenticationEvent] = [
            .startFaceScan,
            .cameraAccessGranted,
            .faceFound,
            .beginAuthentication,
            .authenticationSucceeded,
            .finishUnlock,
        ]
        let expected: [AuthenticationState] = [
            .requestingCamera,
            .searchingForFace,
            .faceDetected,
            .authenticating,
            .authenticated,
            .unlocked,
        ]

        var state = AuthenticationState.locked
        for (event, expectedState) in zip(events, expected) {
            guard let nextState = next(state, event) else {
                return XCTFail("\(event) should be allowed from \(state)")
            }
            XCTAssertEqual(nextState, expectedState)
            state = nextState
        }
    }

    func testCameraOutcomes() {
        XCTAssertEqual(next(.requestingCamera, .cameraAccessDenied), .cameraPermissionDenied)
        XCTAssertEqual(next(.requestingCamera, .cameraFailed(reason: "x")), .cameraUnavailable(reason: "x"))
        XCTAssertEqual(next(.searchingForFace, .cameraFailed(reason: "y")), .cameraUnavailable(reason: "y"))
        XCTAssertEqual(next(.searchingForFace, .scanTimedOut), .timeout)
    }

    func testAuthenticationOutcomes() {
        XCTAssertEqual(next(.authenticating, .authenticationFailed(reason: "r")), .authenticationFailed(reason: "r"))
        XCTAssertEqual(next(.authenticating, .authenticationCancelled), .authenticationCancelled)
        XCTAssertEqual(next(.authenticating, .authenticationUnavailable(reason: "u")), .authenticationUnavailable(reason: "u"))
    }

    func testLockIsAllowedFromEveryState() {
        let states: [AuthenticationState] = [
            .locked, .requestingCamera, .searchingForFace, .faceDetected, .authenticating,
            .authenticated, .unlocked, .cameraPermissionDenied, .cameraUnavailable(reason: ""),
            .authenticationFailed(reason: ""), .authenticationCancelled,
            .authenticationUnavailable(reason: ""), .timeout,
        ]
        for state in states {
            XCTAssertEqual(next(state, .lock), .locked, "lock should be allowed from \(state)")
        }
    }

    func testRetryIsAllowedAfterRecoverableFailures() {
        let failures: [AuthenticationState] = [
            .cameraPermissionDenied, .cameraUnavailable(reason: ""), .authenticationFailed(reason: ""),
            .authenticationCancelled, .authenticationUnavailable(reason: ""), .timeout,
        ]
        for state in failures {
            XCTAssertTrue(state.isRecoverableFailure)
            XCTAssertEqual(next(state, .startFaceScan), .requestingCamera, "retry should be allowed from \(state)")
        }
    }

    func testPasswordFallbackAvailability() {
        XCTAssertTrue(AuthenticationState.locked.canUsePasswordFallback)
        XCTAssertTrue(AuthenticationState.searchingForFace.canUsePasswordFallback)
        XCTAssertTrue(AuthenticationState.timeout.canUsePasswordFallback)
        XCTAssertTrue(AuthenticationState.cameraPermissionDenied.canUsePasswordFallback)

        // Already authenticating (or about to), or already through.
        XCTAssertFalse(AuthenticationState.faceDetected.canUsePasswordFallback)
        XCTAssertFalse(AuthenticationState.authenticating.canUsePasswordFallback)
        XCTAssertFalse(AuthenticationState.authenticated.canUsePasswordFallback)
        XCTAssertFalse(AuthenticationState.unlocked.canUsePasswordFallback)
        // LocalAuthentication itself is unavailable, so the fallback would fail the same way.
        XCTAssertFalse(AuthenticationState.authenticationUnavailable(reason: "").canUsePasswordFallback)
    }

    func testInvalidTransitionsAreRejected() {
        XCTAssertNil(next(.locked, .faceFound))
        XCTAssertNil(next(.locked, .authenticationSucceeded))
        XCTAssertNil(next(.searchingForFace, .authenticationSucceeded))
        XCTAssertNil(next(.faceDetected, .scanTimedOut))
        XCTAssertNil(next(.authenticating, .startFaceScan))
        XCTAssertNil(next(.authenticated, .startFaceScan))
        XCTAssertNil(next(.unlocked, .beginAuthentication))
        XCTAssertNil(next(.unlocked, .finishUnlock))
        XCTAssertNil(next(.requestingCamera, .faceFound))
    }

    func testCameraUsageFlags() {
        XCTAssertTrue(AuthenticationState.requestingCamera.usesCamera)
        XCTAssertTrue(AuthenticationState.searchingForFace.usesCamera)
        XCTAssertFalse(AuthenticationState.faceDetected.usesCamera)
        XCTAssertFalse(AuthenticationState.authenticating.usesCamera)
        XCTAssertFalse(AuthenticationState.locked.usesCamera)
    }
}

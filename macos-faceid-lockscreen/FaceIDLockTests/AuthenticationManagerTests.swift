import LocalAuthentication
import XCTest
@testable import FaceIDLock

/// Tests the mapping from LocalAuthentication errors to lock-screen outcomes.
/// The system dialog itself can't be driven from unit tests.
final class AuthenticationManagerTests: XCTestCase {
    func testCancellationsMapToCancelled() {
        for code in [LAError.Code.userCancel, .appCancel, .systemCancel, .userFallback] {
            XCTAssertEqual(AuthenticationManager.outcome(for: LAError(code)), .cancelled, "\(code)")
        }
    }

    func testWrongCredentialsMapToFailed() {
        guard case .failed = AuthenticationManager.outcome(for: LAError(.authenticationFailed)) else {
            return XCTFail("authenticationFailed should map to .failed")
        }
    }

    func testLockoutMapsToFailedWithGuidance() {
        guard case .failed(let reason) = AuthenticationManager.outcome(for: LAError(.biometryLockout)) else {
            return XCTFail("biometryLockout should map to .failed")
        }
        XCTAssertTrue(reason.localizedCaseInsensitiveContains("password"))
    }

    func testMissingPasswordMapsToUnavailable() {
        guard case .unavailable(let reason) = AuthenticationManager.outcome(for: LAError(.passcodeNotSet)) else {
            return XCTFail("passcodeNotSet should map to .unavailable")
        }
        XCTAssertFalse(reason.isEmpty)
    }

    func testNonInteractiveMapsToUnavailable() {
        guard case .unavailable = AuthenticationManager.outcome(for: LAError(.notInteractive)) else {
            return XCTFail("notInteractive should map to .unavailable")
        }
    }

    func testUnknownErrorsMapToFailedWithDescription() {
        let error = NSError(domain: "Test", code: 42, userInfo: [NSLocalizedDescriptionKey: "Something broke"])
        XCTAssertEqual(AuthenticationManager.outcome(for: error), .failed(reason: "Something broke"))
    }

    func testMissingErrorStillFails() {
        guard case .failed = AuthenticationManager.outcome(for: nil) else {
            return XCTFail("A nil error without success should still be a failure")
        }
    }

    func testBiometryKindMapping() {
        XCTAssertEqual(BiometryKind(LABiometryType.none), .unavailable)
        XCTAssertEqual(BiometryKind(LABiometryType.touchID), .touchID)
        XCTAssertEqual(BiometryKind(LABiometryType.faceID), .faceID)
    }

    func testMethodDescription() {
        let touchID = AuthenticationAvailability(canAuthenticate: true, biometry: .touchID, isBiometryReady: true, unavailableReason: nil)
        XCTAssertEqual(touchID.methodDescription, "Touch ID or your password")

        let notEnrolled = AuthenticationAvailability(canAuthenticate: true, biometry: .touchID, isBiometryReady: false, unavailableReason: nil)
        XCTAssertEqual(notEnrolled.methodDescription, "your password")
    }
}

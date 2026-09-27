import XCTest
@testable import FaceIDLock

final class PresentationTests: XCTestCase {
    private let touchID = AuthenticationAvailability(canAuthenticate: true, biometry: .touchID, isBiometryReady: true, unavailableReason: nil)

    // MARK: - LockScreenStatus

    func testSearchingCopyFollowsGuidance() {
        XCTAssertEqual(LockScreenStatus(state: .searchingForFace, guidance: .noFace, availability: touchID).title, "Looking for your face…")
        XCTAssertEqual(LockScreenStatus(state: .searchingForFace, guidance: .moveCloser, availability: touchID).title, "Move a little closer")
        XCTAssertEqual(LockScreenStatus(state: .searchingForFace, guidance: .ready, availability: touchID).title, "Hold still…")
    }

    func testSearchingOffersPasswordOnReturnAndCancelOnEscape() {
        let status = LockScreenStatus(state: .searchingForFace, guidance: .noFace, availability: touchID)
        XCTAssertEqual(status.glyph, .searching)
        XCTAssertEqual(status.defaultAction, .usePassword)
        XCTAssertEqual(status.cancelAction, .cancel)
    }

    func testFaceDetectedAndAuthenticatingHaveNoButtons() {
        XCTAssertTrue(LockScreenStatus(state: .faceDetected, guidance: .ready, availability: touchID).actions.isEmpty)
        XCTAssertTrue(LockScreenStatus(state: .authenticating, guidance: .ready, availability: touchID).actions.isEmpty)
    }

    func testSuccessCopy() {
        let status = LockScreenStatus(state: .authenticated, guidance: .ready, availability: touchID)
        XCTAssertEqual(status.title, "Welcome")
        XCTAssertEqual(status.detail, "Unlocking…")
        XCTAssertEqual(status.glyph, .success)
    }

    func testEveryRecoverableFailureOffersAWayForward() {
        let failures: [AuthenticationState] = [
            .cameraPermissionDenied, .cameraUnavailable(reason: "r"), .authenticationFailed(reason: "r"),
            .authenticationCancelled, .authenticationUnavailable(reason: "r"), .timeout,
        ]
        for state in failures {
            let status = LockScreenStatus(state: state, guidance: .noFace, availability: touchID)
            XCTAssertFalse(status.actions.isEmpty, "\(state) needs at least one action")
            XCTAssertNotNil(status.defaultAction, "\(state) needs a Return-key action")
        }
    }

    func testPasswordButtonTitleReflectsTouchID() {
        XCTAssertEqual(LockScreenAction.usePassword.title(for: touchID), "Touch ID or Password")
        XCTAssertEqual(LockScreenAction.usePassword.title(for: .assumed), "Use Password")
    }

    // MARK: - UserProfile

    func testInitials() {
        XCTAssertEqual(UserProfile.initials(for: "Alex Appleseed"), "AA")
        XCTAssertEqual(UserProfile.initials(for: "alex"), "A")
        XCTAssertEqual(UserProfile.initials(for: "Mary Jane Watson"), "MW")
        XCTAssertEqual(UserProfile.initials(for: "   "), "?")
    }

    func testCustomNameWins() {
        XCTAssertEqual(UserProfile.resolve(customName: "  Alex  ").displayName, "Alex")
        XCTAssertFalse(UserProfile.resolve(customName: "").displayName.isEmpty)
    }

    // MARK: - LockScreenConfiguration

    func testConfigurationReadsUserDefaults() throws {
        let suiteName = "FaceIDLockTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertEqual(LockScreenConfiguration.load(from: defaults), .standard)

        defaults.set(false, forKey: PreferenceKey.startsScanAutomatically)
        defaults.set(15, forKey: PreferenceKey.faceSearchTimeoutSeconds)
        let configuration = LockScreenConfiguration.load(from: defaults)
        XCTAssertFalse(configuration.startsScanAutomatically)
        XCTAssertEqual(configuration.faceSearchTimeout, .seconds(15))
    }
}

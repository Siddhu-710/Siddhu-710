import CoreVideo
import XCTest
@testable import FaceIDLock

final class FaceDetectionTests: XCTestCase {
    func testNoFacesMeansNoFace() {
        let result = FaceDetectionResult.evaluate(faceBounds: [], minimumFaceHeight: 0.12)
        XCTAssertEqual(result, .empty)
        XCTAssertFalse(result.isQualified)
    }

    func testSmallFaceAsksToMoveCloser() {
        let result = FaceDetectionResult.evaluate(
            faceBounds: [CGRect(x: 0.45, y: 0.45, width: 0.06, height: 0.08)],
            minimumFaceHeight: 0.12
        )
        XCTAssertEqual(result.guidance, .moveCloser)
        XCTAssertFalse(result.isQualified)
    }

    func testLargeFaceQualifies() {
        let result = FaceDetectionResult.evaluate(
            faceBounds: [CGRect(x: 0.3, y: 0.25, width: 0.3, height: 0.4)],
            minimumFaceHeight: 0.12
        )
        XCTAssertEqual(result.guidance, .ready)
        XCTAssertTrue(result.isQualified)
    }

    func testLargestFaceWins() {
        let small = CGRect(x: 0.05, y: 0.05, width: 0.05, height: 0.06)
        let large = CGRect(x: 0.4, y: 0.3, width: 0.25, height: 0.35)
        let result = FaceDetectionResult.evaluate(faceBounds: [small, large], minimumFaceHeight: 0.12)
        XCTAssertEqual(result.faceCount, 2)
        XCTAssertEqual(result.primaryFace, large)
        XCTAssertTrue(result.isQualified)
    }

    /// Runs the real Vision request on a synthetic, featureless frame.
    func testVisionFindsNoFaceInBlankFrame() throws {
        let width = 640
        let height = 480
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
        XCTAssertEqual(status, kCVReturnSuccess)
        let buffer = try XCTUnwrap(pixelBuffer)

        CVPixelBufferLockBaseAddress(buffer, [])
        if let base = CVPixelBufferGetBaseAddress(buffer) {
            memset(base, 0x80, CVPixelBufferGetBytesPerRow(buffer) * height)
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])

        let detector = FaceDetectionManager(onResult: { _ in })
        let result = detector.analyze(buffer)
        XCTAssertEqual(result.faceCount, 0)
        XCTAssertEqual(result.guidance, .noFace)
    }
}

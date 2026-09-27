import AVFoundation
import Vision

/// Receives camera frames and asks Vision whether a face is present.
///
/// This is presence detection only: it uses `VNDetectFaceRectanglesRequest`, keeps nothing but the
/// bounding box of the largest face, and never recognises, compares, or stores faces. Each frame is
/// analysed synchronously on the capture queue and released as soon as the callback returns.
nonisolated final class FaceDetectionManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    private let minimumFaceHeight: CGFloat
    private let minimumInterval: TimeInterval
    private let onResult: @Sendable (FaceDetectionResult) -> Void

    // Only used from the capture output queue (or the calling thread in tests), one frame at a time.
    private let request = VNDetectFaceRectanglesRequest()
    private var lastAnalysisTime: TimeInterval = 0

    /// - Parameters:
    ///   - minimumFaceHeight: Fraction of the frame height a face must fill to count as present.
    ///   - minimumInterval: Minimum seconds between analysed frames; extra frames are dropped.
    ///   - onResult: Called on the capture queue after each analysed frame.
    init(
        minimumFaceHeight: CGFloat = FaceDetectionResult.defaultMinimumFaceHeight,
        minimumInterval: TimeInterval = 0.1,
        onResult: @escaping @Sendable (FaceDetectionResult) -> Void
    ) {
        self.minimumFaceHeight = minimumFaceHeight
        self.minimumInterval = minimumInterval
        self.onResult = onResult
        super.init()
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastAnalysisTime >= minimumInterval,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastAnalysisTime = now
        onResult(analyze(pixelBuffer))
    }

    /// Runs face-rectangle detection on one frame.
    func analyze(_ pixelBuffer: CVPixelBuffer) -> FaceDetectionResult {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return .empty
        }
        let faceBounds = (request.results ?? []).map(\.boundingBox)
        return FaceDetectionResult.evaluate(faceBounds: faceBounds, minimumFaceHeight: minimumFaceHeight)
    }
}

import CoreGraphics

/// Guidance shown while searching for a face.
nonisolated enum FaceGuidance: Equatable, Sendable {
    case noFace
    case moveCloser
    case ready
}

/// The outcome of analysing a single camera frame.
///
/// Only geometry is kept — never pixels, landmarks, or anything that could identify a person.
nonisolated struct FaceDetectionResult: Equatable, Sendable {
    let faceCount: Int
    /// Normalised bounding box (0...1, origin bottom-left) of the largest face, if any.
    let primaryFace: CGRect?
    let guidance: FaceGuidance

    /// A face is present and large enough to count as "someone is sitting in front of the Mac".
    var isQualified: Bool { guidance == .ready }

    static let empty = FaceDetectionResult(faceCount: 0, primaryFace: nil, guidance: .noFace)

    /// A face at normal laptop distance fills roughly a third of a 640×480 frame; 12% still
    /// accepts someone leaning back while rejecting faces far in the background.
    static let defaultMinimumFaceHeight: CGFloat = 0.12

    /// Decides what a set of detected faces means for the lock screen.
    ///
    /// - Parameters:
    ///   - faceBounds: Normalised bounding boxes reported by Vision.
    ///   - minimumFaceHeight: Fraction of the frame height the largest face must fill.
    static func evaluate(faceBounds: [CGRect], minimumFaceHeight: CGFloat) -> FaceDetectionResult {
        let largest = faceBounds.max { lhs, rhs in
            lhs.width * lhs.height < rhs.width * rhs.height
        }
        guard let largest else { return .empty }

        let guidance: FaceGuidance = largest.height >= minimumFaceHeight ? .ready : .moveCloser
        return FaceDetectionResult(faceCount: faceBounds.count, primaryFace: largest, guidance: guidance)
    }
}

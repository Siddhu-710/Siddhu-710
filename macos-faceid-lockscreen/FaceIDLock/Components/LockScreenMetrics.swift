import SwiftUI

extension EnvironmentValues {
    /// Combined text scale from the in-app Text Size setting and any Dynamic Type size in the
    /// environment. Applied to every font on the lock screen.
    @Entry var textScale: CGFloat = 1
}

extension DynamicTypeSize {
    /// Relative to `.large`, which is the default size.
    var textScaleFactor: CGFloat {
        switch self {
        case .xSmall: return 0.85
        case .small: return 0.9
        case .medium: return 0.95
        case .large: return 1.0
        case .xLarge: return 1.1
        case .xxLarge: return 1.2
        case .xxxLarge: return 1.3
        case .accessibility1: return 1.45
        case .accessibility2: return 1.6
        case .accessibility3: return 1.75
        case .accessibility4: return 1.9
        case .accessibility5: return 2.0
        @unknown default: return 1.0
        }
    }
}

/// Sizes derived from the window size, so the layout looks right on a 13" MacBook Air, a 15"
/// MacBook Air, and a large external display alike.
struct LockScreenMetrics {
    let size: CGSize
    let layoutScale: CGFloat
    let textScale: CGFloat

    /// Points of a 13-inch MacBook Air at its default "looks like" resolution.
    private static let referenceSize = CGSize(width: 1470, height: 956)

    init(size: CGSize, textScale: CGFloat) {
        self.size = size
        let widthRatio = size.width / Self.referenceSize.width
        let heightRatio = size.height / Self.referenceSize.height
        self.layoutScale = min(max(min(widthRatio, heightRatio), 0.7), 1.6)
        self.textScale = textScale
    }

    var clockFontSize: CGFloat { 124 * layoutScale }
    var dateFontSize: CGFloat { max(21 * layoutScale * textScale, 14) }
    var avatarSize: CGFloat { 92 * layoutScale }
    var nameFontSize: CGFloat { max(20 * layoutScale * textScale, 14) }
    var glyphSize: CGFloat { 72 * layoutScale }
    var titleFontSize: CGFloat { max(15 * layoutScale * textScale, 13) }
    var detailFontSize: CGFloat { max(12.5 * layoutScale * textScale, 11) }
    var footnoteFontSize: CGFloat { max(11 * layoutScale * textScale, 10) }
    var buttonFontSize: CGFloat { max(13 * layoutScale * textScale, 12) }
    var spacing: CGFloat { 14 * layoutScale }
    var topInset: CGFloat { size.height * 0.08 }
    var bottomInset: CGFloat { size.height * 0.04 }
    var textColumnWidth: CGFloat { 440 * layoutScale * min(textScale, 1.4) }
}

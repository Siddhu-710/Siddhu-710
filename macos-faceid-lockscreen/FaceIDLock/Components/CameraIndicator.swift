import SwiftUI

/// Shows that the camera is on. macOS also shows its own indicator, but the menu bar is hidden
/// in full screen, so the lock screen makes it visible too.
struct CameraIndicator: View {
    var fontSize: CGFloat = 11

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.green)
                .frame(width: fontSize * 0.65, height: fontSize * 0.65)
            Text("Camera on")
                .font(.system(size: fontSize, weight: .medium))
        }
        .padding(.horizontal, fontSize * 0.9)
        .padding(.vertical, fontSize * 0.45)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Camera is on"))
    }
}

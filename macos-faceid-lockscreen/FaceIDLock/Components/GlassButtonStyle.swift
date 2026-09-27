import SwiftUI

/// A translucent capsule button. The prominent variant is used for the Return-key action.
struct GlassButtonStyle: ButtonStyle {
    var isProminent = false
    var fontSize: CGFloat = 13

    func makeBody(configuration: Configuration) -> some View {
        GlassButton(configuration: configuration, isProminent: isProminent, fontSize: fontSize)
    }
}

private struct GlassButton: View {
    let configuration: ButtonStyleConfiguration
    let isProminent: Bool
    let fontSize: CGFloat

    @State private var isHovering = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        configuration.label
            .font(.system(size: fontSize, weight: .medium))
            .foregroundStyle(isProminent ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
            .padding(.horizontal, fontSize * 1.25)
            .padding(.vertical, fontSize * 0.6)
            .background { background }
            .overlay {
                Capsule().strokeBorder(Color.primary.opacity(contrast == .increased ? 0.5 : 0.12), lineWidth: 1)
            }
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.5)
            .onHover { isHovering = $0 }
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: isHovering)
    }

    @ViewBuilder
    private var background: some View {
        if isProminent {
            Capsule().fill(Color.accentColor.opacity(isHovering ? 1 : 0.85))
        } else if reduceTransparency {
            Capsule().fill(Color(nsColor: .controlBackgroundColor))
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(Color.primary.opacity(isHovering ? 0.08 : 0)))
        }
    }
}

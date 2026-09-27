import SwiftUI

/// A slowly drifting, blurred colour field behind the lock screen, generated in code so no
/// wallpaper assets are needed. Frosted with a material while locked, clearer once unlocked.
struct AmbientBackground: View {
    var isUnlocked: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.controlActiveState) private var controlActiveState

    var body: some View {
        let palette = Palette(colorScheme: colorScheme)
        let isPaused = reduceMotion || controlActiveState == .inactive

        ZStack {
            palette.base

            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { timeline in
                let time: Double = isPaused ? 0 : timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    let longestSide = max(size.width, size.height)
                    for blob in palette.blobs {
                        let driftX = CGFloat(0.07 * sin(time * blob.speed + blob.phase))
                        let driftY = CGFloat(0.07 * cos(time * blob.speed * 0.8 + blob.phase))
                        let center = CGPoint(
                            x: size.width * (blob.x + driftX),
                            y: size.height * (blob.y + driftY)
                        )
                        let radius = longestSide * blob.radius
                        let bounds = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                        context.fill(
                            Path(ellipseIn: bounds),
                            with: .radialGradient(
                                Gradient(colors: [blob.color, blob.color.opacity(0)]),
                                center: center,
                                startRadius: 0,
                                endRadius: radius
                            )
                        )
                    }
                }
            }

            if reduceTransparency {
                palette.base.opacity(isUnlocked ? 0.4 : 0.6)
            } else {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(isUnlocked ? 0.35 : 0.85)
            }

            // Gentle top/bottom shading keeps the clock and footer legible on any colour.
            LinearGradient(
                colors: [palette.shade.opacity(0.35), .clear, .clear, palette.shade.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.8), value: isUnlocked)
        .accessibilityHidden(true)
    }
}

private struct Palette {
    struct Blob {
        let color: Color
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let speed: Double
        let phase: Double
    }

    let base: Color
    let shade: Color
    let blobs: [Blob]

    init(colorScheme: ColorScheme) {
        if colorScheme == .dark {
            base = Color(red: 0.04, green: 0.05, blue: 0.10)
            shade = .black
            blobs = [
                Blob(color: Color(red: 0.36, green: 0.26, blue: 0.86), x: 0.22, y: 0.28, radius: 0.55, speed: 0.11, phase: 0.0),
                Blob(color: Color(red: 0.03, green: 0.52, blue: 0.62), x: 0.80, y: 0.30, radius: 0.50, speed: 0.09, phase: 1.7),
                Blob(color: Color(red: 0.58, green: 0.20, blue: 0.58), x: 0.70, y: 0.85, radius: 0.55, speed: 0.07, phase: 3.1),
                Blob(color: Color(red: 0.10, green: 0.28, blue: 0.74), x: 0.18, y: 0.86, radius: 0.45, speed: 0.13, phase: 4.4),
            ]
        } else {
            base = Color(red: 0.93, green: 0.94, blue: 0.97)
            shade = Color(red: 0.55, green: 0.58, blue: 0.68)
            blobs = [
                Blob(color: Color(red: 1.00, green: 0.78, blue: 0.66), x: 0.22, y: 0.26, radius: 0.55, speed: 0.11, phase: 0.0),
                Blob(color: Color(red: 0.62, green: 0.80, blue: 1.00), x: 0.82, y: 0.28, radius: 0.50, speed: 0.09, phase: 1.7),
                Blob(color: Color(red: 0.82, green: 0.74, blue: 1.00), x: 0.70, y: 0.86, radius: 0.55, speed: 0.07, phase: 3.1),
                Blob(color: Color(red: 0.70, green: 0.92, blue: 0.84), x: 0.18, y: 0.84, radius: 0.45, speed: 0.13, phase: 4.4),
            ]
        }
    }
}

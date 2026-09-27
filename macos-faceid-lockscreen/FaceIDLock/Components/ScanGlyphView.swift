import SwiftUI

/// An original, Face ID–inspired scanning glyph: viewfinder brackets that lock on, a scan line
/// while searching, a spinning tick ring while authenticating, and a drawn checkmark on success.
///
/// Everything is vector-drawn, so it stays sharp on Retina displays. With Reduce Motion enabled,
/// continuous motion (scan line, spinning ring, failure shake) is replaced by static states and
/// cross-fades.
struct ScanGlyphView: View {
    let phase: GlyphPhase
    let size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var failureShakes: CGFloat = 0

    var body: some View {
        ZStack {
            ViewfinderShape(inset: bracketInset)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .opacity(phase == .success ? 0 : bracketOpacity)
                .scaleEffect(phase == .success ? 0.7 : 1)

            if phase == .searching && !reduceMotion {
                ScanLine(tint: tint, lineWidth: lineWidth)
                    .padding(size * 0.2)
                    .transition(.opacity)
            }

            if phase == .detected || phase == .authenticating {
                TickRing(
                    tint: tint,
                    isAnimating: !reduceMotion,
                    revolutionsPerSecond: phase == .authenticating ? 0.8 : 1.4,
                    tickWidth: lineWidth * 0.55
                )
                .frame(width: size * 0.44, height: size * 0.44)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }

            SuccessMark(isVisible: phase == .success, tint: tint, lineWidth: lineWidth, drawsStroke: !reduceMotion)
                .frame(width: size * 0.8, height: size * 0.8)
        }
        .frame(width: size, height: size)
        .modifier(ShakeEffect(amplitude: size * 0.08, shakes: failureShakes))
        .animation(
            reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.72),
            value: phase
        )
        .onChange(of: phase) { _, newPhase in
            guard newPhase == .failure, !reduceMotion else { return }
            withAnimation(.linear(duration: 0.5)) {
                failureShakes += 1
            }
        }
        .accessibilityHidden(true) // The status text beneath the glyph carries the meaning.
    }

    private var lineWidth: CGFloat {
        size * (contrast == .increased ? 0.06 : 0.045)
    }

    private var bracketInset: CGFloat {
        switch phase {
        case .detected, .authenticating: return 0.14
        case .searching: return 0.05
        case .idle, .success, .failure, .inactive: return 0.08
        }
    }

    private var bracketOpacity: Double {
        switch phase {
        case .inactive: return 0.45
        case .idle: return 0.85
        default: return 1
        }
    }

    private var tint: Color {
        switch phase {
        case .idle, .searching: return .primary
        case .detected, .authenticating: return .accentColor
        case .success: return .green
        case .failure: return .red
        case .inactive: return .secondary
        }
    }
}

// MARK: - Pieces

/// Four rounded corner brackets. `inset` is a fraction of the side length, animatable so the
/// brackets glide inward when a face is detected.
struct ViewfinderShape: Shape {
    var inset: CGFloat

    var animatableData: CGFloat {
        get { inset }
        set { inset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let box = CGRect(
            x: rect.midX - side / 2,
            y: rect.midY - side / 2,
            width: side,
            height: side
        ).insetBy(dx: side * inset, dy: side * inset)

        let leg = box.width * 0.28
        let radius = leg * 0.55
        var path = Path()

        // Top-left
        path.move(to: CGPoint(x: box.minX, y: box.minY + leg))
        path.addArc(tangent1End: CGPoint(x: box.minX, y: box.minY), tangent2End: CGPoint(x: box.maxX, y: box.minY), radius: radius)
        path.addLine(to: CGPoint(x: box.minX + leg, y: box.minY))

        // Top-right
        path.move(to: CGPoint(x: box.maxX - leg, y: box.minY))
        path.addArc(tangent1End: CGPoint(x: box.maxX, y: box.minY), tangent2End: CGPoint(x: box.maxX, y: box.maxY), radius: radius)
        path.addLine(to: CGPoint(x: box.maxX, y: box.minY + leg))

        // Bottom-right
        path.move(to: CGPoint(x: box.maxX, y: box.maxY - leg))
        path.addArc(tangent1End: CGPoint(x: box.maxX, y: box.maxY), tangent2End: CGPoint(x: box.minX, y: box.maxY), radius: radius)
        path.addLine(to: CGPoint(x: box.maxX - leg, y: box.maxY))

        // Bottom-left
        path.move(to: CGPoint(x: box.minX + leg, y: box.maxY))
        path.addArc(tangent1End: CGPoint(x: box.minX, y: box.maxY), tangent2End: CGPoint(x: box.minX, y: box.minY), radius: radius)
        path.addLine(to: CGPoint(x: box.minX, y: box.maxY - leg))

        return path
    }
}

/// A soft horizontal line sweeping up and down inside the brackets.
private struct ScanLine: View {
    let tint: Color
    let lineWidth: CGFloat

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let progress = CGFloat((sin(time * 2.4) + 1) / 2)
            GeometryReader { proxy in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0), tint, tint.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width, height: max(lineWidth * 0.7, 1))
                    .shadow(color: tint.opacity(0.6), radius: lineWidth * 1.5)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * progress)
            }
        }
    }
}

/// A ring of ticks with a bright "comet" travelling around it.
private struct TickRing: View {
    let tint: Color
    let isAnimating: Bool
    let revolutionsPerSecond: Double
    let tickWidth: CGFloat

    private static let tickCount = 36

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !isAnimating)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let outerRadius = min(canvasSize.width, canvasSize.height) / 2 - tickWidth
                let innerRadius = outerRadius * 0.78
                let head = (time * revolutionsPerSecond).truncatingRemainder(dividingBy: 1)

                for index in 0..<Self.tickCount {
                    let fraction = Double(index) / Double(Self.tickCount)
                    let angle = fraction * 2 * Double.pi - Double.pi / 2
                    let unitX = CGFloat(cos(angle))
                    let unitY = CGFloat(sin(angle))

                    let intensity: Double
                    if isAnimating {
                        var distanceBehindHead = head - fraction
                        if distanceBehindHead < 0 { distanceBehindHead += 1 }
                        intensity = max(0.2, 1 - distanceBehindHead * 1.8)
                    } else {
                        intensity = 0.7
                    }

                    var tick = Path()
                    tick.move(to: CGPoint(x: center.x + unitX * innerRadius, y: center.y + unitY * innerRadius))
                    tick.addLine(to: CGPoint(x: center.x + unitX * outerRadius, y: center.y + unitY * outerRadius))
                    context.stroke(
                        tick,
                        with: .color(tint.opacity(intensity)),
                        style: StrokeStyle(lineWidth: tickWidth, lineCap: .round)
                    )
                }
            }
        }
    }
}

/// A circle and checkmark that draw themselves in.
private struct SuccessMark: View {
    let isVisible: Bool
    let tint: Color
    let lineWidth: CGFloat
    let drawsStroke: Bool

    var body: some View {
        let progress: CGFloat = (isVisible || !drawsStroke) ? 1 : 0
        ZStack {
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            CheckmarkShape()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth * 1.2, lineCap: .round, lineJoin: .round))
        }
        .opacity(isVisible ? 1 : 0)
        .animation(drawsStroke ? .easeOut(duration: 0.55) : .easeInOut(duration: 0.2), value: isVisible)
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.minY + rect.height * 0.66))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.71, y: rect.minY + rect.height * 0.37))
        return path
    }
}

/// Horizontal "no" shake, like a rejected password on macOS. Each +1 to `shakes` is one shake.
struct ShakeEffect: GeometryEffect {
    var amplitude: CGFloat
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amplitude * sin(shakes * .pi * 6), y: 0))
    }
}

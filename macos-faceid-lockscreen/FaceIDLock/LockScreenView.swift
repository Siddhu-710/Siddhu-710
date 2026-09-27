import Accessibility
import SwiftUI

/// The full-screen lock screen: clock, user, scan glyph, status, and fallback actions.
struct LockScreenView: View {
    @ObservedObject var viewModel: LockScreenViewModel
    let profile: UserProfile

    @Environment(\.textScale) private var textScale
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let cameraPrivacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
    )!

    var body: some View {
        let status = viewModel.status

        GeometryReader { proxy in
            let metrics = LockScreenMetrics(size: proxy.size, textScale: textScale)

            VStack(spacing: 0) {
                ClockView(metrics: metrics)
                    .padding(.top, metrics.topInset)

                Spacer(minLength: metrics.spacing * 2)

                authenticationPanel(status: status, metrics: metrics)

                Spacer(minLength: metrics.spacing * 2)

                Text("Demo only — this app doesn't lock your Mac. Press ⌃⌘Q to use the real lock screen.")
                    .font(.system(size: metrics.footnoteFontSize))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, metrics.spacing * 2)
                    .padding(.bottom, metrics.bottomInset)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .overlay(alignment: .topTrailing) {
                if viewModel.isCameraActive {
                    CameraIndicator(fontSize: metrics.footnoteFontSize)
                        .padding(metrics.spacing * 1.5)
                        .transition(.opacity)
                }
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .smooth(duration: 0.35), value: status)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isCameraActive)
        .onChange(of: viewModel.state) { _, _ in
            AccessibilityNotification.Announcement(viewModel.status.title).post()
        }
    }

    // MARK: - Sections

    private func authenticationPanel(status: LockScreenStatus, metrics: LockScreenMetrics) -> some View {
        VStack(spacing: metrics.spacing) {
            AvatarView(initials: profile.initials, size: metrics.avatarSize)

            Text(profile.displayName)
                .font(.system(size: metrics.nameFontSize, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            ScanGlyphView(phase: status.glyph, size: metrics.glyphSize)
                .padding(.top, metrics.spacing * 0.75)

            VStack(spacing: 4 * metrics.layoutScale) {
                Text(status.title)
                    .font(.system(size: metrics.titleFontSize, weight: .medium))
                    .contentTransition(.opacity)

                if let detail = status.detail {
                    Text(detail)
                        .font(.system(size: metrics.detailFontSize))
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: metrics.textColumnWidth)
            .accessibilityElement(children: .combine)

            actionButtons(status: status, metrics: metrics)
                // Reserve the row's height so the layout doesn't jump as buttons come and go.
                .frame(minHeight: metrics.buttonFontSize * 2.6)
                .padding(.top, metrics.spacing * 0.5)
        }
        .padding(.horizontal, metrics.spacing * 2)
    }

    private func actionButtons(status: LockScreenStatus, metrics: LockScreenMetrics) -> some View {
        HStack(spacing: metrics.spacing * 0.75) {
            ForEach(status.actions) { action in
                Button {
                    perform(action)
                } label: {
                    Label(action.title(for: viewModel.availability), systemImage: action.systemImage)
                }
                .buttonStyle(GlassButtonStyle(isProminent: action == status.defaultAction, fontSize: metrics.buttonFontSize))
                .keyboardShortcut(shortcut(for: action, in: status))
                .transition(.opacity)
            }
        }
    }

    // MARK: - Actions

    private func shortcut(for action: LockScreenAction, in status: LockScreenStatus) -> KeyboardShortcut? {
        if action == status.defaultAction { return .defaultAction }
        if action == status.cancelAction { return .cancelAction }
        return nil
    }

    private func perform(_ action: LockScreenAction) {
        switch action {
        case .scanFace, .tryAgain:
            viewModel.beginFaceScan()
        case .usePassword:
            viewModel.usePassword()
        case .cancel:
            viewModel.cancelScan()
        case .openCameraSettings:
            openURL(Self.cameraPrivacySettingsURL)
        }
    }
}

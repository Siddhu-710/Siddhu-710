import AppKit
import SwiftUI

/// Gives the SwiftUI window a chrome-less look and, optionally, takes it into native full screen
/// once at launch.
///
/// Native full screen is used deliberately instead of a kiosk mode: the demo can always be left
/// with ⌃⌘F, Mission Control, or ⌘Tab, because it is not a security boundary.
struct WindowConfigurator: NSViewRepresentable {
    var entersFullScreen: Bool

    func makeNSView(context: Context) -> ConfiguringView {
        ConfiguringView(entersFullScreen: entersFullScreen)
    }

    func updateNSView(_ nsView: ConfiguringView, context: Context) {}

    final class ConfiguringView: NSView {
        private let entersFullScreen: Bool
        private var hasConfiguredWindow = false

        init(entersFullScreen: Bool) {
            self.entersFullScreen = entersFullScreen
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            return nil
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window, !hasConfiguredWindow else { return }
            hasConfiguredWindow = true

            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.tabbingMode = .disallowed
            window.collectionBehavior.insert(.fullScreenPrimary)

            guard entersFullScreen, !window.styleMask.contains(.fullScreen) else { return }
            // Let the window finish appearing before animating into its own Space.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak window] in
                guard let window, !window.styleMask.contains(.fullScreen) else { return }
                window.toggleFullScreen(nil)
            }
        }
    }
}

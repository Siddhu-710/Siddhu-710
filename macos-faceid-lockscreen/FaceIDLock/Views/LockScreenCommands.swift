import SwiftUI

/// Menu bar commands. They keep working in full screen, where the menu bar is hidden until the
/// pointer reaches the top of the display.
struct LockScreenCommands: Commands {
    @ObservedObject var viewModel: LockScreenViewModel

    var body: some Commands {
        // A lock screen is a single window.
        CommandGroup(replacing: .newItem) {}

        CommandMenu("Lock Screen") {
            Button("Lock") {
                viewModel.lock()
            }
            .keyboardShortcut("l", modifiers: .command)

            Divider()

            Button("Scan Face") {
                viewModel.beginFaceScan()
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(!viewModel.state.canStartFaceScan)

            Button("Use Touch ID or Password…") {
                viewModel.usePassword()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(!viewModel.state.canUsePasswordFallback)
        }
    }
}

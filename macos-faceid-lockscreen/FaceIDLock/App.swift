import AppKit
import SwiftUI

@main
struct FaceIDLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel: LockScreenViewModel

    init() {
        PreferenceDefaults.register()
        _viewModel = StateObject(wrappedValue: LockScreenViewModel.live())
    }

    var body: some Scene {
        Window("Face ID Lock", id: "lock-screen") {
            if AppEnvironment.isRunningUnitTests {
                // Unit tests use this app as their host; don't touch the camera or go full screen.
                Text("Running unit tests…")
                    .frame(width: 320, height: 120)
            } else {
                RootView(viewModel: viewModel)
                    .frame(minWidth: 760, minHeight: 560)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 820)
        .commands {
            LockScreenCommands(viewModel: viewModel)
        }

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

enum AppEnvironment {
    static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}

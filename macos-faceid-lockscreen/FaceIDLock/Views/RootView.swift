import AppKit
import SwiftUI

/// Hosts the lock screen and the unlocked state, and forwards app/system lifecycle events to
/// the view model.
struct RootView: View {
    @ObservedObject var viewModel: LockScreenViewModel

    @AppStorage(PreferenceKey.displayName) private var displayName = ""
    @AppStorage(PreferenceKey.textSize) private var textSize: TextSizePreference = .standard
    @AppStorage(PreferenceKey.opensInFullScreen) private var opensInFullScreen = PreferenceDefaults.opensInFullScreen

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var workspaceCenter: NotificationCenter { NSWorkspace.shared.notificationCenter }

    var body: some View {
        let profile = UserProfile.resolve(customName: displayName)
        let isUnlocked = viewModel.state == .unlocked

        ZStack {
            AmbientBackground(isUnlocked: isUnlocked)

            if isUnlocked {
                UnlockedView(viewModel: viewModel, profile: profile)
                    .transition(unlockedTransition)
            } else {
                LockScreenView(viewModel: viewModel, profile: profile)
                    .transition(lockTransition)
            }
        }
        .animation(
            reduceMotion ? .easeInOut(duration: 0.3) : .spring(response: 0.7, dampingFraction: 0.88),
            value: isUnlocked
        )
        .environment(\.textScale, textSize.scale * dynamicTypeSize.textScaleFactor)
        .background(WindowConfigurator(entersFullScreen: opensInFullScreen))
        .onAppear {
            viewModel.start()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            viewModel.appDidResignActive()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.appDidBecomeActive()
        }
        .onReceive(workspaceCenter.publisher(for: NSWorkspace.willSleepNotification)) { _ in
            viewModel.systemWillSleep()
        }
        .onReceive(workspaceCenter.publisher(for: NSWorkspace.screensDidSleepNotification)) { _ in
            viewModel.systemWillSleep()
        }
        .onReceive(workspaceCenter.publisher(for: NSWorkspace.didWakeNotification)) { _ in
            viewModel.systemDidWake(appIsActive: NSApp.isActive)
        }
        .onReceive(workspaceCenter.publisher(for: NSWorkspace.screensDidWakeNotification)) { _ in
            viewModel.systemDidWake(appIsActive: NSApp.isActive)
        }
    }

    private var lockTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 1.04)),
            removal: .opacity.combined(with: .scale(scale: 1.12))
        )
    }

    private var unlockedTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.94)),
            removal: .opacity.combined(with: .scale(scale: 0.97))
        )
    }
}

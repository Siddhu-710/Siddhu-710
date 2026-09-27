# Contributing

Thanks for helping improve Face ID Lock! Bug reports, accessibility fixes, design polish and tests are all welcome.

## Ground rules

This project is a **demo** and must stay honest about that. Pull requests will not be accepted if they:

- store, transmit or compare camera frames, face landmarks, embeddings or any other biometric data;
- handle the user's password in-process, or add custom credential checks;
- attempt to replace, hook or imitate the real macOS login window, or trap the user in the app;
- use private APIs, or add network access.

If you're unsure whether an idea fits, open an issue first.

## Development setup

1. Install **Xcode 16.3 or later** (Xcode 26+ recommended).
2. Fork and clone the repository, then `open macos-faceid-lockscreen/FaceIDLock.xcodeproj`.
3. Run the app with **⌘R** and the tests with **⌘U**.
4. Turn off **Open in full screen** in the app's Settings (⌘,) while iterating on UI.

## Conventions

- **Architecture.** Views render, `LockScreenViewModel` decides, managers talk to frameworks. New states or transitions go through `AuthenticationStateMachine`, with tests.
- **Concurrency.** UI and view model code is `@MainActor`. AVFoundation work stays on `CameraManager`'s session queue. Types used from background queues are marked `nonisolated` and are `Sendable`.
- **Style.** Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/). Match the surrounding code, and write comments that explain *why* rather than *what*.
- **UI.** Support light and dark mode, Reduce Motion, Reduce Transparency, Increase Contrast and keyboard-only use. Put user-facing strings in `String(localized:)` or `Text("…")`.
- **Assets.** Contributions must be original or properly licensed. Don't add Apple's proprietary artwork (such as the Face ID glyph) or other copyrighted assets.

## Pull request checklist

- [ ] `xcodebuild test -project FaceIDLock.xcodeproj -scheme FaceIDLock -destination 'platform=macOS'` passes (run inside `macos-faceid-lockscreen/`)
- [ ] New behavior has unit tests where it can be tested without hardware
- [ ] Manually tested on a Mac: camera grant and deny, face scan, password fallback, cancel, lock
- [ ] Checked with Reduce Motion and VoiceOver if the UI changed
- [ ] README updated if behavior, requirements or shortcuts changed
- [ ] Screenshots attached for visual changes

## Reporting bugs

Please include your macOS version, Xcode version, Mac model, steps to reproduce, and what you expected versus what happened. For anything security-related, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).

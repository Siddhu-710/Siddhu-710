import SwiftUI

/// The app's Settings window (⌘,).
struct SettingsView: View {
    @AppStorage(PreferenceKey.displayName) private var displayName = ""
    @AppStorage(PreferenceKey.startsScanAutomatically) private var startsScanAutomatically = PreferenceDefaults.startsScanAutomatically
    @AppStorage(PreferenceKey.opensInFullScreen) private var opensInFullScreen = PreferenceDefaults.opensInFullScreen
    @AppStorage(PreferenceKey.faceSearchTimeoutSeconds) private var timeoutSeconds = PreferenceDefaults.faceSearchTimeoutSeconds
    @AppStorage(PreferenceKey.textSize) private var textSize: TextSizePreference = .standard

    var body: some View {
        Form {
            Section {
                TextField("Display name", text: $displayName, prompt: Text(UserProfile.resolve(customName: "").displayName))
            } header: {
                Text("Profile")
            } footer: {
                Text("Leave empty to use your macOS account name.")
                    .foregroundStyle(.secondary)
            }

            Section("Face Scan") {
                Toggle("Start scanning automatically", isOn: $startsScanAutomatically)
                Picker("Stop looking after", selection: $timeoutSeconds) {
                    ForEach(PreferenceDefaults.timeoutChoices, id: \.self) { seconds in
                        Text("\(seconds) seconds").tag(seconds)
                    }
                }
            }

            Section("Display") {
                Toggle("Open in full screen", isOn: $opensInFullScreen)
                Picker("Text size", selection: $textSize) {
                    ForEach(TextSizePreference.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }
            }

            Section("Privacy") {
                Label("Camera frames are analyzed in memory to detect whether a face is present, then discarded. Nothing is saved or sent anywhere.", systemImage: "camera")
                Label("macOS performs authentication in its own dialog. This app never sees your password or biometric data.", systemImage: "lock.shield")
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 520)
    }
}

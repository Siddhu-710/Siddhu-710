import SwiftUI

/// What the demo shows after a successful unlock.
struct UnlockedView: View {
    @ObservedObject var viewModel: LockScreenViewModel
    let profile: UserProfile

    @Environment(\.textScale) private var textScale

    var body: some View {
        GeometryReader { proxy in
            let metrics = LockScreenMetrics(size: proxy.size, textScale: textScale)

            VStack(spacing: metrics.spacing * 1.5) {
                Spacer(minLength: metrics.topInset)

                Label("Unlocked", systemImage: "lock.open.fill")
                    .font(.system(size: metrics.detailFontSize, weight: .semibold))
                    .padding(.horizontal, metrics.spacing)
                    .padding(.vertical, metrics.spacing * 0.4)
                    .background(.ultraThinMaterial, in: Capsule())

                Text(greeting)
                    .font(.system(size: 44 * metrics.layoutScale * min(textScale, 1.3), weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)

                if let unlockedAt = viewModel.unlockedAt {
                    Text("Verified by macOS at \(unlockedAt, format: .dateTime.hour().minute())")
                        .font(.system(size: metrics.titleFontSize))
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .top, spacing: metrics.spacing) {
                    InfoCard(
                        systemImage: "checkmark.shield.fill",
                        title: "Identity",
                        value: Text("Verified with LocalAuthentication"),
                        metrics: metrics
                    )
                    InfoCard(
                        systemImage: "video.slash.fill",
                        title: "Camera",
                        value: Text("Off — no frames were saved"),
                        metrics: metrics
                    )
                    InfoCard(
                        systemImage: viewModel.availability.biometry == .touchID ? "touchid" : "key.fill",
                        title: "Sign-in methods",
                        value: Text(viewModel.availability.methodDescription.capitalizedFirstLetter),
                        metrics: metrics
                    )
                }
                .frame(maxWidth: 820 * metrics.layoutScale)
                .padding(.top, metrics.spacing)

                Button {
                    viewModel.lock()
                } label: {
                    Label("Lock Screen", systemImage: "lock.fill")
                }
                .buttonStyle(GlassButtonStyle(isProminent: true, fontSize: metrics.buttonFontSize))
                .padding(.top, metrics.spacing)
                .help("Lock (⌘L)")

                Spacer(minLength: metrics.spacing * 2)

                Text("This demo can't lock or unlock your Mac. Press ⌃⌘Q to lock your Mac for real.")
                    .font(.system(size: metrics.footnoteFontSize))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, metrics.bottomInset)
            }
            .padding(.horizontal, metrics.spacing * 3)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private var greeting: String {
        let firstName = profile.displayName.split(separator: " ").first.map(String.init) ?? profile.displayName
        let hour = Calendar.current.component(.hour, from: viewModel.unlockedAt ?? Date())
        switch hour {
        case 5..<12:
            return String(localized: "Good morning, \(firstName)")
        case 12..<18:
            return String(localized: "Good afternoon, \(firstName)")
        default:
            return String(localized: "Good evening, \(firstName)")
        }
    }
}

private struct InfoCard: View {
    let systemImage: String
    let title: LocalizedStringKey
    let value: Text
    let metrics: LockScreenMetrics

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.spacing * 0.5) {
            Image(systemName: systemImage)
                .font(.system(size: metrics.titleFontSize * 1.3, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: metrics.detailFontSize, weight: .semibold))
                .foregroundStyle(.secondary)
            value
                .font(.system(size: metrics.titleFontSize, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(metrics.spacing * 1.2)
        .background {
            RoundedRectangle(cornerRadius: 16 * metrics.layoutScale, style: .continuous)
                .fill(reduceTransparency ? AnyShapeStyle(Color(nsColor: .controlBackgroundColor)) : AnyShapeStyle(.ultraThinMaterial))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16 * metrics.layoutScale, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private extension String {
    var capitalizedFirstLetter: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}

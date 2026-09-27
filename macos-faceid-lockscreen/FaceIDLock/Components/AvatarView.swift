import SwiftUI

/// A Contacts-style monogram avatar.
struct AvatarView: View {
    let initials: String
    let size: CGFloat

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.66, green: 0.69, blue: 0.75),
                            Color(red: 0.49, green: 0.52, blue: 0.58),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text(initials)
                .font(.system(size: size * 0.4, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .padding(size * 0.12)
        }
        .frame(width: size, height: size)
        .overlay {
            Circle().strokeBorder(.white.opacity(contrast == .increased ? 0.7 : 0.25), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.25), radius: size * 0.12, y: size * 0.05)
        .accessibilityHidden(true) // The name is shown (and read) right below.
    }
}

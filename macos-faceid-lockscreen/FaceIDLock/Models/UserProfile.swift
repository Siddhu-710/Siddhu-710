import Foundation

/// The person shown on the lock screen.
///
/// The avatar is a generated monogram: reading the macOS account picture requires APIs that are
/// unavailable to sandboxed apps, and a monogram avoids handling anyone's photo.
struct UserProfile: Equatable {
    let displayName: String
    let initials: String

    init(displayName: String) {
        self.displayName = displayName
        self.initials = UserProfile.initials(for: displayName)
    }

    /// Uses the name from Settings if set, otherwise the macOS account's full name.
    static func resolve(customName: String) -> UserProfile {
        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return UserProfile(displayName: trimmed)
        }
        let fullName = NSFullUserName().trimmingCharacters(in: .whitespacesAndNewlines)
        return UserProfile(displayName: fullName.isEmpty ? NSUserName() : fullName)
    }

    /// First letter of the first and last words, e.g. "Alex Appleseed" → "AA", "Alex" → "A".
    static func initials(for name: String) -> String {
        let words = name
            .split(whereSeparator: { $0.isWhitespace })
            .filter { word in word.first?.isLetter == true }
        guard let first = words.first?.first else { return "?" }
        guard words.count > 1, let last = words.last?.first else {
            return String(first).uppercased()
        }
        return (String(first) + String(last)).uppercased()
    }
}

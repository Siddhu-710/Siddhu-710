# Security Policy

## Scope

Face ID Lock is a **demonstration app**. It doesn't lock your Mac, it doesn't replace the macOS login window, and its face scan is presence detection, not identity verification. The only real security decision is made by Apple's LocalAuthentication framework.

Out of scope, by design:

- Passing the face-presence check with a photo or another person's face.
- Leaving the full-screen demo with ⌘Tab, Mission Control, ⌃⌘F or ⌘Q.

In scope:

- Any path by which the app **stores or transmits** camera frames or face data.
- Any way to reach the **unlocked state without a successful LocalAuthentication result**.
- The camera **staying on** when the UI says it's off, or after the scan has ended.
- Weaknesses in the sandbox or entitlement configuration.

## Reporting a vulnerability

Please **don't open a public issue**. Use GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) on this repository, and include steps to reproduce along with your macOS and Xcode versions. You should get a response within a week.

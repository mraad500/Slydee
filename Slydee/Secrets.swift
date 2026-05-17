import Foundation

/// Bundled credentials. **Git-ignored** (see `.gitignore`) so the key never
/// reaches the repository or its history.
///
/// ⚠️ Security reality: a key compiled into a client app is still extractable
/// from the shipped binary. Mitigations the founder must apply:
///   1. Restrict this key in Google AI Studio (API + app restrictions, quota).
///   2. For production scale, proxy requests through a server you control and
///      remove this file entirely.
/// This file is intentionally NOT tracked by git.
nonisolated enum Secrets {
    /// Google Gemini (Generative Language API) key.
    static let geminiAPIKey = "AIzaSyC5RL9vXGqzYvm9SxNpXdibFIBzUiT1qHI"

    /// Model id. Change here if Google's model naming differs.
    static let geminiModel = "gemini-3.1-flash-lite"

    static var hasGemini: Bool {
        !geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

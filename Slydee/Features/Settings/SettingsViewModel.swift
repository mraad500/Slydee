import Foundation
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    enum KeyState: Equatable {
        case idle
        case testing
        case valid
        case invalid(String)
    }

    var claudeKey = ""
    var openAIKey = ""
    var googleKey = ""
    var googleCX = ""
    var claudeState: KeyState = .idle
    var openAIState: KeyState = .idle

    func load() {
        claudeKey = KeychainStore.read(.claude) ?? ""
        openAIKey = KeychainStore.read(.openAI) ?? ""
        googleKey = KeychainStore.read(.googleKey) ?? ""
        googleCX = KeychainStore.read(.googleCX) ?? ""
    }

    func save(_ key: KeychainStore.Key) {
        switch key {
        case .claude:
            KeychainStore.save(claudeKey, for: .claude)
            claudeState = .idle
        case .openAI:
            KeychainStore.save(openAIKey, for: .openAI)
            openAIState = .idle
        case .googleKey:
            KeychainStore.save(googleKey, for: .googleKey)
        case .googleCX:
            KeychainStore.save(googleCX, for: .googleCX)
        }
    }

    func clear(_ key: KeychainStore.Key) {
        KeychainStore.delete(key)
        switch key {
        case .claude:
            claudeKey = ""
            claudeState = .idle
        case .openAI:
            openAIKey = ""
            openAIState = .idle
        case .googleKey:
            googleKey = ""
        case .googleCX:
            googleCX = ""
        }
    }

    func test(_ key: KeychainStore.Key) {
        let value = (key == .claude ? claudeKey : openAIKey)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            setState(key, .invalid("Enter a key first."))
            return
        }
        save(key)
        setState(key, .testing)

        Task {
            let result: KeyState
            do {
                let ok = try await Self.ping(key: key, apiKey: value)
                result = ok ? .valid : .invalid("Unexpected response.")
            } catch GenerationError.missingAPIKey {
                result = .invalid("Key was rejected.")
            } catch {
                let message = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
                result = .invalid(message)
            }
            setState(key, result)
        }
    }

    private func setState(_ key: KeychainStore.Key, _ state: KeyState) {
        switch key {
        case .claude: claudeState = state
        case .openAI: openAIState = state
        case .googleKey, .googleCX: break
        }
    }

    /// Cheap validation request (max 1 token).
    private static func ping(key: KeychainStore.Key, apiKey: String) async throws -> Bool {
        switch key {
        case .claude:
            let body = try JSONSerialization.data(withJSONObject: [
                "model": "claude-sonnet-4-6",
                "max_tokens": 1,
                "messages": [["role": "user", "content": "ping"]],
            ])
            _ = try await APIClient.postJSON(
                url: URL(string: "https://api.anthropic.com/v1/messages")!,
                headers: [
                    "x-api-key": apiKey,
                    "anthropic-version": "2023-06-01",
                    "content-type": "application/json",
                ],
                body: body
            )
            return true
        case .openAI:
            let body = try JSONSerialization.data(withJSONObject: [
                "model": "gpt-4o",
                "max_tokens": 1,
                "messages": [["role": "user", "content": "ping"]],
            ])
            _ = try await APIClient.postJSON(
                url: URL(string: "https://api.openai.com/v1/chat/completions")!,
                headers: [
                    "Authorization": "Bearer \(apiKey)",
                    "content-type": "application/json",
                ],
                body: body
            )
            return true
        case .googleKey, .googleCX:
            return true
        }
    }
}

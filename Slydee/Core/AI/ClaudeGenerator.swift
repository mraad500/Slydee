import Foundation

/// Arabic & Mixed generation via the Anthropic Claude API (highest quality
/// for Arabic). The static system prompt is sent as a cacheable block.
nonisolated struct ClaudeGenerator: AIGenerator {
    let apiKey: String
    var model = "claude-sonnet-4-6"

    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    func generate(_ request: GenerationRequest) async throws -> GeneratedDeck {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw GenerationError.missingAPIKey
        }

        let arabic = request.language == .arabic
        let systemPrompt = arabic
            ? PromptBuilder.arabicSystemPrompt()
            : PromptBuilder.mixedSystemPrompt()
        let userPrompt = PromptBuilder.claudeUserPrompt(
            source: request.sourceText,
            slideCount: request.slideCount,
            tone: request.tone,
            arabic: arabic
        )

        let payload = ClaudeRequest(
            model: model,
            max_tokens: 4096,
            system: [
                .init(text: systemPrompt, cache_control: .init()),
            ],
            messages: [.init(role: "user", content: userPrompt)]
        )

        let body = try JSONEncoder().encode(payload)
        let data: Data
        do {
            data = try await APIClient.postJSON(
                url: Self.endpoint,
                headers: [
                    "x-api-key": apiKey,
                    "anthropic-version": "2023-06-01",
                    "content-type": "application/json",
                ],
                body: body
            )
        } catch let APIClient.APIError.http(code, _) where code == 401 || code == 403 {
            throw GenerationError.missingAPIKey
        } catch let APIClient.APIError.http(_, message) {
            throw GenerationError.network(message)
        } catch let APIClient.APIError.transport(message) {
            throw GenerationError.network(message)
        }

        try Task.checkCancellation()

        guard let decoded = try? JSONDecoder().decode(ClaudeResponse.self, from: data),
              let text = decoded.content.first(where: { $0.type == "text" })?.text
        else { throw GenerationError.invalidResponse }

        return try DeckJSONParser.parse(text, requested: request.language)
    }
}

private nonisolated struct ClaudeRequest: Encodable {
    struct SystemBlock: Encodable {
        var type = "text"
        var text: String
        var cache_control: CacheControl?
    }

    struct CacheControl: Encodable {
        var type = "ephemeral"
    }

    struct Message: Encodable {
        var role: String
        var content: String
    }

    var model: String
    var max_tokens: Int
    var system: [SystemBlock]
    var messages: [Message]
}

private nonisolated struct ClaudeResponse: Decodable {
    struct ContentBlock: Decodable {
        var type: String
        var text: String?
    }

    var content: [ContentBlock]
}

import Foundation

/// OpenAI GPT fallback for Arabic/Mixed when no Claude key is set.
nonisolated struct OpenAIGenerator: AIGenerator {
    let apiKey: String
    var model = "gpt-4o"

    private static let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

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

        let payload = OpenAIRequest(
            model: model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt),
            ],
            response_format: .init(type: "json_object")
        )

        let body = try JSONEncoder().encode(payload)
        let data: Data
        do {
            data = try await APIClient.postJSON(
                url: Self.endpoint,
                headers: [
                    "Authorization": "Bearer \(apiKey)",
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

        guard let decoded = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
              let text = decoded.choices.first?.message.content
        else { throw GenerationError.invalidResponse }

        return try DeckJSONParser.parse(text, requested: request.language)
    }
}

private nonisolated struct OpenAIRequest: Encodable {
    struct Message: Encodable {
        var role: String
        var content: String
    }

    struct ResponseFormat: Encodable {
        var type: String
    }

    var model: String
    var messages: [Message]
    var response_format: ResponseFormat
}

private nonisolated struct OpenAIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { var content: String }
        var message: Message
    }

    var choices: [Choice]
}

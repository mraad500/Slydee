import Foundation

/// Deck generation via Gemini. Reuses `PromptBuilder` (system + schema'd user
/// prompt) and the tolerant `DeckJSONParser`. Same `AIGenerator` contract as
/// every other generator, so it slots into `GeneratorFactory`.
nonisolated struct GeminiGenerator: AIGenerator {
    func generate(_ request: GenerationRequest) async throws -> GeneratedDeck {
        let arabic = request.language == .arabic
        let system: String
        switch request.language {
        case .arabic: system = PromptBuilder.arabicSystemPrompt()
        case .mixed: system = PromptBuilder.mixedSystemPrompt()
        case .english: system = PromptBuilder.englishInstructions(tone: request.tone)
        }

        let user = PromptBuilder.claudeUserPrompt(
            source: request.sourceText,
            slideCount: request.slideCount,
            tone: request.tone,
            arabic: arabic
        )

        let text = try await GeminiClient.generateJSON(system: system, user: user)
        try Task.checkCancellation()
        return try DeckJSONParser.parse(text, requested: request.language)
    }
}

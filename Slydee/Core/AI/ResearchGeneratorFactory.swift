import Foundation

/// Research generator resolution. Same model as decks: Gemini primary,
/// deterministic mock fallback so it never hard-fails.
nonisolated enum ResearchGeneratorFactory {
    static func generator(for language: AppLanguage) -> any ResearchGenerator {
        _ = language // Gemini handles all languages.
        return FallbackResearchGenerator(
            primary: GeminiResearchGenerator(),
            fallback: MockResearchGenerator()
        )
    }
}

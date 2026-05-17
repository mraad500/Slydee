import Foundation

/// Resolves the research generator. Returns the deterministic mock today; the
/// real AI path (Foundation Models for English, Claude for Arabic/Mixed) plugs
/// in here later — exactly like `GeneratorFactory` for decks.
nonisolated enum ResearchGeneratorFactory {
    static func generator(for language: AppLanguage) -> any ResearchGenerator {
        // TODO: when the AI API is connected, branch on `language`:
        //   .english        -> on-device Foundation Models research generator
        //   .arabic, .mixed  -> Claude (fallback OpenAI) research generator
        // each wrapped so it degrades to MockResearchGenerator.
        _ = language
        return MockResearchGenerator()
    }
}

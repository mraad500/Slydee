import Foundation

/// Deck generator resolution. Slydee ships with a bundled Gemini key (see
/// `Secrets`), so every language uses Gemini, degrading to the deterministic
/// mock if the network/key fails — generation never hard-fails.
nonisolated enum GeneratorFactory {
    static func generator(for language: AppLanguage) -> any AIGenerator {
        _ = language // Gemini handles all languages; param kept for the call site.
        return FallbackGenerator(
            primary: GeminiGenerator(),
            fallback: MockGenerator()
        )
    }
}

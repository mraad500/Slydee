import Foundation

/// Tries a primary generator; on any non-cancellation failure (e.g. on-device
/// model unavailable, missing API key, network error) falls back to a
/// secondary so the user always gets a deck.
nonisolated struct FallbackGenerator: AIGenerator {
    let primary: any AIGenerator
    let fallback: any AIGenerator

    func generate(_ request: GenerationRequest) async throws -> GeneratedDeck {
        do {
            return try await primary.generate(request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            return try await fallback.generate(request)
        }
    }
}

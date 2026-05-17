import Foundation

/// Tries a primary research generator; on any non-cancellation failure
/// (network down, bad key, bad response) falls back so the user always gets a
/// document. Mirrors `FallbackGenerator`.
nonisolated struct FallbackResearchGenerator: ResearchGenerator {
    let primary: any ResearchGenerator
    let fallback: any ResearchGenerator

    func generate(_ request: ResearchRequest) async throws -> GeneratedResearch {
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

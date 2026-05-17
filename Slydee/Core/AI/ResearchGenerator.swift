import Foundation

/// Inputs for research generation. Mirrors `GenerationRequest` but for
/// long-form prose rather than slides.
nonisolated struct ResearchRequest: Sendable {
    var topic: String
    var language: AppLanguage
    var tone: ResearchTone
    var lengthMode: ResearchLengthMode
    var lengthValue: Int

    var targetWordCount: Int {
        lengthMode.targetWordCount(lengthValue)
    }
}

nonisolated struct GeneratedResearch: Sendable {
    var title: String
    var sections: [ResearchSection]
}

/// A source of structured research content. Implementations: a deterministic
/// mock (now), and later on-device / Claude generators wired through
/// `ResearchGeneratorFactory`. Reuses `GenerationError`.
protocol ResearchGenerator: Sendable {
    func generate(_ request: ResearchRequest) async throws -> GeneratedResearch
}

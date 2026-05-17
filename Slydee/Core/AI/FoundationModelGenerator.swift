import Foundation
import FoundationModels

/// On-device English generation via Apple Foundation Models. Free, private,
/// fast — the preferred path for English decks.
nonisolated struct FoundationModelGenerator: AIGenerator {
    func generate(_ request: GenerationRequest) async throws -> GeneratedDeck {
        let model = SystemLanguageModel.default

        switch model.availability {
        case .available:
            break
        case let .unavailable(reason):
            throw GenerationError.unavailable(String(describing: reason))
        @unknown default:
            throw GenerationError.unavailable("unknown")
        }

        let session = LanguageModelSession {
            PromptBuilder.englishInstructions(tone: request.tone)
        }
        let prompt = PromptBuilder.englishPrompt(
            source: request.sourceText,
            slideCount: request.slideCount
        )

        let response = try await session.respond(to: prompt, generating: GenDeck.self)
        try Task.checkCancellation()
        return Self.map(response.content)
    }

    private static func map(_ gen: GenDeck) -> GeneratedDeck {
        let slides = gen.slides.map { slide in
            GeneratedSlide(
                layout: SlideLayout(rawValue: slide.layout) ?? .titleContent,
                language: .english,
                title: slide.title,
                subtitle: nil,
                bullets: slide.bullets,
                body: slide.body.isEmpty ? nil : slide.body,
                speakerNotes: slide.speakerNotes,
                suggestedImageQuery: nil
            )
        }
        return GeneratedDeck(
            title: gen.title,
            subtitle: gen.subtitle.isEmpty ? nil : gen.subtitle,
            language: .english,
            slides: slides
        )
    }
}

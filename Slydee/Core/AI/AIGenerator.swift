import Foundation

nonisolated enum Tone: String, CaseIterable, Codable, Sendable, Identifiable {
    case academic
    case casual
    case pitch
    case educational

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .academic: "Academic"
        case .casual: "Casual"
        case .pitch: "Pitch"
        case .educational: "Educational"
        }
    }

    /// English descriptor injected into the prompt.
    var englishDescriptor: String {
        switch self {
        case .academic: "formal and precise, suitable for a university lecture"
        case .casual: "friendly and conversational, easy to follow"
        case .pitch: "persuasive and energetic, like an investor pitch"
        case .educational: "clear and instructional, designed for learning"
        }
    }

    /// Arabic descriptor injected into the Arabic prompt.
    var arabicDescriptor: String {
        switch self {
        case .academic: "رسمية ودقيقة، مناسبة لمحاضرة جامعية"
        case .casual: "ودّية وبسيطة، سهلة المتابعة"
        case .pitch: "مقنعة وحماسية، كعرض لمستثمر"
        case .educational: "واضحة وتعليمية، مصمّمة للتعلّم"
        }
    }
}

nonisolated struct GenerationRequest: Sendable {
    var sourceText: String
    var language: AppLanguage
    var slideCount: Int
    var tone: Tone
}

nonisolated struct GeneratedSlide: Sendable {
    var layout: SlideLayout
    var language: AppLanguage
    var title: String
    var subtitle: String?
    var bullets: [String]
    var body: String?
    var speakerNotes: String
    var suggestedImageQuery: String?
}

nonisolated struct GeneratedDeck: Sendable {
    var title: String
    var subtitle: String?
    var language: AppLanguage
    var slides: [GeneratedSlide]
}

enum GenerationError: LocalizedError, Sendable {
    case cancelled
    case unavailable(String)
    case invalidResponse
    case missingAPIKey
    case network(String)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            "Generation was cancelled."
        case let .unavailable(reason):
            "On-device AI is unavailable: \(reason)"
        case .invalidResponse:
            "The model returned an unexpected response. Try again."
        case .missingAPIKey:
            "Add your Claude or OpenAI API key in Settings to generate Arabic decks."
        case let .network(message):
            "Network error: \(message)"
        }
    }
}

/// A source of structured deck content. Implementations: on-device Foundation
/// Models (English), Claude (Arabic/Mixed), and a deterministic mock fallback.
protocol AIGenerator: Sendable {
    func generate(_ request: GenerationRequest) async throws -> GeneratedDeck
}

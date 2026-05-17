import Foundation

/// Decodes the universal slide JSON returned by Claude/OpenAI into a
/// `GeneratedDeck`. Tolerant of markdown fences and surrounding prose.
nonisolated enum DeckJSONParser {
    private nonisolated struct DeckDTO: Decodable {
        var title: String
        var subtitle: String?
        var language: String?
        var slides: [SlideDTO]
    }

    private nonisolated struct SlideDTO: Decodable {
        var layout: String?
        var language: String?
        var title: String
        var subtitle: String?
        var bullets: [String]?
        var body: String?
        var speakerNotes: String?
    }

    static func parse(_ raw: String, requested: AppLanguage) throws -> GeneratedDeck {
        guard let json = extractJSONObject(from: raw),
              let data = json.data(using: .utf8)
        else { throw GenerationError.invalidResponse }

        guard let dto = try? JSONDecoder().decode(DeckDTO.self, from: data) else {
            throw GenerationError.invalidResponse
        }

        let slides = dto.slides.map { slide -> GeneratedSlide in
            let slideLang: AppLanguage = {
                if requested == .mixed {
                    return slide.language.flatMap(AppLanguage.init(rawValue:)) ?? .english
                }
                return requested
            }()
            return GeneratedSlide(
                layout: slide.layout.flatMap(SlideLayout.init(rawValue:)) ?? .titleContent,
                language: slideLang,
                title: slide.title,
                subtitle: slide.subtitle?.isEmpty == false ? slide.subtitle : nil,
                bullets: slide.bullets ?? [],
                body: slide.body?.isEmpty == false ? slide.body : nil,
                speakerNotes: slide.speakerNotes ?? "",
                suggestedImageQuery: nil
            )
        }

        guard !slides.isEmpty else { throw GenerationError.invalidResponse }

        return GeneratedDeck(
            title: dto.title,
            subtitle: dto.subtitle,
            language: requested,
            slides: slides
        )
    }

    /// Pulls the first balanced `{ ... }` object out of arbitrary model text.
    private static func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{") else { return nil }
        var depth = 0
        var inString = false
        var escaped = false
        var index = start

        while index < text.endIndex {
            let char = text[index]
            if escaped {
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else if char == "\"" {
                inString.toggle()
            } else if !inString {
                if char == "{" { depth += 1 }
                else if char == "}" {
                    depth -= 1
                    if depth == 0 {
                        return String(text[start...index])
                    }
                }
            }
            index = text.index(after: index)
        }
        return nil
    }
}

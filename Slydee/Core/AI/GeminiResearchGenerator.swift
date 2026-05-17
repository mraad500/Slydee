import Foundation

/// Research generation via Gemini. Asks for a typed JSON document and maps it
/// to `[ResearchSection]`. Conforms to `ResearchGenerator` so it slots into
/// `ResearchGeneratorFactory`.
nonisolated struct GeminiResearchGenerator: ResearchGenerator {
    func generate(_ request: ResearchRequest) async throws -> GeneratedResearch {
        let system = systemPrompt(request)
        let user = userPrompt(request)

        let text = try await GeminiClient.generateJSON(system: system, user: user)
        try Task.checkCancellation()

        guard let json = Self.firstJSONObject(in: text),
              let data = json.data(using: .utf8),
              let dto = try? JSONDecoder().decode(ResearchDTO.self, from: data),
              !dto.sections.isEmpty
        else { throw GenerationError.invalidResponse }

        let sections = dto.sections.map {
            ResearchSection(
                ResearchSectionStyle(rawValue: $0.style ?? "body") ?? .body,
                $0.text
            )
        }
        return GeneratedResearch(
            title: dto.title?.isEmpty == false ? dto.title! : request.topic,
            sections: sections
        )
    }

    // MARK: Prompts

    private func systemPrompt(_ r: ResearchRequest) -> String {
        switch r.language {
        case .arabic:
            "أنت باحث خبير تكتب باللغة العربية الفصحى بنبرة \(r.tone.arabicDescriptor). "
                + "أنتج بحثاً منظّماً ومترابطاً."
        case .mixed:
            "You are an expert researcher. Write a structured paper mixing Arabic "
                + "for prose and English for technical terms. Tone: \(r.tone.englishDescriptor)."
        case .english:
            "You are an expert researcher writing in clear academic English. "
                + "Tone: \(r.tone.englishDescriptor). Produce a structured, coherent paper."
        }
    }

    private func userPrompt(_ r: ResearchRequest) -> String {
        """
        Topic: \(r.topic)
        Target length: about \(r.targetWordCount) words.
        Write a complete research document: a title, then ordered sections
        (abstract, introduction, several body sections with sub-headings, a
        conclusion, and references).

        Return ONLY JSON in exactly this shape, no prose, no markdown fences:
        {"title":"string","sections":[{"style":"title|heading|subheading|body|quote","text":"string"}]}
        Use "title" once (first), "heading" for section headings, "subheading"
        for sub-headings, "body" for paragraphs, "quote" for block quotes.
        """
    }

    // MARK: Decoding

    private nonisolated struct ResearchDTO: Decodable {
        struct Section: Decodable {
            var style: String?
            var text: String
        }
        var title: String?
        var sections: [Section]
    }

    /// Balanced `{ … }` extractor (Gemini JSON mode is clean, but be tolerant).
    private static func firstJSONObject(in text: String) -> String? {
        guard let start = text.firstIndex(of: "{") else { return nil }
        var depth = 0
        var inString = false
        var escaped = false
        var index = start
        while index < text.endIndex {
            let char = text[index]
            if escaped { escaped = false }
            else if char == "\\" { escaped = true }
            else if char == "\"" { inString.toggle() }
            else if !inString {
                if char == "{" { depth += 1 }
                else if char == "}" {
                    depth -= 1
                    if depth == 0 { return String(text[start...index]) }
                }
            }
            index = text.index(after: index)
        }
        return nil
    }
}

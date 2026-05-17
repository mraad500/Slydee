import Foundation

/// Deterministic offline generator. Used for previews/tests and as the
/// fallback when no on-device model or API key is available, so the Create
/// flow always produces a renderable deck.
nonisolated struct MockGenerator: AIGenerator {
    func generate(_ request: GenerationRequest) async throws -> GeneratedDeck {
        try await Task.sleep(for: .milliseconds(600))
        try Task.checkCancellation()

        let arabic = request.language == .arabic
        let topic = request.sourceText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(70)
        let title = topic.isEmpty
            ? (arabic ? "عرض تقديمي" : "Untitled Presentation")
            : String(topic)

        var slides: [GeneratedSlide] = []

        slides.append(
            GeneratedSlide(
                layout: .sectionDivider,
                language: request.language == .mixed ? .english : request.language,
                title: title,
                subtitle: arabic ? "أعدّه Slydee" : "Made with Slydee",
                bullets: [],
                body: nil,
                speakerNotes: arabic
                    ? "افتتح العرض بمقدمة موجزة عن الموضوع."
                    : "Open with a brief introduction to the topic.",
                suggestedImageQuery: nil
            )
        )

        let bodyCount = max(1, request.slideCount - 2)
        for i in 0..<bodyCount {
            let n = i + 1
            slides.append(
                GeneratedSlide(
                    layout: i % 4 == 3 ? .quote : .titleContent,
                    language: request.language == .mixed ? .english : request.language,
                    title: arabic ? "النقطة \(n)" : "Key Point \(n)",
                    subtitle: nil,
                    bullets: i % 4 == 3 ? [] : (arabic
                        ? ["فكرة أساسية حول \(title)", "تفصيل داعم ومثال", "نتيجة أو خلاصة مرحلية"]
                        : ["A core idea about \(title)", "Supporting detail and an example", "A takeaway or interim conclusion"]),
                    body: i % 4 == 3
                        ? (arabic ? "“التبسيط هو قمة الإتقان.”" : "“Simplicity is the ultimate sophistication.”")
                        : nil,
                    speakerNotes: arabic
                        ? "اشرح هذه النقطة بمثال واقعي."
                        : "Explain this point with a real-world example.",
                    suggestedImageQuery: "\(title) concept"
                )
            )
        }

        slides.append(
            GeneratedSlide(
                layout: .titleOnly,
                language: request.language == .mixed ? .english : request.language,
                title: arabic ? "شكراً" : "Thank you",
                subtitle: arabic ? "أسئلة؟" : "Questions?",
                bullets: [],
                body: nil,
                speakerNotes: arabic ? "افتح باب النقاش." : "Open the floor for discussion.",
                suggestedImageQuery: nil
            )
        )

        return GeneratedDeck(
            title: title,
            subtitle: nil,
            language: request.language,
            slides: Array(slides.prefix(max(3, request.slideCount)))
        )
    }
}

import Foundation

/// Deterministic offline research generator. Produces a believable, properly
/// structured document (title → abstract → sections → conclusion →
/// references) scaled to the requested length and language. Swap for a real
/// AI generator later via `ResearchGeneratorFactory`.
nonisolated struct MockResearchGenerator: ResearchGenerator {
    func generate(_ request: ResearchRequest) async throws -> GeneratedResearch {
        try await Task.sleep(for: .milliseconds(900))
        try Task.checkCancellation()

        let arabic = request.language == .arabic
        let mixed = request.language == .mixed
        let topic = request.topic.trimmingCharacters(in: .whitespacesAndNewlines)

        // More target words → more body sections.
        let bodyCount = max(2, min(8, request.targetWordCount / 350))
        let paragraph = arabic ? Self.arabicParagraph : Self.englishParagraph

        var sections: [ResearchSection] = []
        sections.append(.init(.title, topic.isEmpty ? (arabic ? "بحث بدون عنوان" : "Untitled Research") : topic))

        // Abstract
        sections.append(.init(.heading, arabic ? "الملخّص" : "Abstract"))
        sections.append(.init(.body, arabic
            ? "يتناول هذا البحث موضوع «\(topic)» ويستعرض أبرز جوانبه ونتائجه بأسلوب \(request.tone.arabicDescriptor)."
            : "This paper examines “\(topic)”, surveying its key dimensions and findings in a manner that is \(request.tone.englishDescriptor)."))

        // Introduction
        sections.append(.init(.heading, arabic ? "المقدمة" : "Introduction"))
        sections.append(.init(.body, paragraph))

        // Body sections
        for index in 1...bodyCount {
            sections.append(.init(.heading, arabic ? "المحور \(index)" : "Section \(index)"))
            sections.append(.init(.subheading, arabic ? "تمهيد" : "Overview"))
            sections.append(.init(.body, paragraph))
            if index % 2 == 0 {
                sections.append(.init(.quote, arabic
                    ? "«التبسيط هو غاية الإتقان.»"
                    : "“Simplicity is the ultimate sophistication.”"))
            }
            sections.append(.init(.body, mixed
                ? "النقطة الأساسية هنا تتعلّق بـ scalability و reliability ضمن \(topic)."
                : paragraph))
        }

        // Conclusion
        sections.append(.init(.heading, arabic ? "الخاتمة" : "Conclusion"))
        sections.append(.init(.body, arabic
            ? "نخلص إلى أن «\(topic)» يمثّل مجالاً غنياً يستحق مزيداً من البحث المعمّق."
            : "We conclude that “\(topic)” is a rich area that merits deeper, continued investigation."))

        // References
        sections.append(.init(.heading, arabic ? "المراجع" : "References"))
        sections.append(.init(.body, "1. Smith, J. (2024). Foundations of \(topic). Slydee Press.\n2. Aziz, M. (2026). Applied perspectives on \(topic). Journal of Applied Studies."))

        return GeneratedResearch(
            title: topic.isEmpty ? (arabic ? "بحث" : "Research") : topic,
            sections: sections
        )
    }

    private static let englishParagraph =
        "This section develops the argument with structured reasoning and "
        + "supporting evidence. It situates the topic within existing work, "
        + "identifies the central tension, and outlines how the analysis "
        + "proceeds. Claims are stated precisely and qualified where the "
        + "evidence is partial, keeping the exposition transparent and testable."

    private static let arabicParagraph =
        "يطوّر هذا القسم الحجّة عبر استدلال منظّم وأدلة داعمة، ويضع الموضوع "
        + "ضمن سياق الأعمال السابقة، ويحدّد الإشكال المركزي، ويبيّن منهج "
        + "التحليل. تُصاغ الدعاوى بدقّة وتُقيَّد عند جزئية الدليل حفاظاً على "
        + "وضوح العرض وقابليته للاختبار."
}

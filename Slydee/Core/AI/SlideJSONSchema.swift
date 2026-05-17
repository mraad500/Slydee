import FoundationModels

/// `@Generable` schema for on-device structured generation (Apple Foundation
/// Models). Mirrors the universal slide schema; the framework handles
/// structured decoding natively — no JSON string parsing on-device.
@Generable
nonisolated struct GenDeck {
    @Guide(description: "A strong, concise presentation title (max 8 words)")
    var title: String

    @Guide(description: "A short supporting subtitle for the cover slide")
    var subtitle: String

    @Guide(description: "The ordered slides of the presentation")
    var slides: [GenSlide]
}

@Generable
nonisolated struct GenSlide {
    @Guide(description: "One of: titleOnly, titleContent, twoColumn, quote, sectionDivider")
    var layout: String

    @Guide(description: "A clear, specific slide title")
    var title: String

    @Guide(description: "3 to 5 concise bullet points, each under 12 words. Empty for quote/title slides.")
    var bullets: [String]

    @Guide(description: "Optional body text, or the quote text for a quote slide")
    var body: String

    @Guide(description: "Detailed, useful speaker notes for this slide")
    var speakerNotes: String
}

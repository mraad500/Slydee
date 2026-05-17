import Foundation

/// Visual role of a block in a research document. Drives reader typography
/// and PDF formatting.
nonisolated enum ResearchSectionStyle: String, Codable, Sendable, CaseIterable {
    case title // document title (one, at the top)
    case heading // H1 section heading
    case subheading // H2 sub-heading
    case body // a paragraph
    case quote // a block quote
}

/// One formatted block of a research document. Stored (JSON-encoded) inside
/// `ResearchDocument.bodyJSON`, mirroring the app's `Block.contentJSON`
/// pattern so the persisted schema stays primitive + CloudKit-safe.
nonisolated struct ResearchSection: Codable, Sendable, Identifiable {
    var id = UUID()
    var style: ResearchSectionStyle
    var text: String

    init(_ style: ResearchSectionStyle, _ text: String) {
        self.style = style
        self.text = text
    }
}

/// Writing tone for research generation.
nonisolated enum ResearchTone: String, Codable, Sendable, CaseIterable, Identifiable {
    case academic
    case analytical
    case descriptive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .academic: "Academic"
        case .analytical: "Analytical"
        case .descriptive: "Descriptive"
        }
    }

    /// Injected into the (future) AI prompt — English.
    var englishDescriptor: String {
        switch self {
        case .academic: "rigorous and citation-driven, suitable for a peer-reviewed paper"
        case .analytical: "evidence-led, comparing perspectives and weighing trade-offs"
        case .descriptive: "clear and explanatory, prioritizing accessible understanding"
        }
    }

    /// Injected into the (future) AI prompt — Arabic.
    var arabicDescriptor: String {
        switch self {
        case .academic: "رصينة وموثّقة بالمصادر، تصلح لبحث محكّم"
        case .analytical: "تحليلية تستند للأدلة وتوازن بين وجهات النظر"
        case .descriptive: "وصفية واضحة تركّز على الفهم الميسّر"
        }
    }
}

/// Whether the user sizes the research by word count or page count.
nonisolated enum ResearchLengthMode: String, Codable, Sendable, CaseIterable, Identifiable {
    case words
    case pages

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .words: "Word count"
        case .pages: "Pages"
        }
    }

    /// Sensible default amount when this mode is selected.
    var defaultValue: Int {
        switch self {
        case .words: 800
        case .pages: 4
        }
    }

    var range: ClosedRange<Int> {
        switch self {
        case .words: 200...5000
        case .pages: 1...30
        }
    }

    var step: Int {
        switch self {
        case .words: 100
        case .pages: 1
        }
    }

    /// Approximate target word count (≈350 words/page) used by the generator.
    func targetWordCount(_ value: Int) -> Int {
        switch self {
        case .words: value
        case .pages: value * 350
        }
    }
}

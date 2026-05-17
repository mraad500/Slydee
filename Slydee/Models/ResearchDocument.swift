import Foundation
import SwiftData

/// A generated research paper / report. Self-contained (no relationships) and
/// fully default-initialized so it's CloudKit-safe and lives in the same
/// store as `Deck`, surfacing in the shared Library.
@Model
final class ResearchDocument {
    var id: UUID = UUID()
    var title: String = ""
    /// The user's original topic prompt.
    var topic: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var language: AppLanguage = AppLanguage.english
    var tone: ResearchTone = ResearchTone.academic
    var lengthMode: ResearchLengthMode = ResearchLengthMode.words
    var lengthValue: Int = 800

    /// `[ResearchSection]` serialized as JSON (keeps the schema primitive).
    var bodyJSON: String = "[]"

    init(
        title: String,
        topic: String,
        language: AppLanguage = .english,
        tone: ResearchTone = .academic,
        lengthMode: ResearchLengthMode = .words,
        lengthValue: Int = 800,
        sections: [ResearchSection] = []
    ) {
        self.id = UUID()
        self.title = title
        self.topic = topic
        self.createdAt = .now
        self.updatedAt = .now
        self.language = language
        self.tone = tone
        self.lengthMode = lengthMode
        self.lengthValue = lengthValue
        self.bodyJSON = JSONCoding.encode(sections)
    }

    /// Decoded body. Setting re-encodes to `bodyJSON`.
    var sections: [ResearchSection] {
        get { JSONCoding.decode([ResearchSection].self, from: bodyJSON) ?? [] }
        set { bodyJSON = JSONCoding.encode(newValue) }
    }

    /// Flattened plain text (used for clipboard + PDF fallback).
    var plainText: String {
        sections.map { section in
            switch section.style {
            case .title, .heading, .subheading:
                "\n\(section.text)\n"
            case .quote:
                "“\(section.text)”"
            case .body:
                section.text
            }
        }
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var wordCount: Int {
        sections
            .map(\.text)
            .joined(separator: " ")
            .split { $0 == " " || $0 == "\n" }
            .count
    }

    var displayTitle: String {
        title.isEmpty ? "Untitled research" : title
    }

    func touch() {
        updatedAt = .now
    }
}

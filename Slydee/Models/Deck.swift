import Foundation
import SwiftData

@Model
final class Deck {
    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var language: AppLanguage = AppLanguage.english
    var theme: ThemeID = ThemeID.classic

    // Optional to-many is required for CloudKit sync.
    @Relationship(deleteRule: .cascade, inverse: \Slide.deck)
    var slides: [Slide]?

    var coverImageData: Data?
    /// The original topic / source text the user provided.
    var originalInput: String?

    init(
        title: String,
        language: AppLanguage = .english,
        theme: ThemeID = .classic,
        originalInput: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.createdAt = .now
        self.updatedAt = .now
        self.language = language
        self.theme = theme
        self.originalInput = originalInput
        self.slides = []
    }

    /// Slides sorted by their stored index (SwiftData relationships are
    /// unordered).
    var orderedSlides: [Slide] {
        (slides ?? []).sorted { $0.index < $1.index }
    }

    func addSlide(_ slide: Slide) {
        if slides == nil { slides = [] }
        slides?.append(slide)
    }

    func touch() {
        updatedAt = .now
    }
}

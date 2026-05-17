import Foundation
import SwiftData

@Model
final class Slide {
    var id: UUID = UUID()
    var deck: Deck?
    var index: Int = 0
    var layout: SlideLayout = SlideLayout.titleContent
    var transition: TransitionType = TransitionType.fade
    var notes: String = ""
    var language: AppLanguage = AppLanguage.english

    /// `SlideBackground` serialized as JSON (keeps the SwiftData schema
    /// primitive). Empty string falls back to the deck theme.
    var backgroundJSON: String = ""

    @Relationship(deleteRule: .cascade, inverse: \Block.slide)
    var blocks: [Block] = []

    init(
        index: Int,
        layout: SlideLayout,
        language: AppLanguage = .english,
        transition: TransitionType = .fade,
        notes: String = ""
    ) {
        self.id = UUID()
        self.index = index
        self.layout = layout
        self.language = language
        self.transition = transition
        self.notes = notes
        self.blocks = []
    }

    var background: SlideBackground {
        get { JSONCoding.decode(SlideBackground.self, from: backgroundJSON) ?? .theme }
        set { backgroundJSON = JSONCoding.encode(newValue) }
    }

    var orderedBlocks: [Block] {
        blocks.sorted { $0.zIndex < $1.zIndex }
    }
}

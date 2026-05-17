import Foundation
import SwiftData

/// Maps an AI-produced `GeneratedDeck` into persisted SwiftData
/// `Deck`/`Slide`/`Block` graphs. Block frames are relative (0...1); text
/// sizes are tuned for a 1280-wide reference canvas and scaled by the
/// renderer. Runs on the main actor because it mutates the model context.
@MainActor
enum DeckBuilder {
    /// Reference canvas width the AI text sizes are tuned for.
    static let referenceWidth: Double = 1280

    static func build(
        _ generated: GeneratedDeck,
        template: Template,
        sourceText: String,
        into context: ModelContext
    ) -> Deck {
        let deck = Deck(
            title: generated.title,
            language: generated.language,
            theme: template.theme,
            originalInput: sourceText
        )
        context.insert(deck)

        for (i, gen) in generated.slides.enumerated() {
            let slide = Slide(
                index: i,
                layout: gen.layout,
                language: gen.language,
                notes: gen.speakerNotes
            )
            slide.deck = deck
            deck.slides.append(slide)
            context.insert(slide)

            for block in makeBlocks(for: gen, deck: deck, theme: template.theme) {
                block.slide = slide
                slide.blocks.append(block)
                context.insert(block)
            }
        }
        deck.touch()
        return deck
    }

    // MARK: - Block layout

    private static func makeBlocks(
        for gen: GeneratedSlide,
        deck: Deck,
        theme: ThemeID
    ) -> [Block] {
        let textHex = theme.primaryTextHex

        func lang(_ text: String) -> AppLanguage {
            deck.language == .mixed ? LanguageDetector.language(of: text) : gen.language
        }
        func align(_ text: String, centered: Bool = false) -> TextAlign {
            if centered { return .center }
            return lang(text) == .arabic ? .trailing : .leading
        }

        switch gen.layout {
        case .titleOnly, .sectionDivider, .fullImage:
            var blocks: [Block] = [
                .text(
                    gen.title,
                    fontToken: "title", size: 64, weight: .bold,
                    colorHex: textHex, align: .center, language: lang(gen.title),
                    frame: RelativeFrame(x: 0.08, y: 0.34, width: 0.84, height: 0.26),
                    zIndex: 0
                ),
            ]
            if let subtitle = gen.subtitle, !subtitle.isEmpty {
                let b = Block.text(
                    subtitle,
                    fontToken: "heading", size: 30, weight: .regular,
                    colorHex: textHex, align: .center, language: lang(subtitle),
                    frame: RelativeFrame(x: 0.08, y: 0.61, width: 0.84, height: 0.12),
                    zIndex: 1
                )
                b.opacity = 0.7
                blocks.append(b)
            }
            return blocks

        case .quote:
            let quote = gen.body ?? gen.title
            var blocks: [Block] = [
                .text(
                    quote,
                    fontToken: "title", size: 46, weight: .semibold,
                    colorHex: textHex, align: .center, language: lang(quote),
                    frame: RelativeFrame(x: 0.10, y: 0.30, width: 0.80, height: 0.40),
                    zIndex: 0
                ),
            ]
            if let subtitle = gen.subtitle, !subtitle.isEmpty {
                let b = Block.text(
                    subtitle,
                    fontToken: "body", size: 24, weight: .regular,
                    colorHex: textHex, align: .center, language: lang(subtitle),
                    frame: RelativeFrame(x: 0.10, y: 0.71, width: 0.80, height: 0.10),
                    zIndex: 1
                )
                b.opacity = 0.65
                blocks.append(b)
            }
            return blocks

        case .twoColumn:
            let titleBlock = Block.text(
                gen.title,
                fontToken: "heading", size: 44, weight: .bold,
                colorHex: textHex, align: align(gen.title), language: lang(gen.title),
                frame: RelativeFrame(x: 0.07, y: 0.09, width: 0.86, height: 0.16),
                zIndex: 0
            )
            let mid = (gen.bullets.count + 1) / 2
            let left = gen.bullets.prefix(mid).map { "•  \($0)" }.joined(separator: "\n")
            let right = gen.bullets.dropFirst(mid).map { "•  \($0)" }.joined(separator: "\n")
            let leftBlock = Block.text(
                left.isEmpty ? (gen.body ?? "") : left,
                fontToken: "body", size: 28, weight: .regular,
                colorHex: textHex, align: align(left), language: lang(left),
                frame: RelativeFrame(x: 0.07, y: 0.30, width: 0.40, height: 0.60),
                zIndex: 1
            )
            let rightBlock = Block.text(
                right,
                fontToken: "body", size: 28, weight: .regular,
                colorHex: textHex, align: align(right), language: lang(right),
                frame: RelativeFrame(x: 0.53, y: 0.30, width: 0.40, height: 0.60),
                zIndex: 2
            )
            return [titleBlock, leftBlock, rightBlock]

        case .titleContent, .imageRight, .imageLeft:
            let titleBlock = Block.text(
                gen.title,
                fontToken: "heading", size: 46, weight: .bold,
                colorHex: textHex, align: align(gen.title), language: lang(gen.title),
                frame: RelativeFrame(x: 0.07, y: 0.09, width: 0.86, height: 0.16),
                zIndex: 0
            )
            let content = gen.bullets.isEmpty
                ? (gen.body ?? "")
                : gen.bullets.map { "•  \($0)" }.joined(separator: "\n")
            let contentBlock = Block.text(
                content,
                fontToken: "body", size: 30, weight: .regular,
                colorHex: textHex, align: align(content), language: lang(content),
                frame: RelativeFrame(x: 0.07, y: 0.30, width: 0.86, height: 0.60),
                zIndex: 1
            )
            return [titleBlock, contentBlock]
        }
    }
}

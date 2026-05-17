import Foundation
import SwiftData

@MainActor
@Observable
final class EditorViewModel {
    let deck: Deck
    private let context: ModelContext

    var selectedSlideIndex = 0
    var selectedBlockID: PersistentIdentifier?

    init(deck: Deck, context: ModelContext) {
        self.deck = deck
        self.context = context
    }

    var slides: [Slide] { deck.orderedSlides }

    var currentSlide: Slide? {
        guard !slides.isEmpty else { return nil }
        return slides[min(selectedSlideIndex, slides.count - 1)]
    }

    var selectedBlock: Block? {
        guard let id = selectedBlockID else { return nil }
        return currentSlide?.blocks.first { $0.persistentModelID == id }
    }

    func save() {
        deck.touch()
        try? context.save()
    }

    var canUndo: Bool { context.undoManager?.canUndo ?? false }
    var canRedo: Bool { context.undoManager?.canRedo ?? false }

    func undo() {
        context.undoManager?.undo()
        selectedBlockID = nil
        try? context.save()
    }

    func redo() {
        context.undoManager?.redo()
        selectedBlockID = nil
        try? context.save()
    }

    func selectSlide(_ index: Int) {
        selectedSlideIndex = min(max(0, index), max(0, slides.count - 1))
        selectedBlockID = nil
    }

    // MARK: Slide ops

    func addSlide() {
        let slide = Slide(
            index: slides.count,
            layout: .titleContent,
            language: deck.language
        )
        slide.deck = deck
        deck.slides.append(slide)
        context.insert(slide)

        let title = Block.text(
            "New slide",
            fontToken: "heading", size: 46, weight: .bold,
            colorHex: deck.theme.primaryTextHex,
            align: deck.language == .arabic ? .trailing : .leading,
            language: deck.language,
            frame: RelativeFrame(x: 0.07, y: 0.12, width: 0.86, height: 0.2)
        )
        title.slide = slide
        slide.blocks.append(title)
        context.insert(title)

        reindex()
        selectSlide((deck.orderedSlides.firstIndex { $0.id == slide.id }) ?? slides.count - 1)
        save()
    }

    func duplicateCurrentSlide() {
        guard let source = currentSlide else { return }
        let copy = Slide(
            index: source.index + 1,
            layout: source.layout,
            language: source.language,
            transition: source.transition,
            notes: source.notes
        )
        copy.backgroundJSON = source.backgroundJSON
        copy.deck = deck
        deck.slides.append(copy)
        context.insert(copy)

        for block in source.orderedBlocks {
            guard let content = block.content else { continue }
            let newBlock = Block(
                type: block.type,
                frame: block.frame,
                content: content,
                zIndex: block.zIndex,
                rotation: block.rotation,
                opacity: block.opacity
            )
            newBlock.animationJSON = block.animationJSON
            newBlock.slide = copy
            copy.blocks.append(newBlock)
            context.insert(newBlock)
        }
        reindex()
        save()
    }

    func deleteCurrentSlide() {
        guard slides.count > 1, let source = currentSlide else { return }
        context.delete(source)
        reindex()
        selectedSlideIndex = min(selectedSlideIndex, slides.count - 1)
        selectedBlockID = nil
        save()
    }

    private func reindex() {
        for (offset, slide) in deck.orderedSlides.enumerated() {
            slide.index = offset
        }
    }

    // MARK: Block ops

    func select(_ block: Block?) {
        selectedBlockID = block?.persistentModelID
    }

    func deleteSelectedBlock() {
        guard let block = selectedBlock, let slide = currentSlide else { return }
        slide.blocks.removeAll { $0.persistentModelID == block.persistentModelID }
        context.delete(block)
        selectedBlockID = nil
        save()
    }

    func duplicateSelectedBlock() {
        guard let block = selectedBlock, let slide = currentSlide,
              let content = block.content else { return }
        var frame = block.frame
        frame.x = min(0.9, frame.x + 0.04)
        frame.y = min(0.9, frame.y + 0.04)
        let copy = Block(
            type: block.type,
            frame: frame,
            content: content,
            zIndex: (slide.blocks.map(\.zIndex).max() ?? 0) + 1,
            rotation: block.rotation,
            opacity: block.opacity
        )
        copy.animationJSON = block.animationJSON
        copy.slide = slide
        slide.blocks.append(copy)
        context.insert(copy)
        selectedBlockID = copy.persistentModelID
        save()
    }

    func commitTransform(_ block: Block, frame: RelativeFrame, rotation: Double) {
        var f = frame
        f.width = min(max(f.width, 0.04), 1.4)
        f.height = min(max(f.height, 0.03), 1.4)
        f.x = min(max(f.x, -0.3), 1.0)
        f.y = min(max(f.y, -0.3), 1.0)
        block.frame = f
        block.rotation = rotation
        save()
    }

    func updateText(_ block: Block, _ transform: (inout TextContent) -> Void) {
        guard case .text(var content)? = block.content else { return }
        transform(&content)
        block.content = .text(content)
        save()
    }

    func setOpacity(_ value: Double, for block: Block) {
        block.opacity = min(max(value, 0.1), 1)
        save()
    }

    func setAnimation(_ animation: BlockAnimation?, for block: Block) {
        block.animation = animation
        save()
    }

    func setTransition(_ transition: TransitionType) {
        currentSlide?.transition = transition
        save()
    }

    func setNotes(_ notes: String) {
        currentSlide?.notes = notes
        save()
    }

    func setBackground(_ background: SlideBackground) {
        currentSlide?.background = background
        save()
    }

    func bringSelectedToFront() {
        guard let block = selectedBlock, let slide = currentSlide else { return }
        block.zIndex = (slide.blocks.map(\.zIndex).max() ?? 0) + 1
        save()
    }

    func addBlock(_ block: Block) {
        guard let slide = currentSlide else { return }
        block.zIndex = (slide.blocks.map(\.zIndex).max() ?? 0) + 1
        block.slide = slide
        slide.blocks.append(block)
        context.insert(block)
        selectedBlockID = block.persistentModelID
        save()
    }

    private var centerFrame: RelativeFrame {
        RelativeFrame(x: 0.3, y: 0.36, width: 0.4, height: 0.28)
    }

    func addText() {
        addBlock(Block.text(
            "Tap to edit",
            fontToken: "body", size: 32, weight: .semibold,
            colorHex: deck.theme.primaryTextHex,
            align: .center,
            language: deck.language == .arabic ? .arabic : .english,
            frame: centerFrame
        ))
    }

    func addImage(_ data: Data) {
        addBlock(Block(
            type: .image,
            frame: RelativeFrame(x: 0.28, y: 0.28, width: 0.44, height: 0.44),
            content: .image(ImageContent(unsplashQuery: nil, sfSymbol: nil, data: data))
        ))
    }

    func addSticker(_ symbol: String) {
        addBlock(Block(
            type: .sticker,
            frame: RelativeFrame(x: 0.4, y: 0.38, width: 0.2, height: 0.2),
            content: .sticker(stickerID: symbol)
        ))
    }

    func addChart() {
        addBlock(Block(
            type: .chart,
            frame: RelativeFrame(x: 0.22, y: 0.26, width: 0.56, height: 0.5),
            content: .chart(ChartContent(
                kind: "bar",
                labels: ["Q1", "Q2", "Q3", "Q4"],
                values: [12, 19, 14, 23]
            ))
        ))
    }

    func updateChart(_ block: Block, _ transform: (inout ChartContent) -> Void) {
        guard case .chart(var chart)? = block.content else { return }
        transform(&chart)
        block.content = .chart(chart)
        save()
    }
}

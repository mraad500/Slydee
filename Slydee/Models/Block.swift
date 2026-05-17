import Foundation
import SwiftData

@Model
final class Block {
    var id: UUID = UUID()
    var slide: Slide?
    var type: BlockType = BlockType.text
    var rotation: Double = 0
    var opacity: Double = 1
    var zIndex: Int = 0

    /// `RelativeFrame` serialized as JSON.
    var frameJSON: String = ""
    /// `BlockContent` serialized as JSON.
    var contentJSON: String = ""
    /// Optional entrance animation, serialized as JSON (Phase 2).
    var animationJSON: String?

    init(
        type: BlockType,
        frame: RelativeFrame,
        content: BlockContent,
        zIndex: Int = 0,
        rotation: Double = 0,
        opacity: Double = 1
    ) {
        self.id = UUID()
        self.type = type
        self.zIndex = zIndex
        self.rotation = rotation
        self.opacity = opacity
        self.frameJSON = JSONCoding.encode(frame)
        self.contentJSON = JSONCoding.encode(content)
    }

    var frame: RelativeFrame {
        get { JSONCoding.decode(RelativeFrame.self, from: frameJSON) ?? .full }
        set { frameJSON = JSONCoding.encode(newValue) }
    }

    var content: BlockContent? {
        get { JSONCoding.decode(BlockContent.self, from: contentJSON) }
        set { if let newValue { contentJSON = JSONCoding.encode(newValue) } }
    }

    var animation: BlockAnimation? {
        get { animationJSON.flatMap { JSONCoding.decode(BlockAnimation.self, from: $0) } }
        set { animationJSON = newValue.map { JSONCoding.encode($0) } }
    }
}

// MARK: - Convenience factories

extension Block {
    static func text(
        _ string: String,
        fontToken: String,
        size: Double,
        weight: SlydeeFontWeight,
        colorHex: String,
        align: TextAlign,
        language: AppLanguage,
        frame: RelativeFrame,
        zIndex: Int = 0
    ) -> Block {
        Block(
            type: .text,
            frame: frame,
            content: .text(
                TextContent(
                    text: string,
                    fontToken: fontToken,
                    size: size,
                    weight: weight,
                    colorHex: colorHex,
                    align: align,
                    language: language
                )
            ),
            zIndex: zIndex
        )
    }
}

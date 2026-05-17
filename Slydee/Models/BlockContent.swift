import CoreGraphics
import Foundation

/// Block position as a fraction (0...1) of the slide canvas, so layouts scale
/// to any export size.
nonisolated struct RelativeFrame: Codable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    static let full = RelativeFrame(x: 0, y: 0, width: 1, height: 1)

    func absolute(in canvas: CGSize) -> CGRect {
        CGRect(
            x: x * canvas.width,
            y: y * canvas.height,
            width: width * canvas.width,
            height: height * canvas.height
        )
    }
}

nonisolated struct TextContent: Codable, Sendable {
    var text: String
    var fontToken: String // semantic SlydeeFont reference, e.g. "title"
    var size: Double
    var weight: SlydeeFontWeight
    var colorHex: String
    var align: TextAlign
    var language: AppLanguage
}

nonisolated struct ImageContent: Codable, Sendable {
    /// Suggested Unsplash query produced by the AI (resolved in Phase 2).
    var unsplashQuery: String?
    /// SF Symbol placeholder shown until a real image is attached.
    var sfSymbol: String?
    /// Inline image bytes when the user attaches one (Phase 2 editor).
    var data: Data?
}

nonisolated struct ShapeContent: Codable, Sendable {
    var kind: String // "rectangle" | "ellipse" | "line"
    var fillHex: String
}

nonisolated struct ChartContent: Codable, Sendable {
    var kind: String // "bar" | "line" | "pie"
    var labels: [String]
    var values: [Double]
}

/// The polymorphic payload of a `Block`, serialized to JSON in SwiftData.
nonisolated enum BlockContent: Codable, Sendable {
    case text(TextContent)
    case image(ImageContent)
    case sticker(stickerID: String)
    case shape(ShapeContent)
    case chart(ChartContent)

    var asText: TextContent? {
        if case let .text(value) = self { return value }
        return nil
    }
}

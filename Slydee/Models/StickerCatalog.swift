import Foundation

/// Bundled sticker library — SF Symbols (no asset bundling, scalable, crisp).
/// Categorized per spec: universal, educational, Arabic/Islamic.
nonisolated enum StickerCatalog {
    struct Category: Identifiable, Sendable {
        let id: String
        let name: String
        let symbols: [String]
    }

    static let categories: [Category] = [
        Category(id: "universal", name: "Universal", symbols: [
            "arrow.right", "arrow.up", "arrow.down", "arrow.left",
            "arrow.up.right", "checkmark", "checkmark.circle.fill",
            "xmark", "xmark.circle.fill", "heart.fill", "star.fill",
            "circle.fill", "square.fill", "triangle.fill", "bolt.fill",
            "flame.fill", "hand.thumbsup.fill", "exclamationmark.triangle.fill",
            "plus.circle.fill", "minus.circle.fill",
        ]),
        Category(id: "educational", name: "Education", symbols: [
            "book.fill", "books.vertical.fill", "lightbulb.fill",
            "brain.head.profile", "gearshape.fill", "target",
            "function", "graduationcap.fill", "pencil", "ruler.fill",
            "globe", "atom", "flask.fill", "chart.bar.fill",
            "chart.pie.fill", "magnifyingglass", "clock.fill",
            "calendar", "doc.text.fill", "paperclip",
        ]),
        Category(id: "arabic", name: "Arabic / Islamic", symbols: [
            "star.and.crescent.fill", "moon.fill", "moon.stars.fill",
            "sparkles", "seal.fill", "rosette", "circle.hexagongrid.fill",
            "circle.grid.cross.fill", "staroflife.fill", "leaf.fill",
        ]),
    ]
}

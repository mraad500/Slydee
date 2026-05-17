import Foundation

/// A starter visual template. Phase 1 maps each to a built-in `ThemeID`;
/// Phase 2 expands these with JSON-defined layouts and light/dark variants.
nonisolated struct Template: Identifiable, Sendable {
    let id: String
    let name: String
    let theme: ThemeID
}

nonisolated enum TemplateCatalog {
    static let all: [Template] = [
        Template(id: "classic", name: "Classic", theme: .classic),
        Template(id: "sun", name: "Sunny", theme: .sun),
        Template(id: "sky", name: "Sky", theme: .sky),
        Template(id: "mint", name: "Mint", theme: .mint),
        Template(id: "lavender", name: "Lavender", theme: .lavender),
        Template(id: "peach", name: "Peach", theme: .peach),
        Template(id: "midnight", name: "Midnight", theme: .midnight),
        Template(id: "editorial", name: "Editorial", theme: .editorial),
    ]

    static func template(id: String) -> Template {
        all.first { $0.id == id } ?? all[0]
    }
}

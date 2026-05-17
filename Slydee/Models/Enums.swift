import SwiftUI

/// Built-in visual themes. Phase 1 ships these; Phase 2 adds light/dark
/// variants and many more.
nonisolated enum ThemeID: String, Codable, CaseIterable, Identifiable, Sendable {
    case classic // cream + ink
    case sun // cream + sun accent
    case sky
    case mint
    case lavender
    case peach
    case midnight // dark
    case editorial // serif-feel, high contrast

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: "Classic"
        case .sun: "Sun"
        case .sky: "Sky"
        case .mint: "Mint"
        case .lavender: "Lavender"
        case .peach: "Peach"
        case .midnight: "Midnight"
        case .editorial: "Editorial"
        }
    }

    var backgroundHex: String {
        switch self {
        case .classic, .sun, .editorial: "F7F2E8"
        case .sky: "EAF4FF"
        case .mint: "EAF8F1"
        case .lavender: "F1ECFF"
        case .peach: "FFF0EB"
        case .midnight: "1A1A1A"
        }
    }

    var primaryTextHex: String {
        self == .midnight ? "F7F2E8" : "0F0F0F"
    }

    var accentHex: String {
        switch self {
        case .classic, .editorial: "0F0F0F"
        case .sun, .midnight: "FFD93D"
        case .sky: "A5D8FF"
        case .mint: "A8E6CF"
        case .lavender: "C8B6FF"
        case .peach: "FFB199"
        }
    }

    var background: Color { Color(hex: backgroundHex) }
    var primaryText: Color { Color(hex: primaryTextHex) }
    var accent: Color { Color(hex: accentHex) }
}

/// Slide layout archetypes. Phase 1 renders titleOnly/titleContent/twoColumn/
/// quote/sectionDivider; the rest are reserved for Phase 2.
nonisolated enum SlideLayout: String, Codable, CaseIterable, Sendable {
    case titleOnly
    case titleContent
    case twoColumn
    case quote
    case sectionDivider
    case imageRight
    case imageLeft
    case fullImage
}

nonisolated enum TransitionType: String, Codable, CaseIterable, Sendable {
    case fade
    case slide
    case zoom
    case none
}

nonisolated enum BlockType: String, Codable, CaseIterable, Sendable {
    case text
    case image
    case sticker
    case shape
    case chart
}

/// Codable text alignment (SwiftUI's `TextAlignment` isn't `Codable`).
nonisolated enum TextAlign: String, Codable, Sendable {
    case leading
    case center
    case trailing

    var textAlignment: TextAlignment {
        switch self {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }

    var frameAlignment: Alignment {
        switch self {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}

/// Codable font weight (SwiftUI's `Font.Weight` isn't `Codable`).
nonisolated enum SlydeeFontWeight: String, Codable, Sendable, CaseIterable {
    case regular
    case medium
    case semibold
    case bold

    var swiftUI: Font.Weight {
        switch self {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        }
    }
}

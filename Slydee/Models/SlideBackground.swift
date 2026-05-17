import SwiftUI

/// A slide's background fill. Serialized to JSON in `Slide`.
nonisolated enum SlideBackground: Codable, Sendable {
    case theme // inherit the deck theme background
    case solid(hex: String)
    case gradient(hexes: [String])

    @ViewBuilder
    func view(theme: ThemeID) -> some View {
        switch self {
        case .theme:
            theme.background
        case let .solid(hex):
            Color(hex: hex)
        case let .gradient(hexes):
            LinearGradient(
                colors: hexes.map { Color(hex: $0) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

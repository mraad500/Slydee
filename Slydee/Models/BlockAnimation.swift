import SwiftUI

/// Per-block entrance animation, serialized into `Block.animationJSON`.
nonisolated struct BlockAnimation: Codable, Sendable, Equatable {
    enum Kind: String, Codable, Sendable, CaseIterable, Identifiable {
        case none
        case fade
        case slide
        case scale
        case bounce

        var id: String { rawValue }
        var label: String {
            switch self {
            case .none: "None"
            case .fade: "Fade"
            case .slide: "Slide in"
            case .scale: "Scale"
            case .bounce: "Bounce"
            }
        }
    }

    enum Edge: String, Codable, Sendable, CaseIterable, Identifiable {
        case leading, trailing, top, bottom
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    var kind: Kind = .fade
    var edge: Edge = .leading
    var duration: Double = 0.5
    var delay: Double = 0

    static let `default` = BlockAnimation()
}

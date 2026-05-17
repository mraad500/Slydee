import SwiftUI

nonisolated extension Color {
    // MARK: Brand
    static let slydeeCream = Color(hex: "F7F2E8") // Primary background
    static let slydeeInk = Color(hex: "0F0F0F") // Primary text
    static let slydeeSun = Color(hex: "FFD93D") // Accent (CTAs, highlights)

    // MARK: Secondary palette (templates & UI surfaces)
    static let slydeeSky = Color(hex: "A5D8FF")
    static let slydeeMint = Color(hex: "A8E6CF")
    static let slydeeLavender = Color(hex: "C8B6FF")
    static let slydeePeach = Color(hex: "FFB199")

    // MARK: Semantic
    static let slydeeSuccess = Color.slydeeMint
    static let slydeeWarning = Color.slydeePeach
    static let slydeeInfo = Color.slydeeLavender

    // MARK: Surfaces
    /// Slightly elevated surface on top of the cream background.
    static let slydeeSurface = Color(hex: "FFFFFF")
    /// Muted ink for secondary text.
    static let slydeeInkMuted = Color(hex: "5C5C5C")
    /// Hairline separators.
    static let slydeeHairline = Color(hex: "E4DCCB")
}

nonisolated extension Color {
    /// Creates a color from a hex string. Supports `RGB`, `RRGGBB`, and
    /// `AARRGGBB`. Invalid input falls back to opaque black so the UI never
    /// crashes on a malformed token.
    init(hex: String) {
        let sanitized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let a, r, g, b: UInt64
        switch sanitized.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (
                255,
                (value >> 8 & 0xF) * 17,
                (value >> 4 & 0xF) * 17,
                (value & 0xF) * 17
            )
        case 6: // RRGGBB (24-bit)
            (a, r, g, b) = (255, value >> 16, value >> 8 & 0xFF, value & 0xFF)
        case 8: // AARRGGBB (32-bit)
            (a, r, g, b) = (value >> 24, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

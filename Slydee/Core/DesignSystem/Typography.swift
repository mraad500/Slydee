import SwiftUI

/// Typography tokens. English uses SF Pro (the iOS system face); Arabic uses
/// the system Arabic face (SF Arabic) automatically when given Arabic glyphs.
///
/// If IBM Plex Sans Arabic TTFs are later added to `Resources/Fonts` and
/// registered, set `arabicCustomFamily` to its PostScript name and it will be
/// used with a graceful fallback to the system font.
nonisolated enum SlydeeFont {
    /// PostScript family for bundled Arabic font, or `nil` to use the system
    /// Arabic face. Phase 1 ships with the system face (no missing-font risk).
    static let arabicCustomFamily: String? = nil

    static func title(_ size: CGFloat, lang: AppLanguage = .english) -> Font {
        font(size: size, weight: .bold, lang: lang)
    }

    static func heading(_ size: CGFloat, lang: AppLanguage = .english) -> Font {
        font(size: size, weight: .semibold, lang: lang)
    }

    static func body(_ size: CGFloat, lang: AppLanguage = .english) -> Font {
        font(size: size, weight: .regular, lang: lang)
    }

    static func emphasis(_ size: CGFloat, lang: AppLanguage = .english) -> Font {
        font(size: size, weight: .medium, lang: lang)
    }

    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }

    /// Slide-content font: explicit size + weight, language-aware. Used by the
    /// renderer where size is already scaled to the canvas.
    static func scaled(size: CGFloat, weight: Font.Weight, lang: AppLanguage) -> Font {
        if lang == .arabic, let family = arabicCustomFamily {
            return .custom(family, size: size)
        }
        return .system(size: size, weight: weight)
    }

    private static func font(size: CGFloat, weight: Font.Weight, lang: AppLanguage) -> Font {
        if lang == .arabic, let family = arabicCustomFamily {
            return .custom(family, size: size)
        }
        return .system(size: size, weight: weight, design: .default)
    }
}

/// Canonical type scale used across the app UI (not slide content, which
/// stores its own sizes per block).
nonisolated enum FontSize {
    static let display: CGFloat = 34
    static let title: CGFloat = 28
    static let heading: CGFloat = 22
    static let body: CGFloat = 17
    static let callout: CGFloat = 15
    static let caption: CGFloat = 13
}

import Foundation
import SwiftUI

/// The content language of a deck or an individual slide/block.
///
/// `mixed` means language is decided per-block via `LanguageDetector`.
nonisolated enum AppLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
    case english
    case arabic
    case mixed

    var id: String { rawValue }

    /// Layout direction for this language. `mixed` resolves per-block, so it
    /// defaults to the user's reading direction at the container level.
    var layoutDirection: LayoutDirection {
        switch self {
        case .english: .leftToRight
        case .arabic: .rightToLeft
        case .mixed: .leftToRight
        }
    }

    var isRTL: Bool { self == .arabic }

    /// Short display label, localized at the call site via `displayNameKey`.
    var displayNameKey: String.LocalizationValue {
        switch self {
        case .english: "language.english"
        case .arabic: "language.arabic"
        case .mixed: "language.mixed"
        }
    }

    /// Non-localized fallback label (used in previews / logs).
    var rawDisplayName: String {
        switch self {
        case .english: "English"
        case .arabic: "العربية"
        case .mixed: "Mixed"
        }
    }
}

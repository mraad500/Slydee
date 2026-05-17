import Foundation

/// Lightweight script detection so mixed-language decks can tag each block
/// with the correct language (font + direction) without a heavy NLP model.
nonisolated enum LanguageDetector {
    static func containsArabic(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x0600...0x06FF, // Arabic
                 0x0750...0x077F, // Arabic Supplement
                 0x08A0...0x08FF, // Arabic Extended-A
                 0xFB50...0xFDFF, // Arabic Presentation Forms-A
                 0xFE70...0xFEFF: // Arabic Presentation Forms-B
                return true
            default:
                continue
            }
        }
        return false
    }

    /// Dominant language of a string. Arabic wins if any Arabic script is
    /// present (titles/terms in Latin stay readable either way).
    static func language(of text: String) -> AppLanguage {
        containsArabic(text) ? .arabic : .english
    }
}

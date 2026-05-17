import SwiftUI

/// Strongly-typed access to localized UI strings. Backed by
/// `Localizable.xcstrings` (English source + Arabic). Inline `Text("…")`
/// literals also localize via the same catalog; `L` is the typed entry point
/// for non-literal call sites.
/// MainActor-isolated (project default): only consumed from SwiftUI views.
enum L {
    enum tab {
        static let home: LocalizedStringKey = "Home"
        static let library: LocalizedStringKey = "Library"
        static let settings: LocalizedStringKey = "Settings"
    }

    enum home {
        static let newDeck: LocalizedStringKey = "New Presentation"
        static let recent: LocalizedStringKey = "Recent"
        static let templates: LocalizedStringKey = "Templates"
        static let emptyTitle: LocalizedStringKey = "Make your first deck →"
        static let tagline: LocalizedStringKey = "Beautiful slides in seconds."
    }

    enum create {
        static let configure: LocalizedStringKey = "Configure"
        static let generating: LocalizedStringKey = "Generating"
        static let generate: LocalizedStringKey = "Generate"
        static let next: LocalizedStringKey = "Next"
        static let back: LocalizedStringKey = "Back"
        static let close: LocalizedStringKey = "Close"
        static let done: LocalizedStringKey = "Done"
        static let cancel: LocalizedStringKey = "Cancel"
        static let language: LocalizedStringKey = "Language"
        static let slides: LocalizedStringKey = "Slides"
        static let template: LocalizedStringKey = "Template"
        static let tone: LocalizedStringKey = "Tone"
    }

    enum settings {
        static let generation: LocalizedStringKey = "Generation"
        static let defaultGenerator: LocalizedStringKey = "Default generator"
        static let claudeKey: LocalizedStringKey = "Claude API key"
        static let openAIKey: LocalizedStringKey = "OpenAI API key"
        static let appearance: LocalizedStringKey = "Appearance"
        static let appLanguage: LocalizedStringKey = "App language"
        static let about: LocalizedStringKey = "About"
        static let version: LocalizedStringKey = "Version"
    }
}

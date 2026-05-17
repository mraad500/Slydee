import Foundation

/// UI language preference (distinct from a deck's content language).
nonisolated enum UILanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english
    case arabic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .english: "English"
        case .arabic: "العربية"
        }
    }

    var locale: Locale? {
        switch self {
        case .system: nil
        case .english: Locale(identifier: "en")
        case .arabic: Locale(identifier: "ar")
        }
    }
}

/// Which generator the app prefers, overriding the per-language default.
nonisolated enum GeneratorPreference: String, CaseIterable, Identifiable, Sendable {
    case auto
    case onDevice
    case cloud

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: "Auto"
        case .onDevice: "On-device"
        case .cloud: "Claude / OpenAI"
        }
    }
}

/// UserDefaults-backed app preferences (non-secret). API keys live in
/// `KeychainStore`, never here.
nonisolated enum AppSettings {
    private enum DefaultsKey {
        static let uiLanguage = "settings.uiLanguage"
        static let generator = "settings.generator"
    }

    static var uiLanguage: UILanguage {
        get {
            UserDefaults.standard.string(forKey: DefaultsKey.uiLanguage)
                .flatMap(UILanguage.init(rawValue:)) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: DefaultsKey.uiLanguage)
        }
    }

    static var generatorPreference: GeneratorPreference {
        get {
            UserDefaults.standard.string(forKey: DefaultsKey.generator)
                .flatMap(GeneratorPreference.init(rawValue:)) ?? .auto
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: DefaultsKey.generator)
        }
    }

    static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

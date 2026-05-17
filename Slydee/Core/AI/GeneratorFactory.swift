import Foundation

/// Resolves which generator to use, honoring the user's `GeneratorPreference`
/// then falling back by language. Everything degrades to the deterministic
/// mock so generation never hard-fails.
nonisolated enum GeneratorFactory {
    static func generator(for language: AppLanguage) -> any AIGenerator {
        switch AppSettings.generatorPreference {
        case .onDevice:
            return onDeviceChain()
        case .cloud:
            return cloudChain()
        case .auto:
            switch language {
            case .english:
                return onDeviceChain()
            case .arabic, .mixed:
                return cloudChain()
            }
        }
    }

    private static func onDeviceChain() -> any AIGenerator {
        FallbackGenerator(
            primary: FoundationModelGenerator(),
            fallback: MockGenerator()
        )
    }

    /// Claude → OpenAI → Mock, depending on which keys are present.
    private static func cloudChain() -> any AIGenerator {
        let claudeKey = KeychainStore.read(.claude)
        let openAIKey = KeychainStore.read(.openAI)

        let lastResort: any AIGenerator = {
            if let openAIKey, !openAIKey.isEmpty {
                return FallbackGenerator(
                    primary: OpenAIGenerator(apiKey: openAIKey),
                    fallback: MockGenerator()
                )
            }
            return MockGenerator()
        }()

        if let claudeKey, !claudeKey.isEmpty {
            return FallbackGenerator(
                primary: ClaudeGenerator(apiKey: claudeKey),
                fallback: lastResort
            )
        }
        return lastResort
    }
}

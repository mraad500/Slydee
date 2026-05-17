import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class CreateViewModel {
    enum Step: Int { case input, configure, generating }

    enum InputMode: String, CaseIterable, Identifiable {
        case topic, file, image, search
        var id: String { rawValue }

        var label: LocalizedStringKey {
            switch self {
            case .topic: "Topic"
            case .file: "File"
            case .image: "Image"
            case .search: "Search"
            }
        }

        var icon: String {
            switch self {
            case .topic: "text.cursor"
            case .file: "doc.text"
            case .image: "photo"
            case .search: "magnifyingglass"
            }
        }

        /// Search is disabled in Phase 1 (per spec).
        var isEnabled: Bool { self != .search }
    }

    var step: Step = .input
    var inputMode: InputMode = .topic

    var topicText = ""
    var importedText = ""
    var importedLabel = ""
    var isExtracting = false
    var inputError: String?

    var language: AppLanguage = .english
    var slideCount = 8
    var tone: Tone = .educational
    var selectedTemplate: Template

    var statusText = ""
    var generationError: String?
    var resultDeck: Deck?

    /// Optional injected generator for previews/tests; production resolves via
    /// `GeneratorFactory` based on the chosen language.
    private let generatorOverride: (any AIGenerator)?
    private var generationTask: Task<Void, Never>?
    private var statusTask: Task<Void, Never>?

    init(template: Template?, generatorOverride: (any AIGenerator)? = nil) {
        selectedTemplate = template ?? TemplateCatalog.all[0]
        self.generatorOverride = generatorOverride
    }

    static let suggestedTopics: [String] = [
        "Marketing 101",
        "The Solar System",
        "نظرية النسبية",
        "Startup Pitch: EcoPack",
        "تاريخ الأندلس",
    ]

    var sourceText: String {
        switch inputMode {
        case .topic: topicText
        case .file, .image: importedText
        case .search: ""
        }
    }

    var trimmedSource: String {
        sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canContinueFromInput: Bool { !trimmedSource.isEmpty }

    func selectSuggestion(_ suggestion: String) {
        inputMode = .topic
        topicText = suggestion
        if LanguageDetector.containsArabic(suggestion) { language = .arabic }
    }

    func importFile(_ url: URL) {
        isExtracting = true
        inputError = nil
        Task {
            do {
                let text = try await SourceTextExtractor.extract(from: url)
                importedText = text
                importedLabel = url.lastPathComponent
                if LanguageDetector.containsArabic(text) { language = .arabic }
            } catch {
                inputError = error.localizedDescription
                importedText = ""
            }
            isExtracting = false
        }
    }

    func recognizeImage(_ data: Data) {
        isExtracting = true
        inputError = nil
        Task {
            do {
                let text = try await ImageTextRecognizer.recognize(imageData: data)
                importedText = text
                importedLabel = "Scanned image"
                if LanguageDetector.containsArabic(text) { language = .arabic }
            } catch {
                inputError = error.localizedDescription
                importedText = ""
            }
            isExtracting = false
        }
    }

    func goToConfigure() {
        if canContinueFromInput { step = .configure }
    }

    func generate(context: ModelContext) {
        guard canContinueFromInput else { return }
        step = .generating
        generationError = nil
        startStatusCycle()

        let request = GenerationRequest(
            sourceText: trimmedSource,
            language: language,
            slideCount: slideCount,
            tone: tone
        )
        let gen = generatorOverride ?? GeneratorFactory.generator(for: language)
        let template = selectedTemplate
        let src = trimmedSource

        generationTask = Task {
            do {
                let generated = try await gen.generate(request)
                try Task.checkCancellation()
                let deck = DeckBuilder.build(
                    generated, template: template, sourceText: src, into: context
                )
                try? context.save()
                stopStatusCycle()
                resultDeck = deck
            } catch is CancellationError {
                stopStatusCycle()
            } catch {
                stopStatusCycle()
                generationError = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
            }
        }
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        stopStatusCycle()
        step = .configure
    }

    private var statusMessages: [String] {
        language == .arabic
            ? ["نقرأ مدخلاتك…", "نُجهّز المخطط…", "نلمّع الشرائح…"]
            : ["Reading your input…", "Outlining…", "Polishing…"]
    }

    private func startStatusCycle() {
        statusText = statusMessages.first ?? "Working…"
        statusTask = Task {
            var index = 0
            while !Task.isCancelled {
                statusText = statusMessages[index % statusMessages.count]
                index += 1
                try? await Task.sleep(for: .seconds(2.2))
            }
        }
    }

    private func stopStatusCycle() {
        statusTask?.cancel()
        statusTask = nil
    }
}

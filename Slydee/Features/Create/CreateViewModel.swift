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

        /// Web search needs a Google Programmable Search key/cx, which the app
        /// no longer collects (single bundled Gemini key only) — kept in the
        /// model but disabled in the UI so no broken feature ships.
        var isEnabled: Bool { self != .search }
    }

    var step: Step = .input
    var inputMode: InputMode = .topic

    var topicText = ""
    var importedText = ""
    var importedLabel = ""
    var isExtracting = false
    var inputError: String?

    // Web search (Phase 3)
    var searchQuery = ""
    var searchResults: [WebResult] = []
    var selectedResultIDs: Set<UUID> = []
    var isSearching = false
    var searchError: String?

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
        case .file, .image, .search: importedText
        }
    }

    var hasSelectedResults: Bool { !selectedResultIDs.isEmpty }

    func toggleResult(_ result: WebResult) {
        if selectedResultIDs.contains(result.id) {
            selectedResultIDs.remove(result.id)
        } else {
            selectedResultIDs.insert(result.id)
        }
        let chosen = searchResults.filter { selectedResultIDs.contains($0.id) }
        importedText = chosen.map(\.asSourceText).joined(separator: "\n\n")
        importedLabel = "\(chosen.count) web source(s)"
    }

    func runSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        guard let key = KeychainStore.read(.googleKey), !key.isEmpty,
              let cx = KeychainStore.read(.googleCX), !cx.isEmpty
        else {
            searchError = "Add your Google API key and Search Engine ID in Settings."
            return
        }
        isSearching = true
        searchError = nil
        let client = GoogleSearchClient(apiKey: key, cx: cx)
        Task {
            do {
                searchResults = try await client.search(query)
                if searchResults.isEmpty { searchError = "No results." }
            } catch {
                searchError = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
                searchResults = []
            }
            isSearching = false
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

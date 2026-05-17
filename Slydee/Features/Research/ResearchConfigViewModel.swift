import Foundation
import SwiftData
import SwiftUI

/// State + validation + (mock) generation for the research flow. Mirrors
/// `CreateViewModel`'s shape so the two flows feel identical.
@MainActor
@Observable
final class ResearchConfigViewModel {
    enum Phase: Int { case config, generating }

    // MARK: Form state
    var topic = ""
    var language: AppLanguage = .english
    var tone: ResearchTone = .academic
    var lengthMode: ResearchLengthMode = .words {
        didSet { lengthValue = lengthMode.defaultValue }
    }
    var lengthValue = ResearchLengthMode.words.defaultValue

    // MARK: Flow state
    var phase: Phase = .config
    var statusText = ""
    var generationError: String?
    var resultDocument: ResearchDocument?

    private let generatorOverride: (any ResearchGenerator)?
    private var generationTask: Task<Void, Never>?
    private var statusTask: Task<Void, Never>?

    init(generatorOverride: (any ResearchGenerator)? = nil) {
        self.generatorOverride = generatorOverride
    }

    static let suggestedTopics: [String] = [
        "The economics of renewable energy",
        "أثر الذكاء الاصطناعي على التعليم",
        "Urban planning and public health",
        "نظرية النسبية وتطبيقاتها",
    ]

    var trimmedTopic: String {
        topic.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canGenerate: Bool { !trimmedTopic.isEmpty }

    func selectSuggestion(_ suggestion: String) {
        topic = suggestion
        if LanguageDetector.containsArabic(suggestion) { language = .arabic }
    }

    func generate(context: ModelContext) {
        guard canGenerate else { return }
        phase = .generating
        generationError = nil
        startStatusCycle()

        let request = ResearchRequest(
            topic: trimmedTopic,
            language: language,
            tone: tone,
            lengthMode: lengthMode,
            lengthValue: lengthValue
        )
        let generator = generatorOverride ?? ResearchGeneratorFactory.generator(for: language)

        generationTask = Task {
            do {
                let generated = try await generator.generate(request)
                try Task.checkCancellation()
                let document = ResearchDocument(
                    title: generated.title,
                    topic: request.topic,
                    language: request.language,
                    tone: request.tone,
                    lengthMode: request.lengthMode,
                    lengthValue: request.lengthValue,
                    sections: generated.sections
                )
                context.insert(document)
                try? context.save()
                stopStatusCycle()
                resultDocument = document
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
        phase = .config
    }

    // MARK: Status ticker

    private var statusMessages: [String] {
        language == .arabic
            ? ["نقرأ موضوعك…", "نبني الهيكل…", "نكتب الفقرات…", "نراجع ونلمّع…"]
            : ["Reading your topic…", "Structuring…", "Writing sections…", "Polishing…"]
    }

    private func startStatusCycle() {
        statusText = statusMessages.first ?? "Working…"
        statusTask = Task {
            var index = 0
            while !Task.isCancelled {
                statusText = statusMessages[index % statusMessages.count]
                index += 1
                try? await Task.sleep(for: .seconds(2.0))
            }
        }
    }

    private func stopStatusCycle() {
        statusTask?.cancel()
        statusTask = nil
    }
}

import Foundation
import Vision

/// On-device OCR (Vision) for the "Image" input mode. Recognizes Arabic and
/// English so scanned bilingual notes work.
nonisolated enum ImageTextRecognizer {
    enum OCRError: LocalizedError {
        case badImage
        case noText

        var errorDescription: String? {
            switch self {
            case .badImage: "That image couldn’t be read."
            case .noText: "No text was found in the image."
            }
        }
    }

    static func recognize(imageData: Data) async throws -> String {
        let text: String = try await withCheckedThrowingContinuation { continuation in
            let handler = VNImageRequestHandler(data: imageData, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ar", "en"]
            request.usesLanguageCorrection = true
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw OCRError.noText }
        return trimmed
    }
}

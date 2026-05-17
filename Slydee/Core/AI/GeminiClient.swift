import Foundation

/// Thin wrapper over Google Gemini (Generative Language API)
/// `models/{model}:generateContent`. Requests JSON output so deck/research
/// parsers get clean structured text. Key is read from the git-ignored
/// `Secrets` (never user-entered, never in the repo).
nonisolated enum GeminiClient {
    private static let base = "https://generativelanguage.googleapis.com/v1beta/models"

    /// Sends a system + user prompt, returns the model's raw text (JSON).
    static func generateJSON(system: String, user: String) async throws -> String {
        guard Secrets.hasGemini else { throw GenerationError.missingAPIKey }

        let endpoint = "\(base)/\(Secrets.geminiModel):generateContent?key=\(Secrets.geminiAPIKey)"
        guard let url = URL(string: endpoint) else { throw GenerationError.invalidResponse }

        let payload = Request(
            systemInstruction: .init(parts: [.init(text: system)]),
            contents: [.init(role: "user", parts: [.init(text: user)])],
            generationConfig: .init(
                responseMimeType: "application/json",
                temperature: 0.7,
                maxOutputTokens: 8192
            )
        )
        let body = try JSONEncoder().encode(payload)

        let data: Data
        do {
            data = try await APIClient.postJSON(
                url: url,
                headers: ["Content-Type": "application/json"],
                body: body
            )
        } catch let APIClient.APIError.http(_, message) {
            throw GenerationError.network(message)
        } catch let APIClient.APIError.transport(message) {
            throw GenerationError.network(message)
        }

        try Task.checkCancellation()

        guard
            let decoded = try? JSONDecoder().decode(Response.self, from: data),
            let text = decoded.candidates?
                .first?.content?.parts?
                .compactMap(\.text).first,
            !text.isEmpty
        else { throw GenerationError.invalidResponse }

        return text
    }

    // MARK: Wire types

    private nonisolated struct Request: Encodable {
        struct Part: Encodable { var text: String }
        struct Content: Encodable {
            var role: String?
            var parts: [Part]
        }
        struct SystemInstruction: Encodable { var parts: [Part] }
        struct GenerationConfig: Encodable {
            var responseMimeType: String
            var temperature: Double
            var maxOutputTokens: Int
        }

        var systemInstruction: SystemInstruction
        var contents: [Content]
        var generationConfig: GenerationConfig
    }

    private nonisolated struct Response: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable { var text: String? }
                var parts: [Part]?
            }
            var content: Content?
        }
        var candidates: [Candidate]?
    }
}

import Foundation

/// Minimal async JSON transport shared by the Claude and OpenAI generators.
nonisolated enum APIClient {
    enum APIError: LocalizedError {
        case http(Int, String)
        case transport(String)

        var errorDescription: String? {
            switch self {
            case let .http(code, _):
                "The AI service returned an error (HTTP \(code))."
            case let .transport(message):
                message
            }
        }
    }

    static func getJSON(url: URL, headers: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport("No HTTP response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let snippet = String(data: data.prefix(400), encoding: .utf8) ?? ""
            throw APIError.http(http.statusCode, snippet)
        }
        return data
    }

    static func postJSON(
        url: URL,
        headers: [String: String],
        body: Data
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.timeoutInterval = 60
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport("No HTTP response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let snippet = String(data: data.prefix(400), encoding: .utf8) ?? ""
            throw APIError.http(http.statusCode, snippet)
        }
        return data
    }
}

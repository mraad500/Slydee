import Foundation

/// Google Programmable Search (Custom Search JSON API). Needs an API key and
/// a Search Engine ID (cx), both stored in the Keychain.
nonisolated struct GoogleSearchClient {
    let apiKey: String
    let cx: String

    func search(_ query: String) async throws -> [WebResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty, !cx.isEmpty else { throw GenerationError.missingAPIKey }
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(string: "https://www.googleapis.com/customsearch/v1")!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "cx", value: cx),
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "num", value: "8"),
        ]
        guard let url = components.url else { throw GenerationError.invalidResponse }

        let data: Data
        do {
            data = try await APIClient.getJSON(url: url)
        } catch let APIClient.APIError.http(code, _) where code == 401 || code == 403 {
            throw GenerationError.missingAPIKey
        } catch let APIClient.APIError.http(_, message) {
            throw GenerationError.network(message)
        } catch let APIClient.APIError.transport(message) {
            throw GenerationError.network(message)
        }

        guard let response = try? JSONDecoder().decode(GoogleResponse.self, from: data) else {
            throw GenerationError.invalidResponse
        }
        return (response.items ?? []).map { item in
            WebResult(
                title: item.title,
                snippet: item.snippet ?? "",
                url: item.link,
                imageURL: item.pagemap?.cseImage?.first?.src
            )
        }
    }
}

private nonisolated struct GoogleResponse: Decodable {
    struct Item: Decodable {
        var title: String
        var snippet: String?
        var link: String
        var pagemap: Pagemap?
    }

    struct Pagemap: Decodable {
        var cseImage: [CSEImage]?
        enum CodingKeys: String, CodingKey { case cseImage = "cse_image" }
    }

    struct CSEImage: Decodable { var src: String }

    var items: [Item]?
}

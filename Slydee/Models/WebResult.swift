import Foundation

/// A single web search result (Google Custom Search JSON API).
nonisolated struct WebResult: Identifiable, Sendable, Hashable {
    let id = UUID()
    let title: String
    let snippet: String
    let url: String
    let imageURL: String?

    /// Source text contribution with an inline citation.
    var asSourceText: String {
        "\(title)\n\(snippet)\n(Source: \(url))"
    }
}

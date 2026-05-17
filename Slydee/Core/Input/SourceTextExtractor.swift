import Foundation
import PDFKit

/// Extracts plain text from an imported document. Phase 1 supports PDF and
/// plain-text family files; DOCX is deferred to Phase 2 (needs a zip/XML
/// parser).
nonisolated enum SourceTextExtractor {
    enum ExtractError: LocalizedError {
        case unsupported(String)
        case unreadable

        var errorDescription: String? {
            switch self {
            case let .unsupported(ext):
                "‘.\(ext)’ files aren’t supported yet. Try a PDF or text file."
            case .unreadable:
                "Couldn’t read that file. It may be empty or protected."
            }
        }
    }

    static func extract(from url: URL) async throws -> String {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf":
            guard let document = PDFDocument(url: url) else { throw ExtractError.unreadable }
            let text = (0..<document.pageCount)
                .compactMap { document.page(at: $0)?.string }
                .joined(separator: "\n")
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ExtractError.unreadable
            }
            return text
        case "txt", "text", "md", "markdown", "csv":
            if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
                return utf8
            }
            guard let data = try? Data(contentsOf: url),
                  let text = String(data: data, encoding: .isoLatin1)
            else { throw ExtractError.unreadable }
            return text
        default:
            throw ExtractError.unsupported(ext)
        }
    }
}

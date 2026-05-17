import CoreGraphics
import Foundation
import SwiftUI

/// Renders a deck to a 1920×1080 (16:9) vector PDF that opens cleanly in
/// Keynote and PowerPoint. Uses `ImageRenderer` so slide text stays sharp.
@MainActor
enum PDFExporter {
    static let pageSize = CGSize(width: 1920, height: 1080)

    static func export(deck: Deck) async -> URL? {
        let slides = deck.orderedSlides
        guard !slides.isEmpty else { return nil }

        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data) else { return nil }
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let pdf = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }

        for slide in slides {
            let renderer = ImageRenderer(
                content: SlideCanvas(slide: slide, theme: deck.theme, size: pageSize)
            )
            renderer.proposedSize = ProposedViewSize(pageSize)
            renderer.render { _, drawInContext in
                pdf.beginPDFPage(nil)
                drawInContext(pdf)
                pdf.endPDFPage()
            }
        }
        pdf.closePDF()

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeFileName(deck.title)).pdf")
        do {
            try (data as Data).write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private static func safeFileName(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "Slydee Deck" : trimmed
        let illegal = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        return base.components(separatedBy: illegal).joined(separator: "-")
    }
}

import CoreText
import Foundation
import UIKit

/// Renders a `ResearchDocument` to a multi-page A4 PDF with real, selectable,
/// reflowing text (CoreText pagination) — not slide images. RTL-aware per
/// section so Arabic paragraphs lay out correctly.
@MainActor
enum ResearchPDFExporter {
    private static let pageSize = CGSize(width: 595.28, height: 841.89) // A4 @72dpi
    private static let margin: CGFloat = 56

    static func export(_ document: ResearchDocument) async -> URL? {
        let attributed = makeAttributedString(document)
        guard attributed.length > 0 else { return nil }

        let data = NSMutableData()
        let pageRect = CGRect(origin: .zero, size: pageSize)
        let textRect = pageRect.insetBy(dx: margin, dy: margin)

        UIGraphicsBeginPDFContextToData(data, pageRect, nil)
        defer { UIGraphicsEndPDFContext() }

        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        var charIndex = 0
        let total = attributed.length

        while charIndex < total {
            UIGraphicsBeginPDFPage()
            guard let ctx = UIGraphicsGetCurrentContext() else { break }

            // CoreText draws bottom-up; flip into UIKit's top-down space.
            ctx.textMatrix = .identity
            ctx.translateBy(x: 0, y: pageSize.height)
            ctx.scaleBy(x: 1, y: -1)

            let framePath = CGPath(
                rect: CGRect(
                    x: textRect.minX,
                    y: pageSize.height - textRect.maxY,
                    width: textRect.width,
                    height: textRect.height
                ),
                transform: nil
            )
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: charIndex, length: 0),
                framePath,
                nil
            )
            CTFrameDraw(frame, ctx)

            let visible = CTFrameGetVisibleStringRange(frame)
            if visible.length == 0 { break } // safety: avoid infinite loop
            charIndex += visible.length
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeName(document.displayTitle)).pdf")
        do {
            try (data as Data).write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // MARK: Attributed text

    private static func makeAttributedString(_ document: ResearchDocument) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for section in document.sections {
            let isArabic = LanguageDetector.containsArabic(section.text)
            let paragraph = NSMutableParagraphStyle()
            paragraph.baseWritingDirection = isArabic ? .rightToLeft : .leftToRight
            paragraph.lineSpacing = 3

            switch section.style {
            case .title:
                paragraph.alignment = .center
                paragraph.paragraphSpacing = 18
            case .heading:
                paragraph.alignment = isArabic ? .right : .left
                paragraph.paragraphSpacingBefore = 18
                paragraph.paragraphSpacing = 8
            case .subheading:
                paragraph.alignment = isArabic ? .right : .left
                paragraph.paragraphSpacingBefore = 10
                paragraph.paragraphSpacing = 4
            case .body:
                paragraph.alignment = isArabic ? .right : .justified
                paragraph.paragraphSpacing = 10
            case .quote:
                paragraph.alignment = .center
                paragraph.firstLineHeadIndent = 24
                paragraph.headIndent = 24
                paragraph.tailIndent = -24
                paragraph.paragraphSpacing = 12
            }

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font(for: section.style),
                .foregroundColor: color(for: section.style),
                .paragraphStyle: paragraph,
            ]
            result.append(NSAttributedString(
                string: section.text + "\n",
                attributes: attributes
            ))
        }
        return result
    }

    private static func font(for style: ResearchSectionStyle) -> UIFont {
        switch style {
        case .title: .systemFont(ofSize: 26, weight: .bold)
        case .heading: .systemFont(ofSize: 19, weight: .semibold)
        case .subheading: .systemFont(ofSize: 16, weight: .semibold)
        case .body: .systemFont(ofSize: 12, weight: .regular)
        case .quote: .italicSystemFont(ofSize: 13)
        }
    }

    private static func color(for style: ResearchSectionStyle) -> UIColor {
        switch style {
        case .quote: UIColor(white: 0.32, alpha: 1)
        default: UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1)
        }
    }

    private static func safeName(_ raw: String) -> String {
        let base = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = base.isEmpty ? "Slydee Research" : base
        return cleaned.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>"))
            .joined(separator: "-")
    }
}

import SwiftUI

/// Renders one `Slide` at an exact pixel size (16:9). Layout-agnostic: blocks
/// are positioned by their relative frames, so titleOnly / titleContent /
/// twoColumn / quote all render through the same path. Reused by the paged
/// viewer, thumbnails, and PDF export.
struct SlideCanvas: View {
    let slide: Slide
    let theme: ThemeID
    let size: CGSize

    /// 16:9 size for a given width.
    static func size(forWidth width: CGFloat) -> CGSize {
        CGSize(width: width, height: (width * 9 / 16).rounded())
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            slide.background.view(theme: theme)
                .frame(width: size.width, height: size.height)

            ForEach(slide.orderedBlocks) { block in
                BlockView(block: block, canvas: size)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

private struct BlockView: View {
    let block: Block
    let canvas: CGSize

    private var scale: CGFloat {
        canvas.width / CGFloat(DeckBuilder.referenceWidth)
    }

    var body: some View {
        let rect = block.frame.absolute(in: canvas)

        content
            .frame(width: rect.width, height: rect.height, alignment: boxAlignment)
            .position(x: rect.midX, y: rect.midY)
            .rotationEffect(.degrees(block.rotation))
            .opacity(block.opacity)
    }

    @ViewBuilder
    private var content: some View {
        switch block.content {
        case let .text(text):
            textView(text)
        case let .sticker(stickerID):
            Image(systemName: stickerID)
                .resizable()
                .scaledToFit()
        case .image, .shape, .chart, .none:
            EmptyView()
        }
    }

    private func textView(_ text: TextContent) -> some View {
        Text(text.text)
            .font(SlydeeFont.scaled(
                size: CGFloat(text.size) * scale,
                weight: text.weight.swiftUI,
                lang: text.language
            ))
            .foregroundStyle(Color(hex: text.colorHex))
            .multilineTextAlignment(text.align.textAlignment)
            .lineSpacing(6 * scale)
            .minimumScaleFactor(0.4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: boxAlignment)
            .environment(
                \.layoutDirection,
                text.language == .arabic ? .rightToLeft : .leftToRight
            )
    }

    /// Centre cover/quote text; otherwise top-align and follow the text's
    /// horizontal alignment (leading for LTR, trailing for RTL).
    private var boxAlignment: Alignment {
        guard case let .text(text) = block.content else { return .center }
        if text.align == .center { return .center }
        return Alignment(horizontal: text.align.frameAlignment.horizontal, vertical: .top)
    }
}

#Preview {
    let slide = Slide(index: 0, layout: .titleContent, language: .english)
    slide.blocks = [
        Block.text(
            "Designing for Clarity", fontToken: "heading", size: 46, weight: .bold,
            colorHex: "0F0F0F", align: .leading, language: .english,
            frame: RelativeFrame(x: 0.07, y: 0.09, width: 0.86, height: 0.16)
        ),
        Block.text(
            "•  Lead with one idea per slide\n•  Keep bullets under 12 words\n•  Let whitespace breathe",
            fontToken: "body", size: 30, weight: .regular,
            colorHex: "0F0F0F", align: .leading, language: .english,
            frame: RelativeFrame(x: 0.07, y: 0.30, width: 0.86, height: 0.60)
        ),
    ]
    return SlideCanvas(
        slide: slide,
        theme: .sun,
        size: SlideCanvas.size(forWidth: 360)
    )
    .border(Color.slydeeHairline)
}

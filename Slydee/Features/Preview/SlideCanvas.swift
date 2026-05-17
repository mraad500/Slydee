import Charts
import SwiftUI
import UIKit

/// Renders one `Slide` at an exact pixel size (16:9). Layout-agnostic. Reused
/// by the paged viewer, thumbnails, PDF export, and the editor. When
/// `animated` is true, blocks play their entrance animations on appear.
struct SlideCanvas: View {
    let slide: Slide
    let theme: ThemeID
    let size: CGSize
    var animated: Bool = false

    static func size(forWidth width: CGFloat) -> CGSize {
        CGSize(width: width, height: (width * 9 / 16).rounded())
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            slide.background.view(theme: theme)
                .frame(width: size.width, height: size.height)

            ForEach(slide.orderedBlocks) { block in
                BlockView(block: block, canvas: size, theme: theme, animated: animated)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

/// Positions a block at its relative frame and plays entrance animation.
struct BlockView: View {
    let block: Block
    let canvas: CGSize
    let theme: ThemeID
    var animated: Bool = false

    @State private var shown = false

    private var anim: BlockAnimation? {
        guard animated, let a = block.animation, a.kind != .none else { return nil }
        return a
    }

    var body: some View {
        let rect = block.frame.absolute(in: canvas)
        let visible = anim == nil ? true : shown

        BlockContentView(block: block, canvas: canvas, theme: theme)
            .frame(width: rect.width, height: rect.height)
            .rotationEffect(.degrees(block.rotation))
            .opacity(block.opacity * entranceOpacity(visible))
            .scaleEffect(entranceScale(visible))
            .offset(entranceOffset(visible))
            .position(x: rect.midX, y: rect.midY)
            .onAppear {
                guard let anim else { return }
                withAnimation(curve(for: anim).delay(anim.delay)) { shown = true }
            }
    }

    private func curve(for anim: BlockAnimation) -> Animation {
        switch anim.kind {
        case .bounce: .spring(response: anim.duration, dampingFraction: 0.55)
        case .scale: .spring(response: anim.duration, dampingFraction: 0.8)
        default: .easeOut(duration: anim.duration)
        }
    }

    private func entranceOpacity(_ visible: Bool) -> Double {
        guard let anim else { return 1 }
        if anim.kind == .fade || anim.kind == .scale { return visible ? 1 : 0 }
        return visible ? 1 : (anim.kind == .slide ? 1 : 0)
    }

    private func entranceScale(_ visible: Bool) -> CGFloat {
        guard let anim, anim.kind == .scale || anim.kind == .bounce else { return 1 }
        return visible ? 1 : 0.5
    }

    private func entranceOffset(_ visible: Bool) -> CGSize {
        guard let anim, anim.kind == .slide, !visible else { return .zero }
        switch anim.edge {
        case .leading: return CGSize(width: -canvas.width * 0.35, height: 0)
        case .trailing: return CGSize(width: canvas.width * 0.35, height: 0)
        case .top: return CGSize(width: 0, height: -canvas.height * 0.35)
        case .bottom: return CGSize(width: 0, height: canvas.height * 0.35)
        }
    }
}

/// The visual content of a block, filling whatever frame it's given. No
/// positioning — used by both the read-only canvas and the editor.
struct BlockContentView: View {
    let block: Block
    let canvas: CGSize
    let theme: ThemeID

    private var scale: CGFloat {
        canvas.width / CGFloat(DeckBuilder.referenceWidth)
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: boxAlignment)
    }

    @ViewBuilder
    private var content: some View {
        switch block.content {
        case let .text(text):
            textView(text)
        case let .image(image):
            imageView(image)
        case let .sticker(stickerID):
            Image(systemName: stickerID)
                .resizable()
                .scaledToFit()
                .foregroundStyle(theme.primaryText)
        case let .shape(shape):
            shapeView(shape)
        case let .chart(chart):
            chartView(chart)
        case .none:
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

    @ViewBuilder
    private func imageView(_ image: ImageContent) -> some View {
        if let data = image.data, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            ZStack {
                Color.slydeeHairline.opacity(0.4)
                Image(systemName: image.sfSymbol ?? "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44 * scale, height: 44 * scale)
                    .foregroundStyle(Color.slydeeInkMuted)
            }
        }
    }

    @ViewBuilder
    private func shapeView(_ shape: ShapeContent) -> some View {
        let fill = Color(hex: shape.fillHex)
        switch shape.kind {
        case "ellipse":
            Ellipse().fill(fill)
        case "line":
            Rectangle().fill(fill).frame(height: max(2, 4 * scale))
        default:
            RoundedRectangle(cornerRadius: 8 * scale, style: .continuous).fill(fill)
        }
    }

    @ViewBuilder
    private func chartView(_ chart: ChartContent) -> some View {
        let points = Array(zip(chart.labels, chart.values).enumerated())
        Chart {
            ForEach(points, id: \.offset) { _, pair in
                switch chart.kind {
                case "line":
                    LineMark(x: .value("Label", pair.0), y: .value("Value", pair.1))
                        .foregroundStyle(theme.accent)
                case "pie":
                    SectorMark(angle: .value("Value", pair.1), innerRadius: .ratio(0.5))
                        .foregroundStyle(by: .value("Label", pair.0))
                default:
                    BarMark(x: .value("Label", pair.0), y: .value("Value", pair.1))
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .chartForegroundStyleScale(range: [Color.slydeeSun, .slydeeSky, .slydeeMint, .slydeeLavender, .slydeePeach])
        .foregroundStyle(theme.primaryText)
        .padding(8 * scale)
    }

    var boxAlignment: Alignment {
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
    ]
    return SlideCanvas(slide: slide, theme: .sun, size: SlideCanvas.size(forWidth: 360))
        .border(Color.slydeeHairline)
}

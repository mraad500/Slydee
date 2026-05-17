import SwiftData
import SwiftUI

/// Interactive editing surface: tap to select, drag to move, pinch to resize,
/// two-finger rotate. Transient gesture state previews live; changes commit to
/// the model on gesture end.
struct EditableSlideCanvas: View {
    @Bindable var model: EditorViewModel
    let slide: Slide
    let theme: ThemeID
    let size: CGSize

    @GestureState private var drag: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var spin: Angle = .zero

    var body: some View {
        ZStack(alignment: .topLeading) {
            slide.background.view(theme: theme)
                .frame(width: size.width, height: size.height)
                .contentShape(Rectangle())
                .onTapGesture { model.select(nil) }

            ForEach(slide.orderedBlocks) { block in
                blockView(block)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    @ViewBuilder
    private func blockView(_ block: Block) -> some View {
        let selected = model.selectedBlockID == block.persistentModelID
        let stored = block.frame.absolute(in: size)
        let liveScale: CGFloat = selected ? pinch : 1
        let liveW = stored.width * liveScale
        let liveH = stored.height * liveScale
        let cx = stored.midX + (selected ? drag.width : 0)
        let cy = stored.midY + (selected ? drag.height : 0)
        let rotation = Angle.degrees(block.rotation) + (selected ? spin : .zero)

        BlockContentView(block: block, canvas: size, theme: theme)
            .frame(width: liveW, height: liveH)
            .rotationEffect(rotation)
            .overlay(selectionChrome(visible: selected))
            .contentShape(Rectangle())
            .position(x: cx, y: cy)
            .onTapGesture { model.select(block) }
            .gesture(selected ? transformGesture(block) : nil)
            .animation(.interactiveSpring, value: selected)
    }

    @ViewBuilder
    private func selectionChrome(visible: Bool) -> some View {
        if visible {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(
                    Color.slydeeInk,
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
                .overlay(alignment: .topLeading) { handle }
                .overlay(alignment: .topTrailing) { handle }
                .overlay(alignment: .bottomLeading) { handle }
                .overlay(alignment: .bottomTrailing) { handle }
        }
    }

    private var handle: some View {
        Circle()
            .fill(Color.slydeeSun)
            .overlay(Circle().strokeBorder(Color.slydeeInk, lineWidth: 1))
            .frame(width: 12, height: 12)
    }

    private func transformGesture(_ block: Block) -> some Gesture {
        let move = DragGesture()
            .updating($drag) { value, state, _ in state = value.translation }
            .onEnded { value in
                var f = block.frame
                f.x += Double(value.translation.width / size.width)
                f.y += Double(value.translation.height / size.height)
                model.commitTransform(block, frame: f, rotation: block.rotation)
            }

        let resize = MagnifyGesture()
            .updating($pinch) { value, state, _ in state = value.magnification }
            .onEnded { value in
                var f = block.frame
                let cxRel = f.x + f.width / 2
                let cyRel = f.y + f.height / 2
                f.width *= Double(value.magnification)
                f.height *= Double(value.magnification)
                f.x = cxRel - f.width / 2
                f.y = cyRel - f.height / 2
                model.commitTransform(block, frame: f, rotation: block.rotation)
            }

        let rotate = RotateGesture()
            .updating($spin) { value, state, _ in state = value.rotation }
            .onEnded { value in
                model.commitTransform(
                    block,
                    frame: block.frame,
                    rotation: block.rotation + value.rotation.degrees
                )
            }

        return move.simultaneously(with: resize).simultaneously(with: rotate)
    }
}

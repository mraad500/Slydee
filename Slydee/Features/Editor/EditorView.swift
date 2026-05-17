import PhotosUI
import SwiftData
import SwiftUI

struct EditorView: View {
    let deck: Deck
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var model: EditorViewModel?
    @State private var editingText = false
    @State private var editingChart = false
    @State private var editingAnim = false
    @State private var editingSlide = false
    @State private var showStickers = false
    @State private var showPhotos = false
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        Group {
            if let model {
                editor(model)
            } else {
                Color.slydeeCream.ignoresSafeArea()
            }
        }
        .task {
            if model == nil {
                model = EditorViewModel(deck: deck, context: context)
            }
        }
    }

    private func editor(_ model: EditorViewModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 0) {
            topBar(model)
            Divider().overlay(Color.slydeeHairline)

            GeometryReader { geo in
                let canvas = SlideCanvas.size(
                    forWidth: min(geo.size.width - Spacing.lg * 2, geo.size.height - Spacing.lg)
                )
                ZStack {
                    Color.slydeeCream
                    if let slide = model.currentSlide {
                        EditableSlideCanvas(
                            model: model, slide: slide, theme: deck.theme, size: canvas
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .strokeBorder(Color.slydeeHairline, lineWidth: 1)
                        )
                        .shadow(color: Color.slydeeInk.opacity(0.08), radius: 10, y: 5)
                    } else {
                        Text("No slides")
                            .font(SlydeeFont.body(FontSize.body))
                            .foregroundStyle(Color.slydeeInkMuted)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if model.selectedBlock != nil {
                selectionBar(model)
            }
            Divider().overlay(Color.slydeeHairline)
            filmstrip(model)
        }
        .background(Color.slydeeCream.ignoresSafeArea())
        .sheet(isPresented: $editingText) {
            if let block = model.selectedBlock {
                TextInspectorView(model: model, block: block)
            }
        }
        .sheet(isPresented: $editingChart) {
            if let block = model.selectedBlock {
                ChartInspectorView(model: model, block: block)
            }
        }
        .sheet(isPresented: $editingAnim) {
            if let block = model.selectedBlock {
                AnimationInspectorView(model: model, block: block)
            }
        }
        .sheet(isPresented: $editingSlide) {
            if let slide = model.currentSlide {
                SlideInspectorView(model: model, slide: slide)
            }
        }
        .sheet(isPresented: $showStickers) {
            StickerPickerView { symbol in model.addSticker(symbol) }
        }
        .photosPicker(isPresented: $showPhotos, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    model.addImage(data)
                }
                photoItem = nil
            }
        }
    }

    private func topBar(_ model: EditorViewModel) -> some View {
        HStack(spacing: Spacing.lg) {
            Button("Done") {
                model.save()
                dismiss()
            }
            .fontWeight(.semibold)

            Button { model.undo() } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!model.canUndo)
            Button { model.redo() } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!model.canRedo)

            Menu {
                Button { model.addText() } label: { Label("Text", systemImage: "textformat") }
                Button { showPhotos = true } label: { Label("Image", systemImage: "photo") }
                Button { showStickers = true } label: { Label("Sticker", systemImage: "face.smiling") }
                Button { model.addChart() } label: { Label("Chart", systemImage: "chart.bar") }
            } label: {
                Image(systemName: "plus.circle.fill")
            }

            Spacer()

            Button { model.addSlide() } label: {
                Image(systemName: "rectangle.stack.badge.plus")
            }
            Button { model.duplicateCurrentSlide() } label: {
                Image(systemName: "plus.square.on.square")
            }
            Button(role: .destructive) { model.deleteCurrentSlide() } label: {
                Image(systemName: "trash")
            }
            .disabled(model.slides.count <= 1)
            Button { editingSlide = true } label: {
                Image(systemName: "slider.horizontal.3")
            }
        }
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(Color.slydeeInk)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.slydeeSurface)
    }

    private func filmstrip(_ model: EditorViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(Array(model.slides.enumerated()), id: \.element.id) { index, slide in
                    Button {
                        model.selectSlide(index)
                    } label: {
                        SlideCanvas(
                            slide: slide,
                            theme: deck.theme,
                            size: SlideCanvas.size(forWidth: 116)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                                .strokeBorder(
                                    index == model.selectedSlideIndex
                                        ? Color.slydeeInk : Color.slydeeHairline,
                                    lineWidth: index == model.selectedSlideIndex ? 2.5 : 1
                                )
                        )
                        .overlay(alignment: .topLeading) {
                            Text("\(index + 1)")
                                .font(SlydeeFont.body(FontSize.caption))
                                .foregroundStyle(Color.slydeeInk)
                                .padding(4)
                                .background(Color.slydeeSurface.opacity(0.85), in: Capsule())
                                .padding(4)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.slydeeSurface)
    }

    private func selectionBar(_ model: EditorViewModel) -> some View {
        HStack(spacing: Spacing.xl) {
            if model.selectedBlock?.content?.asText != nil {
                barButton("Text", "textformat") {
                    editingText = true
                }
            }
            if case .chart = model.selectedBlock?.content {
                barButton("Chart", "chart.bar") {
                    editingChart = true
                }
            }
            barButton("Duplicate", "plus.square.on.square") {
                model.duplicateSelectedBlock()
            }
            barButton("Animate", "wand.and.stars") {
                editingAnim = true
            }
            barButton("Front", "square.3.layers.3d.top.filled") {
                model.bringSelectedToFront()
            }
            barButton("Delete", "trash") {
                model.deleteSelectedBlock()
            }
            Spacer()
            barButton("Deselect", "xmark.circle") {
                model.select(nil)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Color.slydeeSurface)
    }

    private func barButton(
        _ title: LocalizedStringKey,
        _ symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol).font(.system(size: 17, weight: .semibold))
                Text(title).font(SlydeeFont.body(FontSize.caption))
            }
            .foregroundStyle(Color.slydeeInk)
        }
        .buttonStyle(SpringButtonStyle())
    }
}

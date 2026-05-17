import SwiftData
import SwiftUI

struct DeckPreviewView: View {
    let deck: Deck

    @State private var index = 0
    @State private var zoom: CGFloat = 1
    @State private var presenting = false
    @State private var share: SharePayload?
    @State private var exporting = false

    private var slides: [Slide] { deck.orderedSlides }

    var body: some View {
        GeometryReader { geo in
            let available = geo.size.width - Spacing.lg * 2
            let canvas = SlideCanvas.size(forWidth: max(160, min(available, geo.size.height)))

            ZStack {
                Color.slydeeCream.ignoresSafeArea()

                VStack(spacing: Spacing.md) {
                    Spacer(minLength: 0)

                    TabView(selection: $index) {
                        ForEach(Array(slides.enumerated()), id: \.element.id) { offset, slide in
                            SlideCanvas(slide: slide, theme: deck.theme, size: canvas)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                        .strokeBorder(Color.slydeeHairline, lineWidth: 1)
                                )
                                .shadow(color: Color.slydeeInk.opacity(0.08), radius: 12, y: 6)
                                .scaleEffect(offset == index ? zoom : 1)
                                .gesture(zoomGesture)
                                .onTapGesture(count: 2) {
                                    withAnimation(.spring) { zoom = zoom > 1 ? 1 : 2 }
                                }
                                .tag(offset)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: canvas.height + Spacing.xl)

                    Spacer(minLength: 0)
                    bottomBar
                }
            }
        }
        .navigationTitle(deck.title.isEmpty ? "Deck" : deck.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $presenting) {
            PresentationModeView(deck: deck, startIndex: index)
        }
        .sheet(item: $share) { payload in
            ShareSheet(items: [payload.url])
        }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = min(4, max(1, value.magnification))
            }
            .onEnded { _ in
                if zoom < 1.05 { withAnimation { zoom = 1 } }
            }
    }

    private var bottomBar: some View {
        HStack(spacing: Spacing.lg) {
            Text("\(min(index + 1, slides.count)) / \(slides.count)")
                .font(SlydeeFont.emphasis(FontSize.callout))
                .foregroundStyle(Color.slydeeInk)
                .monospacedDigit()

            Spacer()

            Button {
                exportAndShare()
            } label: {
                if exporting {
                    ProgressView()
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .disabled(exporting)

            Button {
                presenting = true
            } label: {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 20, weight: .semibold))
            }
        }
        .foregroundStyle(Color.slydeeInk)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.slydeeSurface)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.slydeeHairline, lineWidth: 1))
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
    }

    private func exportAndShare() {
        exporting = true
        Task {
            defer { exporting = false }
            if let url = await PDFExporter.export(deck: deck) {
                share = SharePayload(url: url)
            }
        }
    }
}

/// Identifiable wrapper so the share sheet can be presented via `.sheet(item:)`.
struct SharePayload: Identifiable {
    let id = UUID()
    let url: URL
}

/// Distraction-free full-screen presentation. Tap anywhere to exit.
private struct PresentationModeView: View {
    let deck: Deck
    let startIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var index: Int

    init(deck: Deck, startIndex: Int) {
        self.deck = deck
        self.startIndex = startIndex
        _index = State(initialValue: startIndex)
    }

    var body: some View {
        GeometryReader { geo in
            let canvas = SlideCanvas.size(forWidth: geo.size.width)
            ZStack {
                Color.black.ignoresSafeArea()
                TabView(selection: $index) {
                    ForEach(Array(deck.orderedSlides.enumerated()), id: \.element.id) { offset, slide in
                        SlideCanvas(slide: slide, theme: deck.theme, size: canvas)
                            .frame(maxHeight: .infinity)
                            .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .contentShape(Rectangle())
            .onTapGesture { dismiss() }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}

#Preview {
    NavigationStack {
        DeckPreviewView(deck: Deck(title: "Preview Deck"))
    }
    .modelContainer(for: [Deck.self, Slide.self, Block.self], inMemory: true)
}

import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Deck.updatedAt, order: .reverse) private var decks: [Deck]

    @State private var searchText = ""
    @State private var renameTarget: Deck?
    @State private var renameText = ""
    @State private var share: SharePayload?
    @State private var exportingID: PersistentIdentifier?

    private let columns = [GridItem(.adaptive(minimum: 168), spacing: Spacing.md)]

    private var filtered: [Deck] {
        guard !searchText.isEmpty else { return decks }
        return decks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: Spacing.lg) {
                            ForEach(filtered) { deck in
                                NavigationLink(value: deck) {
                                    DeckCard(deck: deck)
                                }
                                .buttonStyle(.plain)
                                .contextMenu { menu(for: deck) }
                            }
                        }
                        .padding(Spacing.lg)
                    }
                    .searchable(text: $searchText, prompt: "Search decks")
                }
            }
            .background(Color.slydeeCream)
            .navigationTitle("Library")
            .navigationDestination(for: Deck.self) { DeckPreviewView(deck: $0) }
            .alert("Rename deck", isPresented: renameBinding) {
                TextField("Title", text: $renameText)
                Button("Cancel", role: .cancel) {}
                Button("Save") { commitRename() }
            }
            .sheet(item: $share) { ShareSheet(items: [$0.url]) }
        }
    }

    @ViewBuilder
    private func menu(for deck: Deck) -> some View {
        Button {
            renameText = deck.title
            renameTarget = deck
        } label: { Label("Rename", systemImage: "pencil") }

        Button {
            duplicate(deck)
        } label: { Label("Duplicate", systemImage: "doc.on.doc") }

        Button {
            export(deck) { await PDFExporter.export(deck: deck) }
        } label: { Label("Export PDF", systemImage: "doc.richtext") }

        Button {
            export(deck) { await PPTXExporter.export(deck: deck) }
        } label: { Label("Export PPTX", systemImage: "rectangle.on.rectangle") }

        Button(role: .destructive) {
            context.delete(deck)
            try? context.save()
        } label: { Label("Delete", systemImage: "trash") }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            MascotView(size: 96)
            Text("No decks yet")
                .font(SlydeeFont.heading(FontSize.heading))
                .foregroundStyle(Color.slydeeInk)
            Text("Create one from the Home tab.")
                .font(SlydeeFont.body(FontSize.callout))
                .foregroundStyle(Color.slydeeInkMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.slydeeCream)
    }

    private var renameBinding: Binding<Bool> {
        Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )
    }

    private func commitRename() {
        guard let deck = renameTarget else { return }
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            deck.title = trimmed
            deck.touch()
            try? context.save()
        }
        renameTarget = nil
    }

    private func duplicate(_ deck: Deck) {
        let copy = Deck(
            title: deck.title + " copy",
            language: deck.language,
            theme: deck.theme,
            originalInput: deck.originalInput
        )
        context.insert(copy)
        for slide in deck.orderedSlides {
            let newSlide = Slide(
                index: slide.index,
                layout: slide.layout,
                language: slide.language,
                transition: slide.transition,
                notes: slide.notes
            )
            newSlide.backgroundJSON = slide.backgroundJSON
            newSlide.deck = copy
            copy.addSlide(newSlide)
            context.insert(newSlide)

            for block in slide.orderedBlocks {
                guard let content = block.content else { continue }
                let newBlock = Block(
                    type: block.type,
                    frame: block.frame,
                    content: content,
                    zIndex: block.zIndex,
                    rotation: block.rotation,
                    opacity: block.opacity
                )
                newBlock.slide = newSlide
                newSlide.addBlock(newBlock)
                context.insert(newBlock)
            }
        }
        try? context.save()
    }

    private func export(_ deck: Deck, _ make: @escaping () async -> URL?) {
        exportingID = deck.persistentModelID
        Task {
            defer { exportingID = nil }
            if let url = await make() {
                share = SharePayload(url: url)
            }
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: [Deck.self, Slide.self, Block.self], inMemory: true)
}

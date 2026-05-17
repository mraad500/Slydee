import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Deck.updatedAt, order: .reverse) private var decks: [Deck]
    @Query(sort: \ResearchDocument.updatedAt, order: .reverse) private var research: [ResearchDocument]

    @State private var searchText = ""
    @State private var renameTarget: Deck?
    @State private var renameText = ""
    @State private var researchRenameTarget: ResearchDocument?
    @State private var researchRenameText = ""
    @State private var share: SharePayload?
    @State private var exportingID: PersistentIdentifier?

    private let columns = [GridItem(.adaptive(minimum: 168), spacing: Spacing.md)]

    private var filtered: [Deck] {
        guard !searchText.isEmpty else { return decks }
        return decks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredResearch: [ResearchDocument] {
        guard !searchText.isEmpty else { return research }
        return research.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.topic.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var isEmpty: Bool { decks.isEmpty && research.isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if isEmpty {
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
                            ForEach(filteredResearch) { document in
                                NavigationLink(value: document) {
                                    ResearchCard(document: document)
                                }
                                .buttonStyle(.plain)
                                .contextMenu { menu(forResearch: document) }
                            }
                        }
                        .padding(Spacing.lg)
                    }
                    .searchable(text: $searchText, prompt: "Search library")
                }
            }
            .background(Color.slydeeCream)
            .navigationTitle("Library")
            .navigationDestination(for: Deck.self) { DeckPreviewView(deck: $0) }
            .navigationDestination(for: ResearchDocument.self) { ResearchReaderView(document: $0) }
            .alert("Rename deck", isPresented: renameBinding) {
                TextField("Title", text: $renameText)
                Button("Cancel", role: .cancel) {}
                Button("Save") { commitRename() }
            }
            .alert("Rename research", isPresented: researchRenameBinding) {
                TextField("Title", text: $researchRenameText)
                Button("Cancel", role: .cancel) {}
                Button("Save") { commitResearchRename() }
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

    @ViewBuilder
    private func menu(forResearch document: ResearchDocument) -> some View {
        Button {
            researchRenameText = document.title
            researchRenameTarget = document
        } label: { Label("Rename", systemImage: "pencil") }

        Button {
            exportingID = document.persistentModelID
            Task {
                defer { exportingID = nil }
                if let url = await ResearchPDFExporter.export(document) {
                    share = SharePayload(url: url)
                }
            }
        } label: { Label("Export PDF", systemImage: "doc.richtext") }

        Button(role: .destructive) {
            context.delete(document)
            try? context.save()
        } label: { Label("Delete", systemImage: "trash") }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            MascotView(size: 96)
            Text("Nothing here yet")
                .font(SlydeeFont.heading(FontSize.heading))
                .foregroundStyle(Color.slydeeInk)
            Text("Make a presentation or research from the Home tab.")
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

    private var researchRenameBinding: Binding<Bool> {
        Binding(
            get: { researchRenameTarget != nil },
            set: { if !$0 { researchRenameTarget = nil } }
        )
    }

    private func commitResearchRename() {
        guard let document = researchRenameTarget else { return }
        let trimmed = researchRenameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            document.title = trimmed
            document.touch()
            try? context.save()
        }
        researchRenameTarget = nil
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
        .modelContainer(
            for: [Deck.self, Slide.self, Block.self, ResearchDocument.self],
            inMemory: true
        )
}

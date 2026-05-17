import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \Deck.updatedAt, order: .reverse) private var decks: [Deck]
    @State private var showCreate = false
    @State private var showResearch = false
    @State private var createTemplate: Template?

    private var recentDecks: [Deck] { Array(decks.prefix(10)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    entryTiles
                    recentSection
                    templatesSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.slydeeCream.ignoresSafeArea())
            .navigationTitle("Home")
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(for: Deck.self) { deck in
                DeckPreviewView(deck: deck)
            }
            .fullScreenCover(isPresented: $showCreate) {
                CreateView(preselectedTemplate: createTemplate)
            }
            .fullScreenCover(isPresented: $showResearch) {
                ResearchFlowView()
            }
        }
    }

    /// Two side-by-side glass entry tiles: presentations and research.
    private var entryTiles: some View {
        HStack(spacing: Spacing.md) {
            entryTile(
                title: "New Presentation",
                subtitle: "Slides in seconds",
                systemImage: "rectangle.on.rectangle.angled",
                tint: Color.slydeeSun
            ) {
                createTemplate = nil
                showCreate = true
            }
            entryTile(
                title: "New Research",
                subtitle: "Papers & reports",
                systemImage: "doc.text.magnifyingglass",
                tint: Color.slydeeInk
            ) {
                showResearch = true
            }
        }
    }

    private func entryTile(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(tint)
                Spacer(minLength: Spacing.sm)
                Text(title)
                    .font(SlydeeFont.heading(FontSize.callout))
                    .foregroundStyle(Color.slydeeInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(SlydeeFont.body(FontSize.caption))
                    .foregroundStyle(Color.slydeeInkMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .glassCard(padding: Spacing.md)
        }
        .buttonStyle(SpringButtonStyle())
    }

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            MascotView(size: 44)
            VStack(alignment: .leading, spacing: 0) {
                Text("Slydee")
                    .font(SlydeeFont.title(FontSize.title))
                    .foregroundStyle(Color.slydeeInk)
                Text("Beautiful slides in seconds.")
                    .font(SlydeeFont.body(FontSize.caption))
                    .foregroundStyle(Color.slydeeInkMuted)
            }
            Spacer()
        }
        .padding(.top, Spacing.lg)
    }

    @ViewBuilder
    private var recentSection: some View {
        if recentDecks.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                sectionTitle("Recent")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach(recentDecks) { deck in
                            NavigationLink(value: deck) {
                                DeckCard(deck: deck)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, Spacing.xxs)
                }
            }
        }
    }

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionTitle("Templates")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(TemplateCatalog.all) { template in
                        Button {
                            createTemplate = template
                            showCreate = true
                        } label: {
                            TemplatePreview(template: template)
                        }
                        .buttonStyle(SpringButtonStyle())
                    }
                }
                .padding(.vertical, Spacing.xxs)
            }
        }
    }

    private var emptyState: some View {
        Button {
            createTemplate = nil
            showCreate = true
        } label: {
            VStack(spacing: Spacing.md) {
                MascotView(size: 96)
                Text("Make your first deck →")
                    .font(SlydeeFont.heading(FontSize.heading))
                    .foregroundStyle(Color.slydeeInk)
                Text("A topic, a file, or an image — Slydee does the rest.")
                    .font(SlydeeFont.body(FontSize.callout))
                    .foregroundStyle(Color.slydeeInkMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xxl)
        }
        .buttonStyle(SpringButtonStyle())
    }

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(SlydeeFont.heading(FontSize.heading))
            .foregroundStyle(Color.slydeeInk)
    }
}

#Preview {
    HomeView()
        .modelContainer(
            for: [Deck.self, Slide.self, Block.self, ResearchDocument.self],
            inMemory: true
        )
}

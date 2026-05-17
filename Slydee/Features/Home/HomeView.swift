import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \Deck.updatedAt, order: .reverse) private var decks: [Deck]
    @State private var showCreate = false
    @State private var createTemplate: Template?

    private var recentDecks: [Deck] { Array(decks.prefix(10)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    newButton
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
        }
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

    private var newButton: some View {
        SlydeeButton("New Presentation", systemImage: "plus", fullWidth: true) {
            createTemplate = nil
            showCreate = true
        }
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
        .modelContainer(for: [Deck.self, Slide.self, Block.self], inMemory: true)
}

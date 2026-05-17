import SwiftUI

/// Setup screen: language, length, tone, topic. Glassmorphic cards on the
/// warm cream background.
struct ResearchConfigView: View {
    @Bindable var vm: ResearchConfigViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                topicCard
                languageCard
                lengthCard
                toneCard
            }
            .padding(Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Topic

    private var topicCard: some View {
        cardSection(title: "Research topic", systemImage: "text.book.closed") {
            TextEditor(text: $vm.topic)
                .font(SlydeeFont.body(FontSize.body))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 130)
                .padding(Spacing.sm)
                .background(Color.white.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(ResearchConfigViewModel.suggestedTopics, id: \.self) { topic in
                        Button {
                            vm.selectSuggestion(topic)
                        } label: {
                            Text(topic)
                                .font(SlydeeFont.body(FontSize.caption))
                                .foregroundStyle(Color.slydeeInk)
                                .padding(.vertical, Spacing.xs)
                                .padding(.horizontal, Spacing.sm)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.4)))
                        }
                        .buttonStyle(SpringButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: Language

    private var languageCard: some View {
        cardSection(title: "Language", systemImage: "character.bubble") {
            Picker("Language", selection: $vm.language) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.rawDisplayName).tag(lang)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: Length

    private var lengthCard: some View {
        cardSection(title: "Length", systemImage: "ruler") {
            Picker("Mode", selection: $vm.lengthMode) {
                ForEach(ResearchLengthMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Stepper(value: $vm.lengthValue,
                    in: vm.lengthMode.range,
                    step: vm.lengthMode.step) {
                Text(lengthLabel)
                    .font(SlydeeFont.emphasis(FontSize.body))
                    .foregroundStyle(Color.slydeeInk)
            }
        }
    }

    private var lengthLabel: String {
        switch vm.lengthMode {
        case .words: "\(vm.lengthValue) words"
        case .pages: "\(vm.lengthValue) page\(vm.lengthValue == 1 ? "" : "s")"
        }
    }

    // MARK: Tone

    private var toneCard: some View {
        cardSection(title: "Tone", systemImage: "slider.horizontal.3") {
            Picker("Tone", selection: $vm.tone) {
                ForEach(ResearchTone.allCases) { tone in
                    Text(tone.displayName).tag(tone)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: Reusable section card

    @ViewBuilder
    private func cardSection<Content: View>(
        title: LocalizedStringKey,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(title, systemImage: systemImage)
                .font(SlydeeFont.heading(FontSize.callout))
                .foregroundStyle(Color.slydeeInk)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

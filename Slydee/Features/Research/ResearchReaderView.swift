import SwiftUI
import UIKit

/// Clean reading view for a generated research document. Titles / subtitles /
/// paragraphs are styled per section, RTL-aware. Exports a formatted PDF or
/// copies plain text.
struct ResearchReaderView: View {
    let document: ResearchDocument

    @State private var share: SharePayload?
    @State private var exporting = false
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(document.sections) { section in
                    sectionView(section)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .glassCard()
            .padding(Spacing.lg)
        }
        .background(Color.slydeeCream.ignoresSafeArea())
        .navigationTitle(document.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        copy()
                    } label: {
                        Label(copied ? "Copied" : "Copy text",
                              systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                    Button {
                        exportPDF()
                    } label: {
                        Label("Export PDF", systemImage: "doc.richtext")
                    }
                } label: {
                    if exporting {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(item: $share) { ShareSheet(items: [$0.url]) }
    }

    // MARK: Section rendering

    @ViewBuilder
    private func sectionView(_ section: ResearchSection) -> some View {
        let isArabic = LanguageDetector.containsArabic(section.text)
        let lang: AppLanguage = isArabic ? .arabic : .english

        Group {
            switch section.style {
            case .title:
                Text(section.text)
                    .font(SlydeeFont.title(FontSize.display, lang: lang))
                    .foregroundStyle(Color.slydeeInk)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, Spacing.xs)
            case .heading:
                Text(section.text)
                    .font(SlydeeFont.heading(FontSize.heading, lang: lang))
                    .foregroundStyle(Color.slydeeInk)
                    .padding(.top, Spacing.sm)
            case .subheading:
                Text(section.text)
                    .font(SlydeeFont.emphasis(FontSize.body, lang: lang))
                    .foregroundStyle(Color.slydeeInk)
            case .body:
                Text(section.text)
                    .font(SlydeeFont.body(FontSize.body, lang: lang))
                    .foregroundStyle(Color.slydeeInk.opacity(0.85))
                    .lineSpacing(5)
            case .quote:
                Text(section.text)
                    .font(SlydeeFont.body(FontSize.body, lang: lang).italic())
                    .foregroundStyle(Color.slydeeInkMuted)
                    .padding(.leading, Spacing.md)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.slydeeSun)
                            .frame(width: 3)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
        .multilineTextAlignment(isArabic ? .trailing : .leading)
        .environment(\.layoutDirection, isArabic ? .rightToLeft : .leftToRight)
    }

    // MARK: Actions

    private func copy() {
        UIPasteboard.general.string = document.plainText
        withAnimation { copied = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { copied = false }
        }
    }

    private func exportPDF() {
        exporting = true
        Task {
            defer { exporting = false }
            if let url = await ResearchPDFExporter.export(document) {
                share = SharePayload(url: url)
            }
        }
    }
}

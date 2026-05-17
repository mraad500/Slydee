import SwiftUI

/// Library/Home tile for a research document. A "paper" aesthetic to read as
/// distinct from a presentation `DeckCard`.
struct ResearchCard: View {
    let document: ResearchDocument

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ZStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.7), Color.slydeeCream],
                    startPoint: .top,
                    endPoint: .bottom
                )
                VStack(alignment: .leading, spacing: 5) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.slydeeSun)
                    Text(document.displayTitle)
                        .font(SlydeeFont.heading(15, lang: document.language))
                        .foregroundStyle(Color.slydeeInk)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(Spacing.sm)
            }
            .frame(width: 168, height: 112)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .strokeBorder(Color.slydeeHairline, lineWidth: 1)
            )

            Text(document.displayTitle)
                .font(SlydeeFont.emphasis(FontSize.callout))
                .foregroundStyle(Color.slydeeInk)
                .lineLimit(1)
            Text("\(document.wordCount) words · \(document.updatedAt, format: .dateTime.day().month().year())")
                .font(SlydeeFont.body(FontSize.caption))
                .foregroundStyle(Color.slydeeInkMuted)
                .lineLimit(1)
        }
        .frame(width: 168)
    }
}

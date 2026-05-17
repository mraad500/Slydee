import SwiftUI

/// A recent-deck tile: themed thumbnail + title + updated date.
struct DeckCard: View {
    let deck: Deck

    private var displayTitle: String {
        deck.title.isEmpty ? "Untitled" : deck.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ZStack {
                deck.theme.background
                Text(displayTitle)
                    .font(SlydeeFont.heading(16, lang: deck.language))
                    .foregroundStyle(deck.theme.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(Spacing.sm)
            }
            .frame(width: 168, height: 112)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .strokeBorder(Color.slydeeHairline, lineWidth: 1)
            )

            Text(displayTitle)
                .font(SlydeeFont.emphasis(FontSize.callout))
                .foregroundStyle(Color.slydeeInk)
                .lineLimit(1)
            Text(deck.updatedAt, format: .dateTime.day().month().year())
                .font(SlydeeFont.body(FontSize.caption))
                .foregroundStyle(Color.slydeeInkMuted)
        }
        .frame(width: 168)
    }
}

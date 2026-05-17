import SwiftUI

/// Rounded elevated surface used for deck/template tiles and list rows.
struct SlydeeCard<Content: View>: View {
    var padding: CGFloat = Spacing.md
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(Color.slydeeSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(Color.slydeeHairline, lineWidth: 1)
            )
            .shadow(color: Color.slydeeInk.opacity(0.05), radius: 8, y: 4)
    }
}

extension View {
    /// Wraps the view in the standard card surface.
    func slydeeCard(padding: CGFloat = Spacing.md) -> some View {
        SlydeeCard(padding: padding) { self }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        Text("Recent deck")
            .font(SlydeeFont.heading(FontSize.heading))
            .slydeeCard()
    }
    .padding()
    .background(Color.slydeeCream)
}

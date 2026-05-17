import SwiftUI

/// Glassmorphic surface: translucent material over a warm cream tint, soft
/// shadow, hairline edge, continuous corners. Spatial-design friendly — sits
/// "above" the background rather than as a flat panel.
struct GlassCard<Content: View>: View {
    var padding: CGFloat = Spacing.lg
    var cornerRadius: CGFloat = Radius.lg
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.slydeeCream.opacity(0.55))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: Color.slydeeInk.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

extension View {
    /// Wraps the view in the standard glass surface.
    func glassCard(
        padding: CGFloat = Spacing.lg,
        cornerRadius: CGFloat = Radius.lg
    ) -> some View {
        GlassCard(padding: padding, cornerRadius: cornerRadius) { self }
    }
}

#Preview {
    ZStack {
        Color.slydeeCream.ignoresSafeArea()
        VStack(spacing: Spacing.lg) {
            Text("Glassmorphism")
                .font(SlydeeFont.heading(FontSize.heading))
                .foregroundStyle(Color.slydeeInk)
                .frame(maxWidth: .infinity)
                .glassCard()
        }
        .padding()
    }
}

import SwiftUI

/// First-run welcome (spec §7.1). One screen, on-brand, dismissible once.
/// Gated by `@AppStorage("hasOnboardedV1")` from `RootView`.
struct OnboardingView: View {
    var onStart: () -> Void

    var body: some View {
        ZStack {
            Color.slydeeCream.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                MascotView(size: 132)

                VStack(spacing: Spacing.sm) {
                    Text("Welcome to Slydee")
                        .font(SlydeeFont.title(FontSize.display))
                        .foregroundStyle(Color.slydeeInk)
                    Text("Beautiful slides in seconds.")
                        .font(SlydeeFont.body(FontSize.body))
                        .foregroundStyle(Color.slydeeInkMuted)
                }

                VStack(alignment: .leading, spacing: Spacing.md) {
                    featureRow("sparkles", "Turn a topic, file, or image into a deck")
                    featureRow("doc.text.magnifyingglass", "Write formatted research & reports")
                    featureRow("character.bubble", "Arabic, English, and Mixed — natively")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()

                Spacer()

                VStack(spacing: Spacing.sm) {
                    SlydeeButton("Get started", systemImage: "arrow.right", fullWidth: true) {
                        onStart()
                    }
                    Text("Tip: add a Claude or OpenAI key in Settings for Arabic.")
                        .font(SlydeeFont.body(FontSize.caption))
                        .foregroundStyle(Color.slydeeInkMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Spacing.xl)
        }
    }

    private func featureRow(_ symbol: String, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.slydeeSun)
                .frame(width: 28)
            Text(text)
                .font(SlydeeFont.body(FontSize.callout))
                .foregroundStyle(Color.slydeeInk)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    OnboardingView {}
}

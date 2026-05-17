import SwiftUI

enum SlydeeButtonKind {
    case primary // Sun yellow, ink text — main CTAs
    case secondary // Ink outline on cream
    case ghost // Text only
}

/// The app's standard button. Pill-shaped, springy press feedback.
struct SlydeeButton: View {
    let title: LocalizedStringKey
    var systemImage: String?
    var kind: SlydeeButtonKind = .primary
    var fullWidth: Bool = false
    let action: () -> Void

    init(
        _ title: LocalizedStringKey,
        systemImage: String? = nil,
        kind: SlydeeButtonKind = .primary,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.kind = kind
        self.fullWidth = fullWidth
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: FontSize.body, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: FontSize.body, weight: .semibold))
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.xl)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.slydeeInk, lineWidth: kind == .secondary ? 1.5 : 0)
            )
        }
        .buttonStyle(SpringButtonStyle())
    }

    private var foreground: Color {
        switch kind {
        case .primary: .slydeeInk
        case .secondary, .ghost: .slydeeInk
        }
    }

    private var background: Color {
        switch kind {
        case .primary: .slydeeSun
        case .secondary: .clear
        case .ghost: .clear
        }
    }
}

/// Subtle scale + opacity on press. Keeps interactions playful but quick.
struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        SlydeeButton("New Presentation", systemImage: "plus", fullWidth: true) {}
        SlydeeButton("Configure", kind: .secondary) {}
        SlydeeButton("Skip", kind: .ghost) {}
    }
    .padding()
    .background(Color.slydeeCream)
}

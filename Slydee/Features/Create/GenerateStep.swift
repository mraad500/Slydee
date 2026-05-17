import SwiftUI

struct GenerateStep: View {
    @Bindable var vm: CreateViewModel
    var onClose: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            if let error = vm.generationError {
                errorView(error)
            } else {
                progressView
            }

            Spacer()
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var progressView: some View {
        VStack(spacing: Spacing.lg) {
            MascotView(size: 120)
                .scaleEffect(pulse ? 1.06 : 0.94)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)
                .onAppear { pulse = true }

            Text(vm.statusText)
                .font(SlydeeFont.heading(FontSize.heading))
                .foregroundStyle(Color.slydeeInk)
                .contentTransition(.opacity)
                .animation(.easeInOut, value: vm.statusText)

            SlydeeButton("Cancel", kind: .secondary) {
                vm.cancelGeneration()
            }
            .padding(.top, Spacing.md)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.bubble")
                .font(.system(size: 56))
                .foregroundStyle(Color.slydeeInk)
            Text("Couldn't generate")
                .font(SlydeeFont.title(FontSize.title))
                .foregroundStyle(Color.slydeeInk)
            Text(message)
                .font(SlydeeFont.body(FontSize.body))
                .foregroundStyle(Color.slydeeInkMuted)
                .multilineTextAlignment(.center)

            VStack(spacing: Spacing.sm) {
                SlydeeButton("Try again") {
                    vm.generationError = nil
                    vm.step = .configure
                }
                SlydeeButton("Close", kind: .ghost, action: onClose)
            }
            .padding(.top, Spacing.md)
        }
    }
}

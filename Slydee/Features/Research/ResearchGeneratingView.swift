import SwiftUI

/// Sleek "the AI is writing" state: pulsing mascot, shimmering skeleton lines
/// that mimic text being written, status ticker, cancel.
struct ResearchGeneratingView: View {
    @Bindable var vm: ResearchConfigViewModel
    var onClose: () -> Void

    @State private var pulse = false
    @State private var shimmer = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            if let error = vm.generationError {
                errorView(error)
            } else {
                writingView
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
    }

    private var writingView: some View {
        VStack(spacing: Spacing.xl) {
            MascotView(size: 104)
                .scaleEffect(pulse ? 1.06 : 0.94)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)

            // Skeleton "page" being written.
            VStack(alignment: .leading, spacing: Spacing.sm) {
                skeletonLine(width: 0.5, tall: true)
                skeletonLine(width: 0.95)
                skeletonLine(width: 0.88)
                skeletonLine(width: 0.92)
                skeletonLine(width: 0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()

            Text(vm.statusText)
                .font(SlydeeFont.heading(FontSize.heading))
                .foregroundStyle(Color.slydeeInk)
                .contentTransition(.opacity)
                .animation(.easeInOut, value: vm.statusText)

            SlydeeButton("Cancel", kind: .secondary) {
                vm.cancelGeneration()
            }
        }
        .onAppear {
            pulse = true
            shimmer = true
        }
    }

    private func skeletonLine(width: CGFloat, tall: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Color.slydeeInk.opacity(0.10))
            .frame(height: tall ? 18 : 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color.slydeeSun.opacity(0.55), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.4)
                        .offset(x: shimmer ? geo.size.width : -geo.size.width * 0.4)
                        .animation(
                            .linear(duration: 1.4).repeatForever(autoreverses: false),
                            value: shimmer
                        )
                }
            }
            .frame(width: nil)
            .scaleEffect(x: width, anchor: .leading)
            .clipped()
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.bubble")
                .font(.system(size: 52))
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
                    vm.phase = .config
                }
                SlydeeButton("Close", kind: .ghost, action: onClose)
            }
        }
        .glassCard()
    }
}

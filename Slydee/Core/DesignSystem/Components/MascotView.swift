import SwiftUI

/// The Slydee mascot face (matches the app icon): two filled eyes, a small
/// hollow circle, and a smooth smile. Used in empty/loading/onboarding states.
struct MascotView: View {
    var size: CGFloat = 96
    var ink: Color = .slydeeInk

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let eyeR = w * 0.085

            // Eyes
            for cx in [w * 0.36, w * 0.64] {
                let rect = CGRect(
                    x: cx - eyeR, y: h * 0.38 - eyeR,
                    width: eyeR * 2, height: eyeR * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(ink))
            }

            // Small hollow circle (cheek dot)
            let dotR = w * 0.045
            let dotRect = CGRect(
                x: w * 0.80 - dotR, y: h * 0.30 - dotR,
                width: dotR * 2, height: dotR * 2
            )
            context.stroke(
                Path(ellipseIn: dotRect),
                with: .color(ink),
                lineWidth: max(1.5, w * 0.02)
            )

            // Smooth smile
            var smile = Path()
            smile.move(to: CGPoint(x: w * 0.32, y: h * 0.60))
            smile.addQuadCurve(
                to: CGPoint(x: w * 0.68, y: h * 0.60),
                control: CGPoint(x: w * 0.50, y: h * 0.80)
            )
            context.stroke(
                smile,
                with: .color(ink),
                style: StrokeStyle(lineWidth: max(2, w * 0.03), lineCap: .round)
            )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 24) {
        MascotView(size: 120)
        MascotView(size: 64, ink: .slydeeSun)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.slydeeCream)
}

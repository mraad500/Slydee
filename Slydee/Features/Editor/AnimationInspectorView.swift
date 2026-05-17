import SwiftUI

/// Sets a selected block's entrance animation. Preview plays on the canvas
/// (present mode) and via the live toggle here.
struct AnimationInspectorView: View {
    @Bindable var model: EditorViewModel
    let block: Block
    @Environment(\.dismiss) private var dismiss

    private var current: BlockAnimation {
        block.animation ?? BlockAnimation(kind: .none)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Entrance") {
                    Picker("Style", selection: kindBinding) {
                        ForEach(BlockAnimation.Kind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    if current.kind == .slide {
                        Picker("From", selection: edgeBinding) {
                            ForEach(BlockAnimation.Edge.allCases) { edge in
                                Text(edge.label).tag(edge)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                if current.kind != .none {
                    Section("Timing") {
                        labeledSlider("Duration", current.duration, "s", durationBinding, 0.2...1.5)
                        labeledSlider("Delay", current.delay, "s", delayBinding, 0...2)
                    }
                }
            }
            .navigationTitle("Animation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func labeledSlider(
        _ title: String,
        _ value: Double,
        _ unit: String,
        _ binding: Binding<Double>,
        _ range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading) {
            Text("\(title): \(value, specifier: "%.1f")\(unit)")
                .font(SlydeeFont.body(FontSize.caption))
                .foregroundStyle(Color.slydeeInkMuted)
            Slider(value: binding, in: range)
        }
    }

    private func mutate(_ transform: (inout BlockAnimation) -> Void) {
        var anim = block.animation ?? BlockAnimation()
        transform(&anim)
        model.setAnimation(anim.kind == .none ? nil : anim, for: block)
    }

    private var kindBinding: Binding<BlockAnimation.Kind> {
        Binding(get: { current.kind }, set: { value in mutate { $0.kind = value } })
    }
    private var edgeBinding: Binding<BlockAnimation.Edge> {
        Binding(get: { current.edge }, set: { value in mutate { $0.edge = value } })
    }
    private var durationBinding: Binding<Double> {
        Binding(get: { current.duration }, set: { value in mutate { $0.duration = value } })
    }
    private var delayBinding: Binding<Double> {
        Binding(get: { current.delay }, set: { value in mutate { $0.delay = value } })
    }
}

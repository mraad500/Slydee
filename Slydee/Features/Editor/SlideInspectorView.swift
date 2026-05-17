import SwiftUI

/// Slide-level inspector: background, transition, speaker notes.
struct SlideInspectorView: View {
    @Bindable var model: EditorViewModel
    let slide: Slide
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Background") {
                    Picker("Style", selection: modeBinding) {
                        Text("Theme").tag("theme")
                        Text("Solid").tag("solid")
                        Text("Gradient").tag("gradient")
                    }
                    .pickerStyle(.segmented)

                    switch slide.background {
                    case .solid:
                        ColorPicker("Color", selection: solidBinding, supportsOpacity: false)
                    case .gradient:
                        ColorPicker("Start", selection: gradientBinding(0), supportsOpacity: false)
                        ColorPicker("End", selection: gradientBinding(1), supportsOpacity: false)
                    case .theme:
                        Text("Uses the deck theme.")
                            .font(SlydeeFont.body(FontSize.caption))
                            .foregroundStyle(Color.slydeeInkMuted)
                    }
                }

                Section("Transition") {
                    Picker("Transition", selection: transitionBinding) {
                        ForEach(TransitionType.allCases, id: \.self) { t in
                            Text(t.rawValue.capitalized).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Speaker notes") {
                    TextEditor(text: notesBinding)
                        .frame(minHeight: 120)
                        .font(SlydeeFont.body(FontSize.body))
                }
            }
            .navigationTitle("Slide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var modeBinding: Binding<String> {
        Binding(
            get: {
                switch slide.background {
                case .theme: "theme"
                case .solid: "solid"
                case .gradient: "gradient"
                }
            },
            set: { value in
                switch value {
                case "solid": model.setBackground(.solid(hex: "FFFFFF"))
                case "gradient": model.setBackground(.gradient(hexes: ["A5D8FF", "C8B6FF"]))
                default: model.setBackground(.theme)
                }
            }
        )
    }

    private var solidBinding: Binding<Color> {
        Binding(
            get: {
                if case let .solid(hex) = slide.background { return Color(hex: hex) }
                return .white
            },
            set: { model.setBackground(.solid(hex: $0.hexString)) }
        )
    }

    private func gradientBinding(_ index: Int) -> Binding<Color> {
        Binding(
            get: {
                if case let .gradient(hexes) = slide.background,
                   hexes.indices.contains(index) {
                    return Color(hex: hexes[index])
                }
                return index == 0 ? .slydeeSky : .slydeeLavender
            },
            set: { newColor in
                var hexes: [String]
                if case let .gradient(existing) = slide.background, existing.count >= 2 {
                    hexes = existing
                } else {
                    hexes = ["A5D8FF", "C8B6FF"]
                }
                hexes[index] = newColor.hexString
                model.setBackground(.gradient(hexes: hexes))
            }
        )
    }

    private var transitionBinding: Binding<TransitionType> {
        Binding(
            get: { slide.transition },
            set: { model.setTransition($0) }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { slide.notes },
            set: { model.setNotes($0) }
        )
    }
}

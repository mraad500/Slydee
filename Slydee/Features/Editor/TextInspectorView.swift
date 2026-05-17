import SwiftUI

/// Bottom sheet for editing a selected text block: content, size, weight,
/// alignment, color, language.
struct TextInspectorView: View {
    @Bindable var model: EditorViewModel
    let block: Block
    @Environment(\.dismiss) private var dismiss

    private var text: TextContent? { block.content?.asText }

    var body: some View {
        NavigationStack {
            Form {
                Section("Text") {
                    TextEditor(text: contentBinding)
                        .frame(minHeight: 90)
                        .font(SlydeeFont.body(FontSize.body))
                }

                Section("Style") {
                    VStack(alignment: .leading) {
                        Text("Size \(Int(text?.size ?? 24))")
                            .font(SlydeeFont.body(FontSize.caption))
                            .foregroundStyle(Color.slydeeInkMuted)
                        Slider(value: sizeBinding, in: 12...120, step: 1)
                    }
                    Picker("Weight", selection: weightBinding) {
                        ForEach(SlydeeFontWeight.allCases, id: \.self) { w in
                            Text(w.rawValue.capitalized).tag(w)
                        }
                    }
                    Picker("Alignment", selection: alignBinding) {
                        Image(systemName: "text.alignleft").tag(TextAlign.leading)
                        Image(systemName: "text.aligncenter").tag(TextAlign.center)
                        Image(systemName: "text.alignright").tag(TextAlign.trailing)
                    }
                    .pickerStyle(.segmented)
                    Picker("Language", selection: langBinding) {
                        Text("English").tag(AppLanguage.english)
                        Text("العربية").tag(AppLanguage.arabic)
                    }
                    .pickerStyle(.segmented)
                    ColorPicker("Color", selection: colorBinding, supportsOpacity: false)
                }

                Section("Block") {
                    VStack(alignment: .leading) {
                        Text("Opacity \(Int(block.opacity * 100))%")
                            .font(SlydeeFont.body(FontSize.caption))
                            .foregroundStyle(Color.slydeeInkMuted)
                        Slider(
                            value: Binding(
                                get: { block.opacity },
                                set: { model.setOpacity($0, for: block) }
                            ),
                            in: 0.1...1
                        )
                    }
                }
            }
            .navigationTitle("Edit text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: Bindings

    private var contentBinding: Binding<String> {
        Binding(
            get: { text?.text ?? "" },
            set: { value in model.updateText(block) { $0.text = value } }
        )
    }

    private var sizeBinding: Binding<Double> {
        Binding(
            get: { text?.size ?? 24 },
            set: { value in model.updateText(block) { $0.size = value } }
        )
    }

    private var weightBinding: Binding<SlydeeFontWeight> {
        Binding(
            get: { text?.weight ?? .regular },
            set: { value in model.updateText(block) { $0.weight = value } }
        )
    }

    private var alignBinding: Binding<TextAlign> {
        Binding(
            get: { text?.align ?? .leading },
            set: { value in model.updateText(block) { $0.align = value } }
        )
    }

    private var langBinding: Binding<AppLanguage> {
        Binding(
            get: { text?.language ?? .english },
            set: { value in model.updateText(block) { $0.language = value } }
        )
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: text?.colorHex ?? "0F0F0F") },
            set: { value in model.updateText(block) { $0.colorHex = value.hexString } }
        )
    }
}

import SwiftUI

/// Edits a chart block: type + data rows.
struct ChartInspectorView: View {
    @Bindable var model: EditorViewModel
    let block: Block
    @Environment(\.dismiss) private var dismiss

    private var chart: ChartContent? {
        if case let .chart(value)? = block.content { return value }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: kindBinding) {
                        Text("Bar").tag("bar")
                        Text("Line").tag("line")
                        Text("Pie").tag("pie")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Data") {
                    let count = chart?.labels.count ?? 0
                    ForEach(0..<count, id: \.self) { index in
                        HStack {
                            TextField("Label", text: labelBinding(index))
                                .textInputAutocapitalization(.words)
                            Divider()
                            TextField("Value", value: valueBinding(index), format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets.sorted(by: >) { removeRow(index) }
                    }
                    Button {
                        model.updateChart(block) {
                            $0.labels.append("New")
                            $0.values.append(0)
                        }
                    } label: {
                        Label("Add row", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Edit chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func removeRow(_ index: Int) {
        model.updateChart(block) {
            guard $0.labels.indices.contains(index) else { return }
            $0.labels.remove(at: index)
            $0.values.remove(at: index)
        }
    }

    private var kindBinding: Binding<String> {
        Binding(
            get: { chart?.kind ?? "bar" },
            set: { value in model.updateChart(block) { $0.kind = value } }
        )
    }

    private func labelBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { chart?.labels[safe: index] ?? "" },
            set: { value in
                model.updateChart(block) {
                    if $0.labels.indices.contains(index) { $0.labels[index] = value }
                }
            }
        )
    }

    private func valueBinding(_ index: Int) -> Binding<Double> {
        Binding(
            get: { chart?.values[safe: index] ?? 0 },
            set: { value in
                model.updateChart(block) {
                    if $0.values.indices.contains(index) { $0.values[index] = value }
                }
            }
        )
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

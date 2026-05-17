import SwiftData
import SwiftUI

/// Entry container for the research flow. Mirrors `CreateView`: config →
/// generating → result (pushed reader). Presented from Home as a full-screen
/// cover.
struct ResearchFlowView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var vm = ResearchConfigViewModel()

    var body: some View {
        @Bindable var vm = vm
        NavigationStack {
            ZStack {
                Color.slydeeCream.ignoresSafeArea()
                switch vm.phase {
                case .config:
                    ResearchConfigView(vm: vm)
                case .generating:
                    ResearchGeneratingView(vm: vm, onClose: { dismiss() })
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .navigationDestination(item: $vm.resultDocument) { document in
                ResearchReaderView(document: document)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { dismiss() }
                                .fontWeight(.semibold)
                        }
                    }
            }
        }
    }

    private var navTitle: LocalizedStringKey {
        switch vm.phase {
        case .config: "New Research"
        case .generating: "Writing"
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        switch vm.phase {
        case .config:
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Generate") { vm.generate(context: context) }
                    .fontWeight(.semibold)
                    .disabled(!vm.canGenerate)
            }
        case .generating:
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
                    .opacity(vm.generationError == nil ? 0 : 1)
            }
        }
    }
}

#Preview {
    ResearchFlowView()
        .modelContainer(for: [ResearchDocument.self], inMemory: true)
}

import SwiftData
import SwiftUI

struct CreateView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var vm: CreateViewModel

    init(preselectedTemplate: Template?) {
        _vm = State(initialValue: CreateViewModel(template: preselectedTemplate))
    }

    var body: some View {
        @Bindable var vm = vm
        NavigationStack {
            ZStack {
                Color.slydeeCream.ignoresSafeArea()
                Group {
                    switch vm.step {
                    case .input:
                        InputStep(vm: vm)
                    case .configure:
                        ConfigureStep(vm: vm)
                    case .generating:
                        GenerateStep(vm: vm, onClose: { dismiss() })
                    }
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .navigationDestination(item: $vm.resultDeck) { deck in
                DeckPreviewView(deck: deck)
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
        switch vm.step {
        case .input: "New Presentation"
        case .configure: "Configure"
        case .generating: "Generating"
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        switch vm.step {
        case .input:
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Next") { vm.goToConfigure() }
                    .fontWeight(.semibold)
                    .disabled(!vm.canContinueFromInput)
            }
        case .configure:
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") { vm.step = .input }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Generate") { vm.generate(context: context) }
                    .fontWeight(.semibold)
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
    CreateView(preselectedTemplate: nil)
        .modelContainer(for: [Deck.self, Slide.self, Block.self], inMemory: true)
}

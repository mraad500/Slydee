import Foundation
import SwiftData

/// Builds the app's `ModelContainer`. Tries CloudKit-backed storage (iCloud
/// sync across devices); if iCloud isn't provisioned/available, degrades to
/// local storage so the app always launches. The models are already
/// CloudKit-safe (all properties have defaults, relationships optional).
@MainActor
enum SlydeePersistence {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([Deck.self, Slide.self, Block.self, ResearchDocument.self])

        let cloud = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        if let container = try? ModelContainer(for: schema, configurations: [cloud]) {
            enableUndo(container)
            return container
        }

        let local = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: schema, configurations: [local]) {
            enableUndo(container)
            return container
        }

        // Last resort: in-memory (never crash on launch).
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: schema, configurations: [memory])
        enableUndo(container)
        return container
    }

    private static func enableUndo(_ container: ModelContainer) {
        container.mainContext.undoManager = UndoManager()
    }
}

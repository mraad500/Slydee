import SwiftData
import SwiftUI

@main
struct SlydeeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Deck.self, Slide.self, Block.self], isUndoEnabled: true)
    }
}

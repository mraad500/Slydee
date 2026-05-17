import SwiftData
import SwiftUI

@main
struct SlydeeApp: App {
    @State private var container = SlydeePersistence.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

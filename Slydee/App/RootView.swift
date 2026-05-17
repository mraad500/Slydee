import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage("settings.uiLanguage") private var uiLanguageRaw = UILanguage.system.rawValue
    @AppStorage("hasOnboardedV1") private var hasOnboarded = false
    @State private var showOnboarding = false

    private var uiLanguage: UILanguage {
        UILanguage(rawValue: uiLanguageRaw) ?? .system
    }

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                HomeView()
            }
            Tab("Library", systemImage: "square.grid.2x2.fill") {
                LibraryView()
            }
            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .tint(.slydeeInk)
        .modifier(LocalePreference(language: uiLanguage))
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                hasOnboarded = true
                showOnboarding = false
            }
        }
        .onAppear { showOnboarding = !hasOnboarded }
    }
}

/// Applies the chosen UI language's locale + layout direction. `.system`
/// leaves the environment untouched.
private struct LocalePreference: ViewModifier {
    let language: UILanguage

    func body(content: Content) -> some View {
        if let locale = language.locale {
            content
                .environment(\.locale, locale)
                .environment(
                    \.layoutDirection,
                    language == .arabic ? .rightToLeft : .leftToRight
                )
        } else {
            content
        }
    }
}

#Preview {
    RootView()
        .modelContainer(
            for: [Deck.self, Slide.self, Block.self, ResearchDocument.self],
            inMemory: true
        )
}

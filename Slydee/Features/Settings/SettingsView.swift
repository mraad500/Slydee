import SwiftUI

struct SettingsView: View {
    @State private var vm = SettingsViewModel()
    @AppStorage("settings.uiLanguage") private var uiLanguageRaw = UILanguage.system.rawValue
    @AppStorage("settings.generator") private var generatorRaw = GeneratorPreference.auto.rawValue

    var body: some View {
        NavigationStack {
            Form {
                generationSection
                appearanceSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.slydeeCream)
            .navigationTitle("Settings")
        }
        .onAppear { vm.load() }
    }

    // MARK: Generation

    private var generationSection: some View {
        Section {
            Picker("Default generator", selection: $generatorRaw) {
                ForEach(GeneratorPreference.allCases) { pref in
                    Text(pref.displayName).tag(pref.rawValue)
                }
            }
            apiKeyRow(
                title: "Claude API key",
                text: $vm.claudeKey,
                state: vm.claudeState,
                onSave: { vm.save(.claude) },
                onTest: { vm.test(.claude) },
                onClear: { vm.clear(.claude) }
            )
            apiKeyRow(
                title: "OpenAI API key",
                text: $vm.openAIKey,
                state: vm.openAIState,
                onSave: { vm.save(.openAI) },
                onTest: { vm.test(.openAI) },
                onClear: { vm.clear(.openAI) }
            )
        } header: {
            Text("Generation")
        } footer: {
            Text("English decks generate free and private on-device. Arabic and Mixed use Claude (or OpenAI). Keys are stored in the Keychain.")
        }
    }

    @ViewBuilder
    private func apiKeyRow(
        title: LocalizedStringKey,
        text: Binding<String>,
        state: SettingsViewModel.KeyState,
        onSave: @escaping () -> Void,
        onTest: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(SlydeeFont.emphasis(FontSize.callout))
            SecureField("sk-…", text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(SlydeeFont.mono(FontSize.callout))
            HStack(spacing: Spacing.md) {
                Button("Save", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .tint(.slydeeSun)
                    .foregroundStyle(Color.slydeeInk)
                Button("Test", action: onTest)
                Spacer()
                Button("Clear", role: .destructive, action: onClear)
                statusIcon(state)
            }
            .font(SlydeeFont.body(FontSize.callout))
        }
        .padding(.vertical, Spacing.xxs)
    }

    @ViewBuilder
    private func statusIcon(_ state: SettingsViewModel.KeyState) -> some View {
        switch state {
        case .idle:
            EmptyView()
        case .testing:
            ProgressView()
        case .valid:
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(Color.slydeeMint)
        case let .invalid(message):
            Image(systemName: "xmark.seal.fill")
                .foregroundStyle(Color.slydeePeach)
                .help(message)
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("App language", selection: $uiLanguageRaw) {
                ForEach(UILanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang.rawValue)
                }
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: AppSettings.appVersion)
            LabeledContent("Made by", value: "Mohammed Raad (Hamoudi)")
            Text("Slydee — beautiful slides in seconds.")
                .font(SlydeeFont.body(FontSize.caption))
                .foregroundStyle(Color.slydeeInkMuted)
        }
    }
}

#Preview {
    SettingsView()
}

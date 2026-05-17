import SwiftUI

struct ConfigureStep: View {
    @Bindable var vm: CreateViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                languageSection
                slideCountSection
                templateSection
                toneSection
            }
            .padding(Spacing.lg)
        }
    }

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(SlydeeFont.heading(FontSize.heading))
            .foregroundStyle(Color.slydeeInk)
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionTitle("Language")
            Picker("Language", selection: $vm.language) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.rawDisplayName).tag(lang)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var slideCountSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionTitle("Slides")
            HStack {
                Stepper(value: $vm.slideCount, in: 3...20) {
                    Text("\(vm.slideCount) slides")
                        .font(SlydeeFont.body(FontSize.body))
                        .foregroundStyle(Color.slydeeInk)
                }
            }
            .padding(Spacing.sm)
            .background(Color.slydeeSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
        }
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionTitle("Template")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(TemplateCatalog.all) { template in
                        Button {
                            vm.selectedTemplate = template
                        } label: {
                            VStack(spacing: Spacing.xs) {
                                TemplatePreview(
                                    template: template,
                                    selected: vm.selectedTemplate.id == template.id
                                )
                                Text(template.name)
                                    .font(SlydeeFont.body(FontSize.caption))
                                    .foregroundStyle(Color.slydeeInk)
                            }
                        }
                        .buttonStyle(SpringButtonStyle())
                    }
                }
                .padding(.vertical, Spacing.xxs)
            }
        }
    }

    private var toneSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionTitle("Tone")
            Picker("Tone", selection: $vm.tone) {
                ForEach(Tone.allCases) { tone in
                    Text(tone.displayName).tag(tone)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

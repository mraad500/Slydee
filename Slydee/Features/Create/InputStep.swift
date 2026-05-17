import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct InputStep: View {
    @Bindable var vm: CreateViewModel
    @State private var showFileImporter = false
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                modeSelector

                switch vm.inputMode {
                case .topic: topicInput
                case .file: fileInput
                case .image: imageInput
                case .search: SearchInputView(vm: vm)
                }

                if let error = vm.inputError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(SlydeeFont.body(FontSize.callout))
                        .foregroundStyle(Color.slydeeInk)
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.slydeeWarning.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                }
            }
            .padding(Spacing.lg)
        }
    }

    private var modeSelector: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(CreateViewModel.InputMode.allCases) { mode in
                let selected = vm.inputMode == mode
                Button {
                    vm.inputMode = mode
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(mode.label)
                            .font(SlydeeFont.body(FontSize.caption))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .foregroundStyle(selected ? Color.slydeeInk : Color.slydeeInkMuted)
                    .background(selected ? Color.slydeeSun : Color.slydeeSurface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .strokeBorder(Color.slydeeHairline, lineWidth: 1)
                    )
                }
                .buttonStyle(SpringButtonStyle())
                .disabled(!mode.isEnabled)
                .opacity(mode.isEnabled ? 1 : 0.4)
            }
        }
    }

    private var topicInput: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("What's your presentation about?")
                .font(SlydeeFont.heading(FontSize.heading))
                .foregroundStyle(Color.slydeeInk)

            TextEditor(text: $vm.topicText)
                .font(SlydeeFont.body(FontSize.body))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 150)
                .padding(Spacing.sm)
                .background(Color.slydeeSurface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .strokeBorder(Color.slydeeHairline, lineWidth: 1)
                )

            Text("\(vm.topicText.count) characters")
                .font(SlydeeFont.body(FontSize.caption))
                .foregroundStyle(Color.slydeeInkMuted)

            Text("Try one of these")
                .font(SlydeeFont.emphasis(FontSize.callout))
                .foregroundStyle(Color.slydeeInk)
                .padding(.top, Spacing.xs)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(CreateViewModel.suggestedTopics, id: \.self) { topic in
                        Button {
                            vm.selectSuggestion(topic)
                        } label: {
                            Text(topic)
                                .font(SlydeeFont.body(FontSize.callout))
                                .foregroundStyle(Color.slydeeInk)
                                .padding(.vertical, Spacing.xs)
                                .padding(.horizontal, Spacing.sm)
                                .background(Color.slydeeSurface)
                                .clipShape(Capsule())
                                .overlay(Capsule().strokeBorder(Color.slydeeHairline))
                        }
                        .buttonStyle(SpringButtonStyle())
                    }
                }
            }
        }
    }

    private var fileInput: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SlydeeButton("Choose a file", systemImage: "doc.badge.plus", kind: .secondary) {
                showFileImporter = true
            }
            Text("PDF or text files.")
                .font(SlydeeFont.body(FontSize.caption))
                .foregroundStyle(Color.slydeeInkMuted)
            extractedPreview
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            if case let .success(urls) = result, let url = urls.first {
                vm.importFile(url)
            }
        }
    }

    private var imageInput: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Choose an image", systemImage: "photo.badge.plus")
                    .font(SlydeeFont.emphasis(FontSize.body))
                    .foregroundStyle(Color.slydeeInk)
                    .padding(.vertical, Spacing.md)
                    .padding(.horizontal, Spacing.xl)
                    .overlay(Capsule().strokeBorder(Color.slydeeInk, lineWidth: 1.5))
            }
            Text("We'll read the text from your image (Arabic + English).")
                .font(SlydeeFont.body(FontSize.caption))
                .foregroundStyle(Color.slydeeInkMuted)
            extractedPreview
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    vm.recognizeImage(data)
                }
            }
        }
    }

    @ViewBuilder
    private var extractedPreview: some View {
        if vm.isExtracting {
            HStack(spacing: Spacing.xs) {
                ProgressView()
                Text("Reading…")
                    .font(SlydeeFont.body(FontSize.callout))
                    .foregroundStyle(Color.slydeeInkMuted)
            }
        } else if !vm.importedText.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label(vm.importedLabel, systemImage: "checkmark.circle.fill")
                    .font(SlydeeFont.emphasis(FontSize.callout))
                    .foregroundStyle(Color.slydeeInk)
                Text(String(vm.importedText.prefix(500)))
                    .font(SlydeeFont.body(FontSize.callout))
                    .foregroundStyle(Color.slydeeInkMuted)
                    .lineLimit(6)
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.slydeeSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
        }
    }

}

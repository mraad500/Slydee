import SwiftUI

/// Web search input (Phase 3): query Google, pick results, use them as the
/// generation source with citations.
struct SearchInputView: View {
    @Bindable var vm: CreateViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                TextField("Search the web", text: $vm.searchQuery)
                    .textFieldStyle(.plain)
                    .padding(Spacing.sm)
                    .background(Color.slydeeSurface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .strokeBorder(Color.slydeeHairline, lineWidth: 1)
                    )
                    .onSubmit { vm.runSearch() }
                Button {
                    vm.runSearch()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.slydeeInk)
                        .padding(Spacing.sm)
                        .background(Color.slydeeSun)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                }
                .buttonStyle(SpringButtonStyle())
            }

            if vm.isSearching {
                HStack(spacing: Spacing.xs) {
                    ProgressView()
                    Text("Searching…")
                        .font(SlydeeFont.body(FontSize.callout))
                        .foregroundStyle(Color.slydeeInkMuted)
                }
            }

            if let error = vm.searchError {
                Text(error)
                    .font(SlydeeFont.body(FontSize.callout))
                    .foregroundStyle(Color.slydeeInk)
                    .padding(Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.slydeeWarning.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            }

            if !vm.searchResults.isEmpty {
                Text("Tap to include as a source")
                    .font(SlydeeFont.body(FontSize.caption))
                    .foregroundStyle(Color.slydeeInkMuted)

                ForEach(vm.searchResults) { result in
                    let selected = vm.selectedResultIDs.contains(result.id)
                    Button {
                        vm.toggleResult(result)
                    } label: {
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selected ? Color.slydeeInk : Color.slydeeInkMuted)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title)
                                    .font(SlydeeFont.emphasis(FontSize.callout))
                                    .foregroundStyle(Color.slydeeInk)
                                    .lineLimit(2)
                                Text(result.snippet)
                                    .font(SlydeeFont.body(FontSize.caption))
                                    .foregroundStyle(Color.slydeeInkMuted)
                                    .lineLimit(3)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(Spacing.sm)
                        .background(Color.slydeeSurface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                                .strokeBorder(
                                    selected ? Color.slydeeInk : Color.slydeeHairline,
                                    lineWidth: selected ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                if vm.hasSelectedResults {
                    Text("\(vm.selectedResultIDs.count) selected — continue with Next")
                        .font(SlydeeFont.body(FontSize.caption))
                        .foregroundStyle(Color.slydeeInkMuted)
                }
            }
        }
    }
}

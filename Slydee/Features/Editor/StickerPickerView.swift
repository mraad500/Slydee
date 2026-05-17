import SwiftUI

/// Searchable, categorized sticker library. Calls `onPick` with an SF Symbol.
struct StickerPickerView: View {
    var onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private let columns = [GridItem(.adaptive(minimum: 60), spacing: Spacing.md)]

    private func symbols(_ category: StickerCatalog.Category) -> [String] {
        guard !search.isEmpty else { return category.symbols }
        return category.symbols.filter { $0.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    ForEach(StickerCatalog.categories) { category in
                        let items = symbols(category)
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text(category.name)
                                    .font(SlydeeFont.heading(FontSize.callout))
                                    .foregroundStyle(Color.slydeeInk)
                                LazyVGrid(columns: columns, spacing: Spacing.md) {
                                    ForEach(items, id: \.self) { symbol in
                                        Button {
                                            onPick(symbol)
                                            dismiss()
                                        } label: {
                                            Image(systemName: symbol)
                                                .font(.system(size: 26))
                                                .foregroundStyle(Color.slydeeInk)
                                                .frame(width: 56, height: 56)
                                                .background(Color.slydeeSurface)
                                                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: Radius.sm)
                                                        .strokeBorder(Color.slydeeHairline)
                                                )
                                        }
                                        .buttonStyle(SpringButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.slydeeCream)
            .searchable(text: $search, prompt: "Search stickers")
            .navigationTitle("Stickers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

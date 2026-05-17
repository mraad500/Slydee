import SwiftUI

/// A miniature slide swatch used in the Home/Create template pickers.
struct TemplatePreview: View {
    let template: Template
    var size = CGSize(width: 150, height: 104)
    var selected = false

    var body: some View {
        let theme = template.theme
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(theme.accent)
                .frame(width: size.width * 0.52, height: 9)
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.primaryText.opacity(0.45))
                .frame(width: size.width * 0.72, height: 5)
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.primaryText.opacity(0.45))
                .frame(width: size.width * 0.6, height: 5)
            Spacer(minLength: 0)
            HStack {
                Spacer()
                Circle().fill(theme.accent).frame(width: 12, height: 12)
            }
        }
        .padding(12)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .background(theme.background)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .strokeBorder(
                    selected ? Color.slydeeInk : Color.slydeeHairline,
                    lineWidth: selected ? 2.5 : 1
                )
        )
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: Spacing.md) {
            ForEach(TemplateCatalog.all) { TemplatePreview(template: $0) }
        }
        .padding()
    }
    .background(Color.slydeeCream)
}

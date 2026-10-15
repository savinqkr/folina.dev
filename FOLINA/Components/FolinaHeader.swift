import SwiftUI

struct FolinaHeader: View {
    let section: String

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image("HeaderLogo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .accessibilityHidden(true)
                Text("FOLINA").font(FolinaTheme.Typography.brand)
            }
            Spacer()
            Text(section)
                .font(FolinaTheme.Typography.caption)
                .foregroundStyle(FolinaTheme.Palette.secondary)
        }
        .foregroundStyle(FolinaTheme.Palette.ink)
        .padding(.horizontal, 28)
        .frame(minHeight: 64)
        .background(FolinaTheme.Palette.surface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FolinaTheme.Palette.border).frame(height: 1)
        }
    }
}

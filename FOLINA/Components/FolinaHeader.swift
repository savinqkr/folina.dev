import SwiftUI

struct FolinaHeader: View {
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image("HeaderLogo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .accessibilityHidden(true)
                Text("FOLINA").font(FolinaTheme.Typography.brand)
            }
            Spacer()
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

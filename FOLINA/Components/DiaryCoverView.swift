import SwiftUI

/// 실물 표지의 고정 비율을 유지하는 장식 컴포넌트. 화면 배치는 부모가 담당합니다.
struct DiaryCoverView: View {
    let diary: DiarySummary

    private var coverColor: Color {
        switch diary.cover.tone {
        case .sage: FolinaTheme.Palette.sage
        case .slateBlue: FolinaTheme.Palette.slateBlue
        case .rose: FolinaTheme.Palette.rose
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(FolinaTheme.Palette.paperEdge)
                .frame(width: 180, height: 269)
                .offset(x: 6, y: 9)
            RoundedRectangle(cornerRadius: 8)
                .fill(coverColor)
                .frame(width: 180, height: 269)
                .shadow(color: FolinaTheme.Palette.ink.opacity(0.16), radius: 12, x: 5, y: 12)

            bindingDecoration

            VStack(alignment: .leading, spacing: 8) {
                Text(diary.title)
                    .font(FolinaTheme.Typography.cover)
                    .foregroundStyle(FolinaTheme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("JOURNAL  2026")
                    .font(.system(size: 10))
                    .foregroundStyle(FolinaTheme.Palette.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(width: 129, alignment: .leading)
            .frame(minHeight: 86, alignment: .leading)
            .background(FolinaTheme.Palette.surface, in: RoundedRectangle(cornerRadius: 5))
            .offset(x: 30, y: 67)
        }
        .frame(width: 192, height: 287, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var bindingDecoration: some View {
        switch diary.cover.binding {
        case .ringBinder:
            binderRings
        case .hardcover, .softcover:
            RoundedRectangle(cornerRadius: 3)
                .fill(diary.cover.binding == .hardcover
                      ? FolinaTheme.Palette.spine : FolinaTheme.Palette.softSpine)
                .frame(width: 13, height: 269)
                .overlay(alignment: .trailing) {
                    Rectangle().fill(FolinaTheme.Palette.surface.opacity(0.8))
                        .frame(width: 2).padding(.vertical, 3)
                }
        }
    }

    private var binderRings: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(FolinaTheme.Palette.steel)
                .frame(width: 17, height: 249)
                .offset(x: 5, y: 10)
            ForEach(0..<7, id: \.self) { index in
                ZStack(alignment: .topLeading) {
                    Ellipse()
                        .fill(FolinaTheme.Palette.steel)
                        .frame(width: 25, height: 11)
                    Ellipse()
                        .fill(FolinaTheme.Palette.collection)
                        .frame(width: 21, height: 5)
                        .offset(x: 2, y: 2)
                }
                .offset(x: -6, y: 31 + CGFloat(index) * 34.5)
            }
        }
    }
}

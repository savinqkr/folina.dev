import SwiftUI

struct DiaryCard: View {
    let diary: DiarySummary
    var isSample = false

    var body: some View {
        VStack(alignment: .center, spacing: FolinaTheme.Spacing.small) {
            DiaryCoverView(diary: diary)
            Text(diary.title)
                .font(FolinaTheme.Typography.label)
                .foregroundStyle(FolinaTheme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
            Text(diary.subtitle)
                .font(FolinaTheme.Typography.caption)
                .foregroundStyle(FolinaTheme.Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
        }
        .frame(width: 192)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(diary.title), \(diary.subtitle), \(isSample ? "샘플 다이어리" : "내 다이어리")")
        .accessibilityIdentifier(diary.id)
    }
}

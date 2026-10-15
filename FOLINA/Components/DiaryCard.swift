import SwiftUI

struct DiaryCard: View {
    let diary: DiarySummary

    var body: some View {
        VStack(alignment: .leading, spacing: FolinaTheme.Spacing.small) {
            DiaryCoverView(diary: diary)
            Text(diary.title)
                .font(FolinaTheme.Typography.label)
                .foregroundStyle(FolinaTheme.Palette.ink)
            Text(diary.subtitle)
                .font(FolinaTheme.Typography.caption)
                .foregroundStyle(FolinaTheme.Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(diary.title), \(diary.subtitle), 샘플 다이어리")
        .accessibilityIdentifier(diary.id)
    }
}

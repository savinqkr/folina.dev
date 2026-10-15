import SwiftUI

struct BookshelfView: View {
    let diaries: [DiarySummary]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                FolinaHeader()
                HStack(spacing: 0) {
                    if geometry.size.width >= 900 {
                        sidebar
                    }
                    bookshelf
                }
            }
        }
        .background(FolinaTheme.Palette.canvas)
        .preferredColorScheme(.light)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: FolinaTheme.Spacing.large) {
            Text("내 다이어리")
                .font(FolinaTheme.Typography.label)
                .foregroundStyle(FolinaTheme.Palette.ink)
                .padding(.horizontal, FolinaTheme.Spacing.medium)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .background(FolinaTheme.Palette.selection, in: RoundedRectangle(cornerRadius: 7))
                .accessibilityAddTraits(.isSelected)
            ForEach(["무료 굿즈", "내 굿즈", "설정"], id: \.self) { title in
                Text(title)
                    .font(FolinaTheme.Typography.body)
                    .foregroundStyle(FolinaTheme.Palette.secondary)
                    .padding(.horizontal, FolinaTheme.Spacing.medium)
                    .accessibilityLabel("\(title), 준비 중")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13)
        .padding(.top, FolinaTheme.Spacing.section)
        .frame(width: 195)
        .background(FolinaTheme.Palette.surface)
    }

    private var bookshelf: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FolinaTheme.Spacing.section) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: FolinaTheme.Spacing.large) {
                        introduction
                        Spacer(minLength: 16)
                        createButton
                    }
                    VStack(alignment: .leading, spacing: FolinaTheme.Spacing.medium) {
                        introduction
                        createButton
                    }
                }

                VStack(alignment: .leading, spacing: 40) {
                    Text("MY COLLECTION")
                        .font(FolinaTheme.Typography.caption.weight(.semibold))
                        .foregroundStyle(FolinaTheme.Palette.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 24)],
                              alignment: .leading, spacing: 36) {
                        ForEach(diaries) { diary in
                            DiaryCard(diary: diary)
                        }
                    }
                }
                .padding(30)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FolinaTheme.Palette.collection,
                            in: RoundedRectangle(cornerRadius: 15))
            }
            .padding(.horizontal, FolinaTheme.Spacing.page)
            .padding(.vertical, 36)
            .frame(maxWidth: 1200, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("bookshelf-home")
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: FolinaTheme.Spacing.medium) {
            Text("내 다이어리")
                .font(FolinaTheme.Typography.title)
                .foregroundStyle(FolinaTheme.Palette.ink)
                .accessibilityAddTraits(.isHeader)
            Text("책처럼 소장하고, 펼치고, 다시 꾸미는 나의 기록")
                .font(FolinaTheme.Typography.body)
                .foregroundStyle(FolinaTheme.Palette.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(minWidth: 200, alignment: .leading)
    }

    private var createButton: some View {
        NavigationLink {
            DiaryCreationView()
        } label: {
            Text("+ 새 다이어리 만들기")
        }
        .buttonStyle(FolinaPrimaryButtonStyle())
        .fixedSize()
        .accessibilityIdentifier("create-diary")
    }
}

#Preview("책장 홈") {
    BookshelfView(diaries: SampleDiaries.bookshelf)
}

import SwiftUI

struct BookshelfView: View {
    let diaries: [DiarySummary]
    @State private var isSidebarExpanded = true

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                FolinaHeader()
                HStack(spacing: 0) {
                    if geometry.size.width >= 600 {
                        BookshelfSidebar(isExpanded: $isSidebarExpanded)
                    }
                    bookshelf
                }
            }
        }
        .background(FolinaTheme.Palette.canvas)
        .preferredColorScheme(.light)
    }

    private var bookshelf: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
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

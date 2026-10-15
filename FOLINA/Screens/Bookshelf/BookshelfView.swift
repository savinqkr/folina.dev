import SwiftUI

struct BookshelfView: View {
    let diaries: [DiarySummary]
    @State private var showsCreationNotice = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                appHeader
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
        .alert("새 다이어리 만들기", isPresented: $showsCreationNotice) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("다이어리 생성 기능은 준비 중이에요.")
        }
    }

    private var appHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image("HeaderLogo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .accessibilityHidden(true)
                Text("FOLINA")
                    .font(FolinaTheme.Typography.brand)
            }
            Spacer()
            Text("LIBRARY")
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
        Button("+ 새 다이어리 만들기") {
            showsCreationNotice = true
        }
        .buttonStyle(FolinaPrimaryButtonStyle())
        .fixedSize()
        .accessibilityIdentifier("create-diary")
    }
}

#Preview("책장 홈") {
    BookshelfView(diaries: SampleDiaries.bookshelf)
}

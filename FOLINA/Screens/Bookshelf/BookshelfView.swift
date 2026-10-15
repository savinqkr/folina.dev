import SwiftUI

struct BookshelfView: View {
    let diaries: [DiarySummary]
    @Environment(DiaryLibrary.self) private var library
    @State private var isSidebarExpanded = true

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                FolinaHeader()
                HStack(spacing: 0) {
                    if geometry.size.width >= 600 {
                        BookshelfSidebar(isExpanded: $isSidebarExpanded)
                    }
                    GeometryReader { contentGeometry in
                        bookshelf(width: contentGeometry.size.width)
                    }
                }
            }
        }
        .background(FolinaTheme.Palette.canvas)
        .preferredColorScheme(.light)
    }

    private func bookshelf(width: CGFloat) -> some View {
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
                    if library.isLoading {
                        ProgressView("다이어리 불러오는 중…")
                    } else if let error = library.loadError {
                        Text(error).foregroundStyle(.red)
                        Button("다시 불러오기") { Task { await library.load() } }
                    } else if diaries.isEmpty {
                        Text("아직 다이어리가 없어요. 새 다이어리를 만들어 보세요.")
                            .accessibilityIdentifier("bookshelf-empty")
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 224), spacing: 24)],
                              alignment: .leading, spacing: 36) {
                        ForEach(diaries) { diary in
                            if let document = library.documents.first(where: { $0.id.uuidString == diary.id }) {
                                NavigationLink {
                                    DiaryDetailView(document: document)
                                } label: {
                                    DiaryCard(diary: diary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(30)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FolinaTheme.Palette.collection,
                            in: RoundedRectangle(cornerRadius: 15))

            }
            .padding(.horizontal, FolinaTheme.Spacing.horizontalPage(width: width))
            .padding(.vertical, 36)
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
        .disabled(!library.isReady)
        .fixedSize()
        .accessibilityIdentifier("create-diary")
    }
}

#Preview("책장 홈") {
    BookshelfView(diaries: []).environment(DiaryLibrary())
}

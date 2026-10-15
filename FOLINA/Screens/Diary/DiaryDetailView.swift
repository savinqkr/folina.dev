import SwiftUI

/// 기존 책장의 실제 문서 진입점을 읽기 화면으로 확장합니다.
struct DiaryDetailView: View {
    let document: DiaryDocument
    @Environment(DiaryLibrary.self) private var library
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var position: DiaryReadingPosition
    @State private var panel: ReadingPanel?
    @State private var isSaving = false
    @State private var isTurning = false
    @State private var errorMessage: String?
    @State private var showEditorNotice = false
    @State private var turnForward = true
    @ScaledMetric(relativeTo: .body) private var controlHeight = 52.0

    init(document: DiaryDocument) {
        self.document = document
        _position = State(initialValue: DiaryReadingPosition(pages: document.pages))
    }

    private var current: DiaryDocument {
        library.documents.first { $0.id == document.id } ?? document
    }

    var body: some View {
        GeometryReader { geometry in
            let spread = DiaryReadingPosition.usesSpread(width: geometry.size.width, height: geometry.size.height)
            VStack(spacing: 0) {
                FolinaHeader()
                HStack(spacing: 16) {
                    Button { dismiss() } label: { Label("나의 책장", systemImage: "chevron.left") }
                        .accessibilityIdentifier("close-reader")
                    Spacer(minLength: 8)
                    Text(current.title).font(.headline).lineLimit(2).accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 8)
                    Button("편집 준비 중") { showEditorNotice = true }
                }
                .font(.subheadline)
                .padding(20)
                if current.pages.isEmpty {
                    ContentUnavailableView("페이지가 없어요", systemImage: "book.closed",
                                           description: Text("저장된 페이지가 없는 다이어리예요."))
                } else {
                    let indices = position.visibleIndices(in: current.pages, spread: spread)
                    DiaryReadingBook(document: current, indices: indices, spread: spread,
                                     selectedID: position.pageID) { id in
                        guard !isTurning else { return }
                        position.select(id, in: current.pages)
                    }
                    .id(indices.first)
                    .transition(.asymmetric(
                        insertion: .offset(x: turnForward ? 28 : -28).combined(with: .opacity),
                        removal: .offset(x: turnForward ? -28 : 28).combined(with: .opacity)))
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 35).onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) * 1.4 else { return }
                        turn(forward: value.translation.width < 0, spread: spread)
                    })
                    .accessibilityAction(named: Text("다음 페이지")) { turn(forward: true, spread: spread) }
                    .accessibilityAction(named: Text("이전 페이지")) { turn(forward: false, spread: spread) }
                    navigation(spread: spread)
                }
            }
        }
        .background(FolinaTheme.Palette.collection)
        .preferredColorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("diary-detail")
        .sheet(item: $panel) { selection in
            NavigationStack {
                ReadingPageList(document: current, bookmarksOnly: selection == .bookmarks,
                                selectedID: position.pageID) { id in
                    position.select(id, in: current.pages)
                    panel = nil
                }
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("닫기") { panel = nil } } }
            }
        }
        .alert("책갈피를 저장하지 못했어요", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("확인", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        .alert("편집 기능은 준비 중이에요", isPresented: $showEditorNotice) {
            Button("확인", role: .cancel) { }
        } message: { Text("지금은 읽기와 페이지 탐색, 책갈피를 사용할 수 있어요.") }
    }

    private func navigation(spread: Bool) -> some View {
        VStack(spacing: 8) {
            let indices = position.visibleIndices(in: current.pages, spread: spread)
            if let first = indices.first, let last = indices.last {
                Text(first == last ? "\(first + 1) / \(current.pages.count)페이지" : "\(first + 1)–\(last + 1) / \(current.pages.count)페이지")
                    .monospacedDigit().accessibilityIdentifier("reading-position")
                if spread, let index = position.index(in: current.pages) {
                    Text("선택: \(index + 1)페이지 · 종이를 눌러 선택")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    Button { turn(forward: false, spread: spread) } label: {
                        Label("이전", systemImage: "chevron.left")
                    }
                    .disabled(isTurning || position.destination(in: current.pages, spread: spread, forward: false) == nil)
                    .accessibilityIdentifier("reading-previous")
                    Button("목차") { panel = .contents }
                        .accessibilityIdentifier("reading-contents")
                    Button("책갈피 목록") { panel = .bookmarks }
                        .accessibilityIdentifier("reading-bookmarks")
                    Button { saveBookmark() } label: {
                        let bookmarked = position.pageID.map { current.bookmarks.contains($0) } ?? false
                        Label(bookmarked ? "책갈피 해제" : "책갈피 추가", systemImage: bookmarked ? "bookmark.fill" : "bookmark")
                    }
                    .disabled(isSaving || position.pageID == nil)
                    .accessibilityIdentifier("reading-toggle-bookmark")
                    Button { turn(forward: true, spread: spread) } label: {
                        Label("다음", systemImage: "chevron.right")
                    }
                    .disabled(isTurning || position.destination(in: current.pages, spread: spread, forward: true) == nil)
                    .accessibilityIdentifier("reading-next")
                }
                .buttonStyle(.borderless)
                .frame(minHeight: 44)
                .padding(.horizontal, 20)
            }
            .frame(height: controlHeight)
        }
        .font(.subheadline)
        .padding(.vertical, 12)
    }

    private func turn(forward: Bool, spread: Bool) {
        guard !isTurning,
              let id = position.destination(in: current.pages, spread: spread, forward: forward) else { return }
        isTurning = true
        turnForward = forward
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.24), completionCriteria: .logicallyComplete) {
            position.select(id, in: current.pages)
        } completion: {
            isTurning = false
        }
    }

    private func saveBookmark() {
        guard !isSaving, let pageID = position.pageID else { return }
        let desired = !current.bookmarks.contains(pageID)
        isSaving = true
        Task { @MainActor in
            defer { isSaving = false }
            do {
                try await library.setBookmark(diaryID: current.id, pageID: pageID, isBookmarked: desired)
            } catch {
                errorMessage = "기존 책갈피는 유지됩니다. 다시 시도해 주세요.\n\(error.localizedDescription)"
            }
        }
    }
}

private enum ReadingPanel: String, Identifiable {
    case contents, bookmarks
    var id: String { rawValue }
}

private struct ReadingPageList: View {
    let document: DiaryDocument
    let bookmarksOnly: Bool
    let selectedID: UUID?
    let select: (UUID) -> Void

    private var indices: [Int] {
        document.pages.indices.filter { !bookmarksOnly || document.bookmarks.contains(document.pages[$0].id) }
    }

    var body: some View {
        List {
            if indices.isEmpty {
                Text(bookmarksOnly ? "설정한 책갈피가 없어요." : "페이지가 없어요.")
            }
            ForEach(indices, id: \.self) { index in
                let page = document.pages[index]
                Button { select(page.id) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(index + 1)페이지 · \(page.paper.title)")
                            if let date = page.date {
                                Text(date.readingLabel).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if document.bookmarks.contains(page.id) { Image(systemName: "bookmark.fill") }
                        if page.id == selectedID { Image(systemName: "checkmark") }
                    }
                }
                .accessibilityIdentifier("reading-jump-\(index + 1)")
            }
        }
        .navigationTitle(bookmarksOnly ? "책갈피" : "목차 · \(document.pages.count)페이지")
        .navigationBarTitleDisplayMode(.inline)
    }
}

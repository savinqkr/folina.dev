import Foundation

struct TrashedDiaryPage: Codable, Equatable, Identifiable {
    var id: UUID { page.id }
    let page: DiaryPage
    let originalIndex: Int
    let wasBookmarked: Bool
    let deletedAt: Date
}

enum DiaryPageMutation {
    case append(DiaryPage, after: UUID?)
    case reorder([UUID])
    case trash(UUID)
    case restore(UUID)
}

extension DiaryDocument {
    func validate() throws {
        let all = pages + trash.map(\.page)
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              Set(all.map(\.id)).count == all.count,
              bookmarks.isSubset(of: Set(pages.map(\.id))),
              trash.allSatisfy({ $0.originalIndex >= 0 }),
              all.allSatisfy({ $0.diaryID == id && $0.widthMM.isFinite && $0.heightMM.isFinite &&
                  $0.widthMM > 0 && $0.heightMM > 0 }) else { throw DiaryStorageError.damagedDocument }
    }

    mutating func apply(_ mutation: DiaryPageMutation, now: Date = Date()) throws {
        try validate()
        // 유효성 검증 중 실패해도 호출자 값이 부분 변경되지 않게 복사본에 적용합니다.
        var next = self
        try next.applyValidated(mutation, now: now)
        self = next
    }

    private mutating func applyValidated(_ mutation: DiaryPageMutation, now: Date) throws {
        switch mutation {
        case let .append(page, after):
            guard page.diaryID == id, !(pages + trash.map(\.page)).contains(where: { $0.id == page.id })
            else { throw DiaryStorageError.damagedDocument }
            let index: Int
            if let after {
                guard let previous = pages.firstIndex(where: { $0.id == after }) else { throw DiaryStorageError.conflict }
                index = previous + 1
            } else { index = pages.count }
            pages.insert(page, at: index)
        case let .reorder(ids):
            guard ids.count == pages.count, Set(ids) == Set(pages.map(\.id)) else { throw DiaryStorageError.conflict }
            let lookup = Dictionary(uniqueKeysWithValues: pages.map { ($0.id, $0) })
            pages = ids.compactMap { lookup[$0] }
        case let .trash(id):
            guard pages.count > 1 else { throw DiaryStorageError.lastPage }
            guard let index = pages.firstIndex(where: { $0.id == id }) else { throw DiaryStorageError.conflict }
            var entries = trash
            entries.append(TrashedDiaryPage(page: pages[index], originalIndex: index,
                                           wasBookmarked: bookmarks.contains(id), deletedAt: now))
            deletedPages = entries
            pages.remove(at: index)
            var kept = bookmarks
            kept.remove(id)
            bookmarkPageIDs = kept
        case let .restore(id):
            var entries = trash
            guard let index = entries.firstIndex(where: { $0.id == id }) else { throw DiaryStorageError.conflict }
            let entry = entries.remove(at: index)
            pages.insert(entry.page, at: min(entry.originalIndex, pages.count))
            deletedPages = entries
            if entry.wasBookmarked {
                var kept = bookmarks
                kept.insert(id)
                bookmarkPageIDs = kept
            }
        }
        try validate()
        updatedAt = now
    }

    func newPage(now: Date = Date(), timeZone: TimeZone = .current) -> DiaryPage {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: now)
        let date = options.kind == .dated
            ? DiaryDate(year: parts.year!, month: parts.month!, day: parts.day!) : nil
        return DiaryPage(id: UUID(), diaryID: id, paper: options.paper, orientation: options.orientation,
                         widthMM: options.orientation == .portrait ? 210 : 297,
                         heightMM: options.orientation == .portrait ? 297 : 210, date: date)
    }
}

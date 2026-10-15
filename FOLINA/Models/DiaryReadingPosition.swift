import Foundation

/// 배열은 저장된 순서, UUID는 읽던 페이지의 정체성입니다. 레이아웃 변경은 선택을 바꾸지 않습니다.
struct DiaryReadingPosition {
    private(set) var pageID: UUID?

    init(pages: [DiaryPage]) { pageID = pages.first?.id }

    func index(in pages: [DiaryPage]) -> Int? {
        pages.firstIndex { $0.id == pageID }
    }

    func visibleIndices(in pages: [DiaryPage], spread: Bool) -> [Int] {
        guard let index = index(in: pages) else { return [] }
        let start = spread ? index / 2 * 2 : index
        return Array(start..<min(pages.count, start + (spread ? 2 : 1)))
    }

    func destination(in pages: [DiaryPage], spread: Bool, forward: Bool) -> UUID? {
        let visible = visibleIndices(in: pages, spread: spread)
        guard let first = visible.first, let last = visible.last else { return nil }
        let next = forward ? last + 1 : first - (spread ? 2 : 1)
        guard pages.indices.contains(next) else { return nil }
        return pages[next].id
    }

    mutating func select(_ id: UUID, in pages: [DiaryPage]) {
        guard pages.contains(where: { $0.id == id }) else { return }
        pageID = id
    }

    /// 기기 방향 대신 현재 창의 실사용 크기를 판정합니다.
    static func usesSpread(width: Double, height: Double) -> Bool {
        width >= 760 && width > height
    }
}

import Foundation

/// DB 참조를 확정하기 전에 복제 sidecar를 모두 준비합니다. 실패 시 원본을 삭제하지 않습니다.
@MainActor
struct DiaryPageManager {
    let inkStore: PageInkStore
    let decorationStore: PageDecorationStore

    init(inkStore: PageInkStore = .shared, decorationStore: PageDecorationStore = .shared) {
        self.inkStore = inkStore
        self.decorationStore = decorationStore
    }

    func recover(_ protection: ProtectedPageSnapshot, source: DiaryPage) async throws -> DiaryPage {
        guard protection.pageID == source.id else { throw DiaryStorageError.damagedDocument }
        let copy = try await duplicate(source)
        if let ink = protection.ink {
            try ink.validate(for: source)
            let coordinatePage = DiaryPage(id: copy.id, diaryID: copy.diaryID, paper: copy.paper,
                orientation: copy.orientation, widthMM: ink.width / 4, heightMM: ink.height / 4, date: copy.date)
            let previous = try await inkStore.load(page: copy)
            try await inkStore.save(PageInk(page: coordinatePage, payload: ink.payload), replacing: previous)
        }
        if let decoration = protection.decoration {
            try decoration.validate(for: source)
            let previous = try await decorationStore.load(page: copy)
            try await decorationStore.save(decoration.copied(to: copy), page: copy, replacing: previous)
        }
        return copy
    }

    func duplicate(_ page: DiaryPage) async throws -> DiaryPage {
        let copy = DiaryPage(id: UUID(), diaryID: page.diaryID, paper: page.paper,
                             orientation: page.orientation, widthMM: page.widthMM,
                             heightMM: page.heightMM, date: page.date)
        if let ink = try await inkStore.load(page: page) {
            // 저장 좌표를 그대로 유지하고 payload는 값 타입 Data로 독립 파일에 저장합니다.
            let coordinatePage = DiaryPage(id: copy.id, diaryID: copy.diaryID, paper: copy.paper,
                orientation: copy.orientation, widthMM: ink.width / 4, heightMM: ink.height / 4, date: copy.date)
            try await inkStore.save(PageInk(page: coordinatePage, payload: ink.payload), replacing: nil)
        }
        if let decoration = try await decorationStore.load(page: page) {
            try await decorationStore.save(decoration.copied(to: copy), page: copy, replacing: nil)
        }
        return copy
    }
}

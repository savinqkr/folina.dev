import Foundation

/// 엔진별 원본을 보존합니다. 이후 엔진은 별도 형식으로 추가하며 기존 payload를 변환하지 않습니다.
struct PageInk: Codable, Equatable {
    let version: Int
    let engine: String
    let diaryID: UUID
    let pageID: UUID
    let width: Double
    let height: Double
    let payload: Data

    init(page: DiaryPage, payload: Data) {
        version = 1
        engine = "pencilkit"
        diaryID = page.diaryID
        pageID = page.id
        width = page.widthMM * 4
        height = page.heightMM * 4
        self.payload = payload
    }

    func validate(for page: DiaryPage) throws {
        guard version == 1, engine == "pencilkit" else { throw DiaryStorageError.unsupportedVersion }
        guard diaryID == page.diaryID, pageID == page.id,
              width.isFinite, height.isFinite, width > 0, height > 0 else {
            throw DiaryStorageError.damagedDocument
        }
    }
}

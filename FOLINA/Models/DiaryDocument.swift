import Foundation

/// UI 초안과 구분되는 버전 1 문서. 날짜는 시간대 이동에도 유지되는 달력 날짜입니다.
struct DiaryDocument: Codable, Equatable, Identifiable {
    let id: UUID
    let title: String
    let options: DiaryDraft
    let createdAt: Date
    let updatedAt: Date
    let pages: [DiaryPage]
    /// nil은 책갈피 필드가 없던 기존 버전 1 문서를 의미합니다.
    var bookmarkPageIDs: Set<UUID>? = nil

    var bookmarks: Set<UUID> { bookmarkPageIDs ?? [] }

    static func create(from draft: DiaryDraft, now: Date = Date(),
                       timeZone: TimeZone = .current) throws -> Self {
        let title = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw DiaryStorageError.emptyName }
        var options = draft
        options.name = title
        let id = UUID()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: now)
        let date = draft.kind == .dated
            ? DiaryDate(year: parts.year!, month: parts.month!, day: parts.day!) : nil
        let page = DiaryPage(id: UUID(), diaryID: id, paper: draft.paper,
                             orientation: draft.orientation,
                             widthMM: draft.orientation == .portrait ? 210 : 297,
                             heightMM: draft.orientation == .portrait ? 297 : 210,
                             date: date)
        return Self(id: id, title: title, options: options, createdAt: now,
                    updatedAt: now, pages: [page])
    }

    var summary: DiarySummary {
        DiarySummary(id: id.uuidString, title: title,
                     subtitle: "\(options.kind.title) · \(options.binding.title)",
                     cover: options.previewSummary.cover, orientation: options.orientation)
    }
}

struct DiaryDate: Codable, Equatable {
    let year: Int
    let month: Int
    let day: Int
}

struct DiaryPage: Codable, Equatable, Identifiable {
    let id: UUID
    let diaryID: UUID
    let paper: DiaryPaper
    let orientation: DiaryOrientation
    let widthMM: Double
    let heightMM: Double
    let date: DiaryDate?
}

enum DiaryStorageError: Error, LocalizedError {
    case emptyName, unavailable, unsupportedVersion, damagedDocument

    var errorDescription: String? {
        switch self {
        case .emptyName: "다이어리 이름을 입력해 주세요."
        case .unavailable: "저장소를 사용할 수 없어요. 책장에서 다시 불러오기를 눌러 주세요."
        case .unsupportedVersion: "이 앱에서 읽을 수 없는 데이터 버전이에요. 앱 업데이트를 확인해 주세요."
        case .damagedDocument: "저장된 다이어리를 읽을 수 없어요. 원본 데이터는 유지됩니다."
        }
    }
}

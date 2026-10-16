import Foundation

protocol PageInkStorage: Sendable {
    func load(page: DiaryPage) async throws -> PageInk?
    func save(_ ink: PageInk) async throws
}

/// 문서 DB와 분리된 페이지별 원자적 파일 저장. 파일 I/O는 actor에서 수행합니다.
actor PageInkStore: PageInkStorage {
    static let shared = PageInkStore()
    private let root: URL

    init(root: URL = URL.applicationSupportDirectory.appendingPathComponent("FolinaInk/v1", isDirectory: true)) {
        self.root = root
    }

    private func url(diaryID: UUID, pageID: UUID) -> URL {
        root.appendingPathComponent(diaryID.uuidString, isDirectory: true)
            .appendingPathComponent(pageID.uuidString + ".json")
    }

    func load(page: DiaryPage) throws -> PageInk? {
        let file = url(diaryID: page.diaryID, pageID: page.id)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        let ink = try JSONDecoder().decode(PageInk.self, from: Data(contentsOf: file))
        try ink.validate(for: page)
        return ink
    }

    func save(_ ink: PageInk) throws {
        let file = url(diaryID: ink.diaryID, pageID: ink.pageID)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(ink).write(to: file, options: .atomic)
    }
}

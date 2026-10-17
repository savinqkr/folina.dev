import Foundation

protocol PageInkStorage: Sendable {
    func load(page: DiaryPage) async throws -> PageInk?
    func save(_ ink: PageInk) async throws
    func save(_ ink: PageInk, replacing expected: PageInk?) async throws
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

    func protections(diaryID: UUID) throws -> [ProtectedPageSnapshot] {
        let directory = root.appendingPathComponent(diaryID.uuidString).appendingPathComponent("conflicts", isDirectory: true)
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.pathExtension == "json" }.map { file in
                let ink = try JSONDecoder().decode(PageInk.self, from: Data(contentsOf: file))
                guard ink.diaryID == diaryID else { throw DiaryStorageError.damagedDocument }
                return ProtectedPageSnapshot(id: "ink-" + file.lastPathComponent, pageID: ink.pageID,
                    createdAt: try file.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast,
                    ink: ink, decoration: nil)
            }
    }

    func save(_ ink: PageInk, replacing expected: PageInk?) throws {
        let file = url(diaryID: ink.diaryID, pageID: ink.pageID)
        let current: PageInk?
        if FileManager.default.fileExists(atPath: file.path) {
            current = try JSONDecoder().decode(PageInk.self, from: Data(contentsOf: file))
        } else { current = nil }
        guard current == expected else {
            let protection = file.deletingLastPathComponent().appendingPathComponent("conflicts", isDirectory: true)
                .appendingPathComponent(ink.pageID.uuidString + "-" + UUID().uuidString + ".json")
            try FileManager.default.createDirectory(at: protection.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(ink).write(to: protection, options: .atomic)
            throw DiaryStorageError.conflict
        }
        try write(ink)
    }

    /// 명시적 초기화 전용. 기존 파일이 있으면 덮어쓰지 않습니다.
    func save(_ ink: PageInk) throws {
        try save(ink, replacing: nil)
    }

    private func write(_ ink: PageInk) throws {
        let file = url(diaryID: ink.diaryID, pageID: ink.pageID)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(ink).write(to: file, options: .atomic)
    }
}

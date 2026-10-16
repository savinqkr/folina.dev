import Foundation

/// immutable 사진 원본과 페이지 객체 파일. 삭제 대신 휴지통의 참조를 유지합니다.
actor PageDecorationStore {
    static let shared = PageDecorationStore()
    private let root: URL
    init(root: URL = URL.applicationSupportDirectory.appendingPathComponent("FolinaDecoration/v1", isDirectory: true)) {
        self.root = root
    }

    private func directory(_ diaryID: UUID) -> URL { root.appendingPathComponent(diaryID.uuidString, isDirectory: true) }
    private func file(_ page: DiaryPage) -> URL {
        directory(page.diaryID).appendingPathComponent("pages", isDirectory: true)
            .appendingPathComponent(page.id.uuidString + ".json")
    }
    private func assetFile(diaryID: UUID, assetID: UUID) -> URL {
        directory(diaryID).appendingPathComponent("assets", isDirectory: true).appendingPathComponent(assetID.uuidString)
    }

    func load(page: DiaryPage) throws -> PageDecoration? {
        let url = file(page)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let value = try JSONDecoder().decode(PageDecoration.self, from: Data(contentsOf: url))
        try value.validate(for: page)
        return value
    }

    func save(_ value: PageDecoration, page: DiaryPage, replacing expected: PageDecoration?) throws {
        try value.validate(for: page)
        // 같은 actor 안에서 비교와 쓰기를 수행합니다. 불러오기 오류도 덮어쓰지 않습니다.
        guard try load(page: page) == expected else {
            let protection = directory(page.diaryID).appendingPathComponent("conflicts", isDirectory: true)
                .appendingPathComponent(page.id.uuidString + "-" + UUID().uuidString + ".json")
            try write(JSONEncoder().encode(value), to: protection)
            throw DiaryStorageError.conflict
        }
        // 사진 파일이 확정된 이후에만 참조 JSON을 확정합니다.
        for object in value.objects where object.kind == .photo {
            guard let id = object.assetID,
                  FileManager.default.fileExists(atPath: assetFile(diaryID: page.diaryID, assetID: id).path)
            else { throw DiaryStorageError.damagedDocument }
        }
        try write(JSONEncoder().encode(value), to: file(page))
    }

    func protections(diaryID: UUID) throws -> [ProtectedPageSnapshot] {
        let directory = directory(diaryID).appendingPathComponent("conflicts", isDirectory: true)
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.pathExtension == "json" }.map { file in
                let content = try JSONDecoder().decode(PageDecoration.self, from: Data(contentsOf: file))
                guard content.diaryID == diaryID else { throw DiaryStorageError.damagedDocument }
                return ProtectedPageSnapshot(id: "decoration-" + file.lastPathComponent, pageID: content.pageID,
                    createdAt: try file.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast,
                    ink: nil, decoration: content)
            }
    }

    func importPhoto(_ data: Data, diaryID: UUID) throws -> UUID {
        let id = UUID()
        try write(data, to: assetFile(diaryID: diaryID, assetID: id))
        return id
    }

    func photo(diaryID: UUID, assetID: UUID) throws -> Data {
        try Data(contentsOf: assetFile(diaryID: diaryID, assetID: assetID))
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}

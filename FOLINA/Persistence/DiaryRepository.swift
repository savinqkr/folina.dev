import Foundation
import SwiftData

/// SwiftData는 문서 단위 트랜잭션을 담당하고 Codable 문서는 UI와 DB 매크로를 분리합니다.
@Model
final class StoredDiary {
    @Attribute(.unique) var id: UUID
    var formatVersion: Int
    var documentData: Data

    init(document: DiaryDocument) throws {
        id = document.id
        formatVersion = 1
        documentData = try JSONEncoder().encode(document)
    }
}

@MainActor
protocol DiaryRepository {
    func load() async throws -> [DiaryDocument]
    func insert(_ document: DiaryDocument) async throws
}

@MainActor
final class SwiftDataDiaryRepository: DiaryRepository {
    private let container: ModelContainer
    private let context: ModelContext

    init(container: ModelContainer) {
        self.container = container
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    static func local() throws -> SwiftDataDiaryRepository {
        let configuration = ModelConfiguration("FolinaLocal", cloudKitDatabase: .none)
        return try SwiftDataDiaryRepository(container: ModelContainer(
            for: StoredDiary.self, configurations: configuration))
    }

    func load() async throws -> [DiaryDocument] {
        try context.fetch(FetchDescriptor<StoredDiary>()).map { row in
            guard row.formatVersion == 1 else { throw DiaryStorageError.unsupportedVersion }
            let document: DiaryDocument
            do { document = try JSONDecoder().decode(DiaryDocument.self, from: row.documentData) }
            catch { throw DiaryStorageError.damagedDocument }
            guard document.id == row.id, !document.pages.isEmpty,
                  !document.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  Set(document.pages.map(\.id)).count == document.pages.count,
                  document.pages.allSatisfy({ $0.diaryID == row.id && $0.widthMM > 0 && $0.heightMM > 0 })
            else { throw DiaryStorageError.damagedDocument }
            return document
        }.sorted { $0.createdAt > $1.createdAt }
    }

    func insert(_ document: DiaryDocument) async throws {
        // 같은 ID의 재요청은 기존 문서를 덮어쓰지 않습니다.
        let id = document.id
        let request = FetchDescriptor<StoredDiary>(predicate: #Predicate { $0.id == id })
        if try !context.fetch(request).isEmpty { return }
        do {
            context.insert(try StoredDiary(document: document))
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}

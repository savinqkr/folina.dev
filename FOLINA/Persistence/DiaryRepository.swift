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
    func updatePages(expected: DiaryDocument, mutation: DiaryPageMutation) async throws -> DiaryDocument
    func setBookmark(diaryID: UUID, pageID: UUID, isBookmarked: Bool) async throws -> DiaryDocument
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
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<StoredDiary>()).map { row in
            guard row.formatVersion == 1 else { throw DiaryStorageError.unsupportedVersion }
            let document: DiaryDocument
            do { document = try JSONDecoder().decode(DiaryDocument.self, from: row.documentData) }
            catch { throw DiaryStorageError.damagedDocument }
            guard document.id == row.id else { throw DiaryStorageError.damagedDocument }
            try document.validate()
            return document
        }.sorted { $0.createdAt > $1.createdAt }
    }

    func setBookmark(diaryID: UUID, pageID: UUID, isBookmarked: Bool) async throws -> DiaryDocument {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let request = FetchDescriptor<StoredDiary>(predicate: #Predicate { $0.id == diaryID })
        guard let row = try context.fetch(request).first else { throw DiaryStorageError.unavailable }
        guard row.formatVersion == 1 else { throw DiaryStorageError.unsupportedVersion }
        var document = try JSONDecoder().decode(DiaryDocument.self, from: row.documentData)
        try document.validate()
        guard document.id == diaryID, document.pages.contains(where: { $0.id == pageID }) else {
            throw DiaryStorageError.damagedDocument
        }
        var bookmarks = document.bookmarks
        if isBookmarked { bookmarks.insert(pageID) } else { bookmarks.remove(pageID) }
        document.bookmarkPageIDs = bookmarks
        do {
            row.documentData = try JSONEncoder().encode(document)
            try context.save()
            return document
        } catch {
            context.rollback()
            throw error
        }
    }

    func updatePages(expected: DiaryDocument, mutation: DiaryPageMutation) async throws -> DiaryDocument {
        // 새 context에서 확정 값을 읽어 오래된 화면의 전체 문서 덮어쓰기를 막습니다.
        let transaction = ModelContext(container)
        transaction.autosaveEnabled = false
        let id = expected.id
        let request = FetchDescriptor<StoredDiary>(predicate: #Predicate { $0.id == id })
        guard let row = try transaction.fetch(request).first else { throw DiaryStorageError.unavailable }
        guard row.formatVersion == 1 else { throw DiaryStorageError.unsupportedVersion }
        var latest = try JSONDecoder().decode(DiaryDocument.self, from: row.documentData)
        guard latest == expected else { throw DiaryStorageError.conflict }
        try latest.apply(mutation)
        do {
            row.documentData = try JSONEncoder().encode(latest)
            try transaction.save()
            return latest
        } catch {
            transaction.rollback()
            throw error
        }
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

import Foundation
import SwiftData
import Testing
@testable import FOLINA

struct PageMutationTests {
    private func diary() throws -> DiaryDocument {
        var draft = DiaryDraft()
        draft.name = "페이지 관리"
        return try DiaryDocument.create(from: draft)
    }

    @Test func legacyJSONAndTrashRoundTripPreserveIdentity() throws {
        var document = try diary()
        var legacy = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(document)) as? [String: Any])
        legacy.removeValue(forKey: "deletedPages")
        let decoded = try JSONDecoder().decode(DiaryDocument.self, from: JSONSerialization.data(withJSONObject: legacy))
        #expect(decoded.trash.isEmpty)
        let first = document.pages[0]
        document.bookmarkPageIDs = [first.id]
        let added = document.newPage()
        try document.apply(.append(added, after: first.id))
        try document.apply(.trash(first.id))
        #expect(document.pages.map(\.id) == [added.id])
        #expect(document.bookmarks.isEmpty)
        #expect(document.trash[0].page == first)
        let reloaded = try JSONDecoder().decode(DiaryDocument.self, from: JSONEncoder().encode(document))
        #expect(reloaded == document)
        document = reloaded
        try document.apply(.restore(first.id))
        #expect(document.pages.map(\.id) == [first.id, added.id])
        #expect(document.bookmarks == [first.id])
        #expect(document.trash.isEmpty)
    }

    @Test func cannotDeleteLastPageAndInvalidReorderDoesNotMutate() throws {
        var document = try diary()
        let original = document
        #expect(throws: DiaryStorageError.self) { try document.apply(.trash(document.pages[0].id)) }
        #expect(document == original)
        #expect(throws: DiaryStorageError.self) { try document.apply(.reorder([UUID()])) }
        #expect(document == original)
        #expect(throws: DiaryStorageError.self) { try document.apply(.append(original.pages[0], after: nil)) }
        #expect(document == original)
    }

    @Test func reorderKeepsUUIDBookmarksAndPageSpecificPaper() throws {
        var document = try diary()
        let first = document.pages[0]
        let second = DiaryPage(id: UUID(), diaryID: document.id, paper: .dotted, orientation: .landscape,
                               widthMM: 297, heightMM: 210, date: nil)
        try document.apply(.append(second, after: nil))
        document.bookmarkPageIDs = [first.id]
        try document.apply(.reorder([second.id, first.id]))
        #expect(document.pages == [second, first])
        #expect(document.pages[0].paper == .dotted)
        #expect(document.bookmarks == [first.id])
        #expect(document.newPage().paper == document.options.paper)
    }
}

@MainActor
struct PageRepositoryTests {
    @Test func persistedPageOperationsAndStaleSnapshotConflict() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let configuration = ModelConfiguration(url: root.appendingPathComponent("pages.store"), cloudKitDatabase: .none)
        let repository = SwiftDataDiaryRepository(container: try ModelContainer(for: StoredDiary.self, configurations: configuration))
        var draft = DiaryDraft()
        draft.name = "재실행"
        let initial = try DiaryDocument.create(from: draft)
        try await repository.insert(initial)
        let added = initial.newPage()
        let updated = try await repository.updatePages(expected: initial, mutation: .append(added, after: nil))
        do {
            _ = try await repository.updatePages(expected: initial, mutation: .trash(initial.pages[0].id))
            Issue.record("오래된 문서를 덮어씀")
        } catch { #expect(error as? DiaryStorageError == .conflict) }
        let ordered = try await repository.updatePages(expected: updated, mutation: .reorder(updated.pages.reversed().map(\.id)))
        let trashed = try await repository.updatePages(expected: ordered, mutation: .trash(added.id))
        let reopened = SwiftDataDiaryRepository(container: try ModelContainer(for: StoredDiary.self, configurations: configuration))
        #expect(try await reopened.load() == [trashed])
        let restored = try await reopened.updatePages(expected: trashed, mutation: .restore(added.id))
        #expect(restored.pages.map(\.id) == ordered.pages.map(\.id))
    }
}

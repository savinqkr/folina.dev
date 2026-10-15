import Foundation
import SwiftData
import Testing
@testable import FOLINA

struct DiaryReadingPositionTests {
    private func pages(_ count: Int) -> [DiaryPage] {
        let diaryID = UUID()
        return (0..<count).map { _ in
            DiaryPage(id: UUID(), diaryID: diaryID, paper: .grid, orientation: .portrait,
                      widthMM: 210, heightMM: 297, date: nil)
        }
    }

    @Test func boundariesEmptyAndSinglePage() {
        for count in [0, 1] {
            let pages = pages(count)
            let position = DiaryReadingPosition(pages: pages)
            for spread in [false, true] {
                #expect(position.destination(in: pages, spread: spread, forward: false) == nil)
                #expect(position.destination(in: pages, spread: spread, forward: true) == nil)
                #expect(position.visibleIndices(in: pages, spread: spread) == (count == 0 ? [] : [0]))
            }
        }
    }

    @Test func oddSpreadAndLastBoundary() throws {
        let pages = pages(5)
        var position = DiaryReadingPosition(pages: pages)
        #expect(position.visibleIndices(in: pages, spread: true) == [0, 1])
        position.select(try #require(position.destination(in: pages, spread: true, forward: true)), in: pages)
        #expect(position.visibleIndices(in: pages, spread: true) == [2, 3])
        position.select(try #require(position.destination(in: pages, spread: true, forward: true)), in: pages)
        #expect(position.visibleIndices(in: pages, spread: true) == [4])
        #expect(position.destination(in: pages, spread: true, forward: true) == nil)
        #expect(position.destination(in: pages, spread: true, forward: false) == pages[2].id)
    }

    @Test func directJumpRotationAndReorderingPreserveIdentity() {
        let pages = pages(6)
        var position = DiaryReadingPosition(pages: pages)
        position.select(pages[3].id, in: pages)
        #expect(position.visibleIndices(in: pages, spread: false) == [3])
        #expect(position.visibleIndices(in: pages, spread: true) == [2, 3])
        #expect(position.pageID == pages[3].id)
        #expect(position.visibleIndices(in: pages, spread: false) == [3])
        let reordered = Array(pages.reversed())
        #expect(position.index(in: reordered) == 2)
        position.select(UUID(), in: reordered)
        #expect(position.pageID == pages[3].id)
        position.select(pages[0].id, in: pages)
        #expect(position.destination(in: pages, spread: false, forward: false) == nil)
    }

    @Test func windowDimensionsChooseReadableLayout() {
        #expect(!DiaryReadingPosition.usesSpread(width: 820, height: 1180))
        #expect(DiaryReadingPosition.usesSpread(width: 1180, height: 820))
        #expect(!DiaryReadingPosition.usesSpread(width: 600, height: 820))
        #expect(!DiaryReadingPosition.usesSpread(width: 700, height: 500))
    }
}

@MainActor
struct DiaryBookmarkStorageTests {
    private func document(_ name: String) throws -> DiaryDocument {
        var draft = DiaryDraft()
        draft.name = name
        return try DiaryDocument.create(from: draft)
    }

    @Test func bookmarksReloadFromDiskAndRemainSeparateBetweenDiaries() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = ModelConfiguration(url: directory.appendingPathComponent("reading.store"),
                                               cloudKitDatabase: .none)
        let first = try document("첫 번째")
        let second = try document("두 번째")
        do {
            let repository = try SwiftDataDiaryRepository(container: ModelContainer(
                for: StoredDiary.self, configurations: configuration))
            try await repository.insert(first)
            try await repository.insert(second)
            _ = try await repository.setBookmark(diaryID: first.id, pageID: first.pages[0].id, isBookmarked: true)
        }
        let repository = try SwiftDataDiaryRepository(container: ModelContainer(
            for: StoredDiary.self, configurations: configuration))
        let loaded = try await repository.load()
        let saved = try #require(loaded.first { $0.id == first.id })
        #expect(saved.bookmarks == [first.pages[0].id])
        #expect(saved.pages == first.pages)
        #expect(saved.createdAt == first.createdAt)
        #expect(saved.updatedAt == first.updatedAt)
        #expect(loaded.first { $0.id == second.id } == second)
        let removed = try await repository.setBookmark(diaryID: first.id, pageID: first.pages[0].id, isBookmarked: false)
        #expect(removed.bookmarks.isEmpty)
        let reloaded = try await repository.load()
        #expect(reloaded.allSatisfy { $0.bookmarks.isEmpty })
        do {
            _ = try await repository.setBookmark(diaryID: second.id, pageID: first.pages[0].id, isBookmarked: true)
            Issue.record("다른 다이어리의 페이지를 허용함")
        } catch { #expect(error is DiaryStorageError) }
    }

    @Test func storedEmptyAndOddPagesRemainRealDocumentData() async throws {
        let original = try document("여러 페이지")
        let pages = (0..<3).map { _ in
            DiaryPage(id: UUID(), diaryID: original.id, paper: .lined,
                      orientation: .landscape, widthMM: 297, heightMM: 210, date: nil)
        }
        let multiple = DiaryDocument(id: original.id, title: original.title, options: original.options,
                                     createdAt: original.createdAt, updatedAt: original.updatedAt, pages: pages)
        let empty = DiaryDocument(id: UUID(), title: "빈 다이어리", options: original.options,
                                  createdAt: original.createdAt, updatedAt: original.updatedAt, pages: [])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let repository = try SwiftDataDiaryRepository(container: ModelContainer(
            for: StoredDiary.self, configurations: configuration))
        try await repository.insert(multiple)
        try await repository.insert(empty)
        let loaded = try await repository.load()
        let saved = try #require(loaded.first { $0.id == multiple.id })
        #expect(saved.pages == pages)
        #expect(loaded.first { $0.id == empty.id }?.pages.isEmpty == true)
        var position = DiaryReadingPosition(pages: saved.pages)
        position.select(pages[2].id, in: saved.pages)
        #expect(position.visibleIndices(in: saved.pages, spread: true) == [2])
        let bookmarked = try await repository.setBookmark(diaryID: saved.id, pageID: pages[2].id, isBookmarked: true)
        #expect(bookmarked.pages == pages)
        #expect(bookmarked.bookmarks == [pages[2].id])
    }

    @Test func versionOnePayloadWithoutBookmarkFieldLoadsAndKeepsIDs() async throws {
        let original = try document("기존 데이터")
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        json.removeValue(forKey: "bookmarkPageIDs")
        let legacyData = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(DiaryDocument.self, from: legacyData)
        #expect(decoded == original)
        #expect(decoded.bookmarks.isEmpty)
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: StoredDiary.self, configurations: configuration)
        let context = ModelContext(container)
        let row = try StoredDiary(document: original)
        row.documentData = legacyData
        context.insert(row)
        try context.save()
        let repository = SwiftDataDiaryRepository(container: container)
        let loaded = try await repository.load()
        #expect(loaded == [original])
        _ = try await repository.setBookmark(diaryID: original.id, pageID: original.pages[0].id, isBookmarked: true)
        let updated = try await repository.load()
        #expect(updated[0].id == original.id)
        #expect(updated[0].pages == original.pages)
        #expect(updated[0].bookmarks == [original.pages[0].id])
        #expect(row.formatVersion == 1)
    }
}

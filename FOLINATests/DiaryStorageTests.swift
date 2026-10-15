import Foundation
import SwiftData
import Testing
@testable import FOLINA

@MainActor
struct DiaryStorageTests {
    private func memoryRepository() throws -> SwiftDataDiaryRepository {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try SwiftDataDiaryRepository(container: ModelContainer(
            for: StoredDiary.self, configurations: configuration))
    }

    @Test func savesMultipleDiariesAndPreservesEveryOption() async throws {
        let repository = try memoryRepository()
        var expected: [DiaryDocument] = []
        for kind in DiaryKind.allCases {
            for binding in DiaryBinding.creationOptions {
                var draft = DiaryDraft()
                draft.name = "  \(kind.title) \(binding.title)  "
                draft.kind = kind
                draft.binding = binding
                draft.tone = .cocoa
                draft.customColor = DiaryCustomColor(red: 0.2, green: 0.4, blue: 0.8)
                draft.coverStyle = .leatherWrap
                draft.paper = .dotted
                draft.orientation = .landscape
                let document = try DiaryDocument.create(from: draft)
                try await repository.insert(document)
                expected.append(document)
            }
        }
        let loaded = try await repository.load()
        #expect(loaded.count == 9)
        #expect(Set(loaded.map(\.id)).count == 9)
        for original in expected {
            #expect(loaded.first(where: { $0.id == original.id }) == original)
            #expect(original.pages.count == 1)
            #expect(original.pages[0].diaryID == original.id)
            #expect(original.pages[0].widthMM == 297)
            #expect(original.pages[0].heightMM == 210)
            #expect(original.pages[0].paper == .dotted)
            #expect(original.pages[0].orientation == .landscape)
            #expect((original.pages[0].date != nil) == (original.options.kind == .dated))
        }
        try await repository.insert(expected[0])
        let repeated = try await repository.load()
        #expect(repeated.count == 9)
    }

    @Test func reloadsFromNewContainerOnDisk() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = ModelConfiguration(url: directory.appendingPathComponent("test.store"),
                                               cloudKitDatabase: .none)
        var draft = DiaryDraft()
        draft.name = "재실행 후에도 남는 기록"
        let document = try DiaryDocument.create(from: draft)
        do {
            let repository = try SwiftDataDiaryRepository(container: ModelContainer(
                for: StoredDiary.self, configurations: configuration))
            let empty = try await repository.load()
            #expect(empty.isEmpty)
            try await repository.insert(document)
        }
        let reopened = try SwiftDataDiaryRepository(container: ModelContainer(
            for: StoredDiary.self, configurations: configuration))
        let loaded = try await reopened.load()
        #expect(loaded == [document])
        #expect(!loaded.contains(where: { $0.summary.id.hasPrefix("sample-") }))
    }

    @Test func datedPageUsesLocalGregorianDay() throws {
        var draft = DiaryDraft()
        draft.name = "날짜 확인"
        let instant = Date(timeIntervalSince1970: 0)
        let west = try #require(TimeZone(secondsFromGMT: -9 * 3600))
        let east = try #require(TimeZone(secondsFromGMT: 9 * 3600))
        let previous = try DiaryDocument.create(from: draft, now: instant, timeZone: west)
        let next = try DiaryDocument.create(from: draft, now: instant, timeZone: east)
        #expect(previous.pages[0].date == DiaryDate(year: 1969, month: 12, day: 31))
        #expect(next.pages[0].date == DiaryDate(year: 1970, month: 1, day: 1))
        #expect(next.pages[0].widthMM == 210)
        #expect(next.createdAt == instant)
        #expect(next.updatedAt == instant)
    }

    @Test func rejectsEmptyNamesWithoutWriting() async {
        let repository = TestDiaryRepository()
        let library = DiaryLibrary { repository }
        await library.load()
        for name in ["", " \n\t "] {
            var draft = DiaryDraft()
            draft.name = name
            let controller = DiaryCreationController()
            let created = await controller.create(draft: draft, library: library)
            #expect(!created)
            #expect(controller.errorMessage != nil)
            #expect(!controller.isSaving)
        }
        #expect(repository.insertCount == 0)
        #expect(library.documents.isEmpty)
    }

    @Test func blocksOverlappingAndCompletedRequests() async {
        let repository = TestDiaryRepository()
        let library = DiaryLibrary { repository }
        await library.load()
        let controller = DiaryCreationController()
        var draft = DiaryDraft()
        draft.name = "한 번만"
        let input = draft
        repository.duringInsert = {
            #expect(controller.isSaving)
            let second = await controller.create(draft: input, library: library)
            #expect(!second)
        }
        let created = await controller.create(draft: draft, library: library)
        let repeated = await controller.create(draft: draft, library: library)
        repository.duringInsert = nil
        #expect(created)
        #expect(!repeated)
        #expect(repository.insertCount == 1)
        #expect(library.documents.count == 1)
        #expect(controller.hasCreated)
    }

    @Test func failedSaveDoesNotPublishSuccessAndCanRetry() async {
        let repository = TestDiaryRepository()
        let library = DiaryLibrary { repository }
        await library.load()
        repository.failSave = true
        let controller = DiaryCreationController()
        var draft = DiaryDraft()
        draft.name = "보존할 입력"
        let failed = await controller.create(draft: draft, library: library)
        #expect(!failed)
        #expect(!controller.hasCreated)
        #expect(!controller.isSaving)
        #expect(controller.errorMessage != nil)
        #expect(library.documents.isEmpty)
        repository.failSave = false
        let retried = await controller.create(draft: draft, library: library)
        #expect(retried)
        #expect(library.documents.count == 1)
        #expect(controller.errorMessage == nil)
    }

    @Test func failedLoadBlocksCreationAndRetryRecovers() async {
        let repository = TestDiaryRepository()
        repository.failLoad = true
        let library = DiaryLibrary { repository }
        await library.load()
        #expect(!library.isReady)
        #expect(library.loadError != nil)
        var draft = DiaryDraft()
        draft.name = "로드 실패"
        let controller = DiaryCreationController()
        let created = await controller.create(draft: draft, library: library)
        #expect(!created)
        #expect(repository.insertCount == 0)
        repository.failLoad = false
        await library.load()
        #expect(library.isReady)
        #expect(library.loadError == nil)
    }

    @Test func bookmarkFailurePreservesPublishedDataAndRetryWorks() async throws {
        let repository = TestDiaryRepository()
        let library = DiaryLibrary { repository }
        await library.load()
        var draft = DiaryDraft()
        draft.name = "책갈피 오류"
        let document = try DiaryDocument.create(from: draft)
        try await library.insert(document)
        repository.failSave = true
        do {
            try await library.setBookmark(diaryID: document.id, pageID: document.pages[0].id, isBookmarked: true)
            Issue.record("저장 실패가 성공으로 처리됨")
        } catch { }
        #expect(library.documents[0].bookmarks.isEmpty)
        repository.failSave = false
        try await library.setBookmark(diaryID: document.id, pageID: document.pages[0].id, isBookmarked: true)
        #expect(library.documents[0].bookmarks == [document.pages[0].id])
    }

    @Test func damagedOrFuturePayloadIsPreserved() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: StoredDiary.self, configurations: configuration)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        var draft = DiaryDraft()
        draft.name = "손상 보호"
        let row = try StoredDiary(document: DiaryDocument.create(from: draft))
        row.documentData = Data("invalid".utf8)
        context.insert(row)
        try context.save()
        let repository = SwiftDataDiaryRepository(container: container)
        do {
            _ = try await repository.load()
            Issue.record("손상 데이터를 성공으로 처리함")
        } catch { #expect(error is DiaryStorageError) }
        row.formatVersion = 999
        try context.save()
        do {
            _ = try await repository.load()
            Issue.record("미지원 버전을 성공으로 처리함")
        } catch { #expect(error is DiaryStorageError) }
        #expect(try context.fetchCount(FetchDescriptor<StoredDiary>()) == 1)
        #expect(row.documentData == Data("invalid".utf8))
    }
}

@MainActor
private final class TestDiaryRepository: DiaryRepository {
    enum Failure: Error { case simulated }
    var documents: [DiaryDocument] = []
    var insertCount = 0
    var failSave = false
    var failLoad = false
    var duringInsert: (() async -> Void)?

    func load() async throws -> [DiaryDocument] {
        if failLoad { throw Failure.simulated }
        return documents
    }

    func setBookmark(diaryID: UUID, pageID: UUID, isBookmarked: Bool) async throws -> DiaryDocument {
        if failSave { throw Failure.simulated }
        guard let index = documents.firstIndex(where: { $0.id == diaryID }) else {
            throw DiaryStorageError.unavailable
        }
        var bookmarks = documents[index].bookmarks
        if isBookmarked { bookmarks.insert(pageID) } else { bookmarks.remove(pageID) }
        documents[index].bookmarkPageIDs = bookmarks
        return documents[index]
    }

    func insert(_ document: DiaryDocument) async throws {
        insertCount += 1
        await duringInsert?()
        if failSave { throw Failure.simulated }
        documents.append(document)
    }
}

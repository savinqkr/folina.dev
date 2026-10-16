import Foundation
import PencilKit
import Testing
@testable import FOLINA

struct PageInkStorageTests {
    private func page(diaryID: UUID = UUID()) -> DiaryPage {
        DiaryPage(id: UUID(), diaryID: diaryID, paper: .grid, orientation: .portrait,
                  widthMM: 210, heightMM: 297, date: nil)
    }

    @Test func independentPagesAndDiariesReloadEditablePayloadFromDisk() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = PageInkStore(root: root)
        let first = page()
        let second = page(diaryID: first.diaryID)
        let other = page()
        let drawing = PKDrawing(strokes: [PKStroke(ink: PKInk(.pen, color: .black),
            path: PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: 20, y: 30), timeOffset: 0,
                              size: CGSize(width: 3, height: 3), opacity: 1, force: 1, azimuth: 0, altitude: 1),
                PKStrokePoint(location: CGPoint(x: 40, y: 50), timeOffset: 0.1,
                              size: CGSize(width: 3, height: 3), opacity: 1, force: 1, azimuth: 0, altitude: 1)
            ], creationDate: Date()))])
        let ink = PageInk(page: first, payload: drawing.dataRepresentation())
        try await store.save(ink)
        let reopened = PageInkStore(root: root)
        let loaded = try #require(try await reopened.load(page: first))
        #expect(loaded == ink)
        #expect(try PKDrawing(data: loaded.payload).strokes.count == 1)
        #expect(try await reopened.load(page: second) == nil)
        #expect(try await reopened.load(page: other) == nil)
        try await reopened.save(PageInk(page: first, payload: PKDrawing().dataRepresentation()), replacing: loaded)
        let erased = try #require(try await store.load(page: first))
        #expect(try PKDrawing(data: erased.payload).strokes.isEmpty)
    }

    @Test func identityVersionAndCoordinateValidation() throws {
        let first = page()
        let ink = PageInk(page: first, payload: Data())
        try ink.validate(for: first)
        #expect(ink.width == 840)
        #expect(ink.height == 1188)
        #expect(throws: DiaryStorageError.self) { try ink.validate(for: page(diaryID: first.diaryID)) }
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(ink)) as? [String: Any])
        json["version"] = 999
        let future = try JSONDecoder().decode(PageInk.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(throws: DiaryStorageError.self) { try future.validate(for: first) }
    }

    @Test func legacyDocumentUnchangedByInkAndCorruptionNotTreatedAsEmpty() async throws {
        var draft = DiaryDraft()
        draft.name = "기존 다이어리"
        let document = try DiaryDocument.create(from: draft)
        let data = try JSONEncoder().encode(document)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = PageInkStore(root: root)
        #expect(try await store.load(page: document.pages[0]) == nil)
        try await store.save(PageInk(page: document.pages[0], payload: PKDrawing().dataRepresentation()))
        #expect(try JSONDecoder().decode(DiaryDocument.self, from: data) == document)
        let file = root.appendingPathComponent(document.id.uuidString)
            .appendingPathComponent(document.pages[0].id.uuidString + ".json")
        let corrupt = Data("broken".utf8)
        try corrupt.write(to: file)
        do { _ = try await store.load(page: document.pages[0]); Issue.record("손상 파일을 빈 필기로 처리함") }
        catch { }
        #expect(try Data(contentsOf: file) == corrupt)
    }
}

@MainActor
struct InkEditorSessionTests {
    private func page() -> DiaryPage {
        DiaryPage(id: UUID(), diaryID: UUID(), paper: .blank, orientation: .portrait,
                  widthMM: 210, heightMM: 297, date: nil)
    }

    @Test func failedSaveKeepsDirtyStateAndRetryPersists() async throws {
        let store = InkTestStorage()
        let session = InkEditorSession(page: page(), storage: store)
        await session.load()
        session.changed()
        await store.setFailure(true)
        #expect(await session.flush() == false)
        #expect(session.status == "저장 실패")
        #expect(session.errorMessage != nil)
        await store.setFailure(false)
        #expect(await session.flush())
        #expect(session.status == "저장됨")
        #expect(session.errorMessage == nil)
        #expect(await store.count == 1)
    }

    @Test func burstDebouncesAndExitFlushSavesImmediately() async throws {
        let store = InkTestStorage()
        let session = InkEditorSession(page: page(), storage: store)
        await session.load()
        for _ in 0..<10 { session.changed() }
        try await Task.sleep(for: .milliseconds(600))
        #expect(await store.count == 1)
        session.changed()
        #expect(await session.flush())
        #expect(await store.count == 2)
        let reopened = InkEditorSession(page: session.page, storage: store)
        await reopened.load()
        #expect(reopened.ready)
        #expect(reopened.canvas.drawing.dataRepresentation() == session.canvas.drawing.dataRepresentation())
    }

    @Test func reopeningUsesSavedCoordinatesAfterPageLayoutChange() async throws {
        let store = InkTestStorage()
        let original = page()
        try await store.save(PageInk(page: original, payload: PKDrawing().dataRepresentation()))
        let resized = DiaryPage(id: original.id, diaryID: original.diaryID, paper: original.paper,
                                orientation: .landscape, widthMM: 297, heightMM: 210, date: nil)
        let session = InkEditorSession(page: resized, storage: store)
        await session.load()
        #expect(session.drawingSize == CGSize(width: 840, height: 1188))
        session.changed()
        #expect(await session.flush())
        let saved = try #require(try await store.load(page: resized))
        #expect(saved.width == 840)
        #expect(saved.height == 1188)
    }

    @Test func loadFailurePreventsOverwrite() async {
        let store = InkTestStorage()
        await store.setFailure(true)
        let session = InkEditorSession(page: page(), storage: store)
        await session.load()
        #expect(!session.ready)
        session.changed()
        #expect(await session.flush() == false)
        #expect(await store.count == 0)
    }
}

private actor InkTestStorage: PageInkStorage {
    enum Failure: Error { case simulated }
    private var failure = false
    private var ink: PageInk?
    private(set) var count = 0
    func setFailure(_ value: Bool) { failure = value }
    func load(page: DiaryPage) throws -> PageInk? {
        if failure { throw Failure.simulated }
        return ink
    }
    func save(_ ink: PageInk, replacing expected: PageInk?) throws {
        guard self.ink == expected else { throw DiaryStorageError.conflict }
        try save(ink)
    }
    func save(_ ink: PageInk) throws {
        if failure { throw Failure.simulated }
        self.ink = ink
        count += 1
    }
}

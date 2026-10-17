import Foundation
import PencilKit
import Testing
@testable import FOLINA

@MainActor
struct PageDecorationTests {
    private func page() -> DiaryPage {
        DiaryPage(id: UUID(), diaryID: UUID(), paper: .grid, orientation: .portrait,
                  widthMM: 210, heightMM: 297, date: nil)
    }

    @Test func koreanTextPhotoTransformFrameAndOutsideCoordinatesReload() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = PageDecorationStore(root: root)
        let page = page()
        let assetData = Data("immutable-photo-fixture".utf8)
        let assetID = try await store.importPhoto(assetData, diaryID: page.diaryID)
        var content = PageDecoration(page: page)
        content.objects = [
            PageObject(pageID: page.id, kind: .text, text: "한글 입력\n둘째 줄", fontSize: 36,
                       color: ObjectColor(red: 0.5, green: 0.2, blue: 0.1), x: -50, y: 1200,
                       width: 320, height: 180, rotation: -35, zIndex: 1),
            PageObject(pageID: page.id, kind: .photo, assetID: assetID, photoStyle: .polaroid,
                       x: 420, y: 550, width: 300, height: 200, rotation: 15, zIndex: 0)
        ]
        try await store.save(content, page: page, replacing: nil)
        let reopened = PageDecorationStore(root: root)
        #expect(try await reopened.load(page: page) == content)
        #expect(try await reopened.photo(diaryID: page.diaryID, assetID: assetID) == assetData)
        var edited = content
        edited.objects[0].text = "수정한 한글\n줄바꿈"
        edited.objects[1].photoStyle = .corners
        try await store.save(edited, page: page, replacing: content)
        #expect(try await reopened.load(page: page) == edited)
        #expect(try await reopened.photo(diaryID: page.diaryID, assetID: assetID) == assetData)
    }

    @Test func staleWriteCreatesDurableProtectionAndDoesNotOverwrite() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = PageDecorationStore(root: root)
        let page = page()
        var first = PageDecoration(page: page)
        first.objects = [PageObject(pageID: page.id, kind: .text, text: "확정")]
        try await store.save(first, page: page, replacing: nil)
        var stale = first
        stale.objects[0].text = "오래된 화면의 수정"
        do {
            try await store.save(stale, page: page, replacing: nil)
            Issue.record("충돌을 무시함")
        } catch { #expect(error as? DiaryStorageError == .conflict) }
        let reopened = PageDecorationStore(root: root)
        #expect(try await reopened.load(page: page) == first)
        let protections = try await reopened.protections(diaryID: page.diaryID)
        #expect(protections.count == 1)
        #expect(protections.first?.decoration == stale)
    }

    @Test func duplicateKeepsInkAndObjectsIndependentAndSharesImmutablePhoto() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let inkStore = PageInkStore(root: root.appendingPathComponent("ink"))
        let store = PageDecorationStore(root: root.appendingPathComponent("decoration"))
        let manager = DiaryPageManager(inkStore: inkStore, decorationStore: store)
        let page = page()
        let assetID = try await store.importPhoto(Data([1, 2, 3]), diaryID: page.diaryID)
        var original = PageDecoration(page: page)
        original.objects = [PageObject(pageID: page.id, kind: .photo, assetID: assetID),
                            PageObject(pageID: page.id, kind: .text, text: "원본", zIndex: 1)]
        try await store.save(original, page: page, replacing: nil)
        let ink = PageInk(page: page, payload: PKDrawing().dataRepresentation())
        try await inkStore.save(ink, replacing: nil)
        let copy = try await manager.duplicate(page)
        #expect(copy.id != page.id)
        #expect(copy.paper == page.paper)
        let copiedInk = try #require(try await inkStore.load(page: copy))
        #expect(copiedInk.pageID == copy.id)
        #expect(copiedInk.payload == ink.payload)
        let stroke = PKStroke(ink: PKInk(.pen, color: .black), path: PKStrokePath(controlPoints: [
            PKStrokePoint(location: CGPoint(x: 20, y: 30), timeOffset: 0, size: CGSize(width: 3, height: 3),
                          opacity: 1, force: 1, azimuth: 0, altitude: 1),
            PKStrokePoint(location: CGPoint(x: 40, y: 60), timeOffset: 0.1, size: CGSize(width: 3, height: 3),
                          opacity: 1, force: 1, azimuth: 0, altitude: 1)
        ], creationDate: Date()))
        let modifiedInk = PageInk(page: copy, payload: PKDrawing(strokes: [stroke]).dataRepresentation())
        try await inkStore.save(modifiedInk, replacing: copiedInk)
        #expect(try await inkStore.load(page: page) == ink)
        let modifiedReloaded = try #require(try await inkStore.load(page: copy))
        #expect(try PKDrawing(data: modifiedReloaded.payload).strokes.count == 1)
        let copied = try #require(try await store.load(page: copy))
        #expect(Set(copied.objects.map(\.id)).isDisjoint(with: Set(original.objects.map(\.id))))
        #expect(copied.objects.allSatisfy { $0.pageID == copy.id })
        #expect(copied.objects[0].assetID == assetID)
        var changed = copied
        changed.objects.removeFirst()
        changed.objects[0].text = "복제본만 수정"
        try await store.save(changed, page: copy, replacing: copied)
        #expect(try await store.load(page: page) == original)
        #expect(try await store.photo(diaryID: page.diaryID, assetID: assetID) == Data([1, 2, 3]))
        let protection = ProtectedPageSnapshot(id: "test", pageID: page.id, createdAt: Date(), ink: nil, decoration: changed.copied(to: page))
        let recovered = try await manager.recover(protection, source: page)
        #expect(recovered.id != page.id)
        #expect(try await store.load(page: page) == original)
    }

    @Test func missingAssetAndCorruptFileDoNotReplaceConfirmedContent() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = PageDecorationStore(root: root)
        let page = page()
        let initial = PageDecoration(page: page)
        try await store.save(initial, page: page, replacing: nil)
        var broken = initial
        broken.objects = [PageObject(pageID: page.id, kind: .photo, assetID: UUID())]
        do { try await store.save(broken, page: page, replacing: initial); Issue.record("누락된 사진을 참조함") }
        catch { #expect(error as? DiaryStorageError == .damagedDocument) }
        #expect(try await store.load(page: page) == initial)
        let file = root.appendingPathComponent(page.diaryID.uuidString).appendingPathComponent("pages")
            .appendingPathComponent(page.id.uuidString + ".json")
        try Data("corrupt".utf8).write(to: file)
        do { try await store.save(initial, page: page, replacing: initial); Issue.record("손상 파일을 덮어씀") }
        catch { }
        #expect(try Data(contentsOf: file) == Data("corrupt".utf8))
    }

    @Test func inkConflictRetainsConfirmedAndIncomingPayload() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = PageInkStore(root: root)
        let page = page()
        let confirmed = PageInk(page: page, payload: Data([1]))
        let incoming = PageInk(page: page, payload: Data([2]))
        try await store.save(confirmed, replacing: nil)
        do { try await store.save(incoming, replacing: nil); Issue.record("충돌을 무시함") }
        catch { #expect(error as? DiaryStorageError == .conflict) }
        #expect(try await store.load(page: page) == confirmed)
        #expect(try await store.protections(diaryID: page.diaryID).first?.ink == incoming)
    }

    @Test func trashAndRestoreKeepInkObjectsAndSharedAssets() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let inkStore = PageInkStore(root: root.appendingPathComponent("ink"))
        let store = PageDecorationStore(root: root.appendingPathComponent("decoration"))
        var draft = DiaryDraft()
        draft.name = "휴지통 보존"
        var document = try DiaryDocument.create(from: draft)
        let original = document.pages[0]
        let second = document.newPage()
        try document.apply(.append(second, after: nil))
        let asset = try await store.importPhoto(Data([4, 5, 6]), diaryID: document.id)
        var content = PageDecoration(page: original)
        content.objects = [PageObject(pageID: original.id, kind: .photo, assetID: asset)]
        try await store.save(content, page: original, replacing: nil)
        let ink = PageInk(page: original, payload: PKDrawing().dataRepresentation())
        try await inkStore.save(ink, replacing: nil)
        document.bookmarkPageIDs = [original.id]
        try document.apply(.trash(original.id))
        #expect(document.bookmarks.isEmpty)
        #expect(try await store.load(page: original) == content)
        #expect(try await inkStore.load(page: original) == ink)
        try document.apply(.restore(original.id))
        #expect(document.pages[0] == original)
        #expect(document.bookmarks == [original.id])
        #expect(try await store.photo(diaryID: document.id, assetID: asset) == Data([4, 5, 6]))
    }

    @Test func textEditsAndLayerOrderPersistFromEditorSession() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = PageDecorationStore(root: root)
        let page = page()
        let session = DecorationEditorSession(page: page, store: store)
        await session.load(size: CGSize(width: 840, height: 1188))
        session.addText()
        let first = try #require(session.selectedID)
        session.update(first) { $0.text = "한글 첫째 줄\n둘째 줄"; $0.rotation = 30; $0.x = -100 }
        session.addText()
        let second = try #require(session.selectedID)
        session.moveSelected(forward: false)
        #expect(await session.flush())
        let loaded = try #require(try await store.load(page: page))
        #expect(loaded.objects.sorted { $0.zIndex < $1.zIndex }.map(\.id) == [second, first])
        #expect(loaded.objects.first(where: { $0.id == first })?.text == "한글 첫째 줄\n둘째 줄")
        let reopened = DecorationEditorSession(page: page, store: store)
        await reopened.load(size: CGSize(width: 840, height: 1188))
        #expect(reopened.content == loaded)
        reopened.selectedID = second
        reopened.deleteSelected()
        #expect(await reopened.flush())
        #expect(try await store.load(page: page)?.objects.map(\.id) == [first])
    }

    @Test func failedObjectSaveKeepsMemoryAndRetryPersists() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let blocked = root.appendingPathComponent("blocked")
        let page = page()
        let session = DecorationEditorSession(page: page, store: PageDecorationStore(root: blocked))
        await session.load(size: CGSize(width: 840, height: 1188))
        session.addText()
        try Data([1]).write(to: blocked)
        #expect(await session.flush() == false)
        #expect(session.content.objects.count == 1)
        #expect(session.errorMessage != nil)
        try FileManager.default.removeItem(at: blocked)
        #expect(await session.flush())
        #expect(session.errorMessage == nil)
    }
}

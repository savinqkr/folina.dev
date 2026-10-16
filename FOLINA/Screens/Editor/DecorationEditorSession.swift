import Foundation
import Observation
import UIKit

@MainActor @Observable
final class DecorationEditorSession {
    let page: DiaryPage
    private(set) var content: PageDecoration
    private(set) var ready = false
    private(set) var status = "불러오는 중…"
    private(set) var errorMessage: String?
    private(set) var hasConflict = false
    private(set) var importing = false
    var selectedID: UUID?
    private var saved: PageDecoration?
    private var revision = 0
    private var savedRevision = 0
    private var protectedRevision: Int?
    var currentIsProtected: Bool { hasConflict && protectedRevision == revision }
    private var pending: Task<Void, Never>?
    private var writes: Task<Bool, Never>?
    private let store: PageDecorationStore

    var selected: PageObject? { content.objects.first { $0.id == selectedID } }

    init(page: DiaryPage, store: PageDecorationStore = .shared) {
        self.page = page
        self.store = store
        content = PageDecoration(page: page)
    }

    func load(size: CGSize) async {
        guard !ready else { return }
        do {
            let loaded = try await store.load(page: page)
            if let loaded {
                guard loaded.width == size.width, loaded.height == size.height else { throw DiaryStorageError.damagedDocument }
            }
            saved = loaded
            content = loaded ?? PageDecoration(page: page, width: size.width, height: size.height)
            ready = true
            errorMessage = nil
            status = "저장됨"
        } catch { errorMessage = error.localizedDescription; status = "꾸미기 불러오기 실패" }
    }

    func addText() {
        guard ready else { return }
        let object = PageObject(pageID: page.id, kind: .text, text: "텍스트를 입력하세요",
                                x: content.width / 2, y: content.height / 2,
                                zIndex: content.objects.count)
        content.objects.append(object)
        selectedID = object.id
        changed()
    }

    func importPhoto(_ data: Data) async {
        guard ready, !importing else { return }
        importing = true
        defer { importing = false }
        do {
            // PhotosPicker가 전달한 원본을 앱 내부에 먼저 확정합니다. 전체 보관함 권한은 요청하지 않습니다.
            guard let image = PhotoPreview.decode(data), image.size.width > 0, image.size.height > 0 else {
                throw DiaryStorageError.damagedDocument
            }
            let id = try await store.importPhoto(data, diaryID: page.diaryID)
            let width = min(320, content.width * 0.6)
            let object = PageObject(pageID: page.id, kind: .photo, assetID: id,
                                    x: content.width / 2, y: content.height / 2, width: width,
                                    height: width * image.size.height / image.size.width,
                                    zIndex: content.objects.count)
            content.objects.append(object)
            selectedID = object.id
            changed()
        } catch { errorMessage = "사진을 추가하지 못했어요. 기존 내용은 유지됩니다.\n\(error.localizedDescription)" }
    }

    func reportImportFailure(_ message: String) { errorMessage = message }

    func update(_ id: UUID, _ change: (inout PageObject) -> Void) {
        guard ready, let index = content.objects.firstIndex(where: { $0.id == id }) else { return }
        var object = content.objects[index]
        change(&object)
        guard (try? object.validate(pageID: page.id)) != nil, object != content.objects[index] else { return }
        content.objects[index] = object
        changed()
    }

    func deleteSelected() {
        guard ready, let selectedID else { return }
        content.objects.removeAll { $0.id == selectedID }
        self.selectedID = nil
        normalizeOrder()
        changed()
    }

    func moveSelected(forward: Bool) {
        guard ready, let selectedID else { return }
        content.objects.sort { $0.zIndex < $1.zIndex }
        guard let index = content.objects.firstIndex(where: { $0.id == selectedID }) else { return }
        let destination = forward ? index + 1 : index - 1
        guard content.objects.indices.contains(destination) else { return }
        content.objects.swapAt(index, destination)
        normalizeOrder()
        changed()
    }

    private func normalizeOrder() {
        for index in content.objects.indices { content.objects[index].zIndex = index }
    }

    private func changed() {
        revision += 1
        status = "꾸미기 저장 대기"
        pending?.cancel()
        pending = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(400)) } catch { return }
            _ = await self?.flush()
        }
    }

    func flush() async -> Bool {
        pending?.cancel()
        pending = nil
        guard ready, !importing else { return false }
        let previous = writes
        if revision == savedRevision { return await previous?.value ?? true }
        let snapshot = content
        let target = revision
        status = "꾸미기 저장 중…"
        let write = Task { @MainActor [weak self] () -> Bool in
            _ = await previous?.value
            guard let self else { return false }
            // 같은 스냅샷의 중복 flush는 성공한 앞선 쓰기를 재사용합니다.
            if target <= self.savedRevision { return true }
            do {
                try await self.store.save(snapshot, page: self.page, replacing: self.saved)
                self.saved = snapshot
                self.savedRevision = target
                if self.revision == target {
                    self.status = "꾸미기 저장됨"
                    self.errorMessage = nil
                    self.hasConflict = false
                }
                return true
            } catch {
                self.hasConflict = (error as? DiaryStorageError) == .conflict
                if self.hasConflict { self.protectedRevision = target }
                self.status = self.hasConflict ? "꾸미기 충돌 사본 보관됨" : "꾸미기 저장 실패"
                self.errorMessage = error.localizedDescription
                return false
            }
        }
        writes = write
        return await write.value
    }
}

import Foundation
import Observation
import PencilKit

@MainActor @Observable
final class InkEditorSession {
    let page: DiaryPage
    let canvas = InkCanvasView()
    private(set) var ready = false
    private(set) var status = "불러오는 중…"
    private(set) var errorMessage: String?
    private(set) var canUndo = false
    private(set) var hasConflict = false
    private var protectedRevision: Int?
    var currentIsProtected: Bool { hasConflict && protectedRevision == revision }
    private(set) var canRedo = false
    private var revision = 0
    private var savedRevision = 0
    private var savedInk: PageInk?
    private var pending: Task<Void, Never>?
    private var writes: Task<Bool, Never>?
    private var writingRevision: Int?
    private let storage: any PageInkStorage
    private var coordinateWidth: Double
    private var coordinateHeight: Double
    var drawingSize: CGSize { CGSize(width: coordinateWidth, height: coordinateHeight) }

    init(page: DiaryPage, storage: any PageInkStorage = PageInkStore.shared) {
        self.page = page
        self.storage = storage
        coordinateWidth = page.widthMM * 4
        coordinateHeight = page.heightMM * 4
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.isScrollEnabled = false
        canvas.drawingPolicy = .anyInput
    }

    func load() async {
        guard !ready else { return }
        do {
            if let ink = try await storage.load(page: page) {
                canvas.drawing = try PKDrawing(data: ink.payload)
                savedInk = ink
                coordinateWidth = ink.width
                coordinateHeight = ink.height
            }
            canvas.undoManager?.removeAllActions()
            ready = true
            errorMessage = nil
            status = "저장됨"
        } catch {
            status = "불러오기 실패"
            errorMessage = "필기를 불러오지 못했어요. 원본은 유지됩니다. 다시 시도해 주세요.\n\(error.localizedDescription)"
        }
    }

    func changed() {
        guard ready else { return }
        revision += 1
        status = "저장 대기"
        updateUndo()
        pending?.cancel()
        pending = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(400)) } catch { return }
            guard let self else { return }
            _ = await self.flush()
        }
    }

    /// 모든 쓰기는 앞선 요청 뒤에 실행하여 오래된 스냅샷이 최신 저장을 덮지 않게 합니다.
    @discardableResult func flush() async -> Bool {
        pending?.cancel()
        pending = nil
        guard ready else { return false }
        if writingRevision == revision, let writes { return await writes.value }
        if revision == savedRevision { return true }
        let target = revision
        let ink = PageInk(page: DiaryPage(id: page.id, diaryID: page.diaryID, paper: page.paper,
                                         orientation: page.orientation, widthMM: coordinateWidth / 4,
                                         heightMM: coordinateHeight / 4, date: page.date),
                          payload: canvas.drawing.dataRepresentation())
        let previous = writes
        let storage = storage
        status = "저장 중…"
        writingRevision = target
        let write = Task { @MainActor [weak self] () -> Bool in
            _ = await previous?.value
            do {
                guard let self else { return false }
                try await storage.save(ink, replacing: self.savedInk)
                self.savedInk = ink
                if self.writingRevision == target { self.writingRevision = nil }
                self.savedRevision = max(self.savedRevision, target)
                if self.revision == target { self.status = "저장됨"; self.errorMessage = nil; self.hasConflict = false }
                return true
            } catch {
                if self?.writingRevision == target { self?.writingRevision = nil }
                self?.hasConflict = (error as? DiaryStorageError) == .conflict
                if self?.hasConflict == true { self?.protectedRevision = target }
                self?.status = self?.hasConflict == true ? "필기 충돌 사본 보관됨" : "저장 실패"
                self?.errorMessage = "필기를 저장하지 못했어요. 편집 화면을 유지하고 다시 저장해 주세요.\n\(error.localizedDescription)"
                return false
            }
        }
        writes = write
        return await write.value
    }

    func undo() { canvas.undoManager?.undo(); updateUndo() }
    func redo() { canvas.undoManager?.redo(); updateUndo() }
    func updateUndo() {
        canUndo = canvas.undoManager?.canUndo ?? false
        canRedo = canvas.undoManager?.canRedo ?? false
    }
}

/// PKCanvasView가 responder chain 변경과 무관하게 같은 세션의 실행 취소 기록을 사용합니다.
@MainActor
final class InkCanvasView: PKCanvasView {
    private let history = UndoManager()
    override var undoManager: UndoManager? { history }
}

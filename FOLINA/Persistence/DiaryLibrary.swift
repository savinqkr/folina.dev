import Foundation
import Observation

@MainActor @Observable
final class DiaryLibrary {
    private(set) var documents: [DiaryDocument] = []
    private(set) var isLoading = false
    private(set) var isReady = false
    private(set) var loadError: String?
    private var repository: (any DiaryRepository)?
    private let makeRepository: @MainActor () throws -> any DiaryRepository

    init(makeRepository: @escaping @MainActor () throws -> any DiaryRepository = { try SwiftDataDiaryRepository.local() }) {
        self.makeRepository = makeRepository
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let storage = try repository ?? makeRepository()
            let loaded = try await storage.load()
            repository = storage
            documents = loaded
            loadError = nil
            isReady = true
        } catch {
            isReady = false
            loadError = "다이어리를 불러오지 못했어요. 저장된 데이터는 삭제하지 않았어요. 다시 시도해 주세요.\n\(error.localizedDescription)"
        }
    }

    func insert(_ document: DiaryDocument) async throws {
        guard isReady, let repository else { throw DiaryStorageError.unavailable }
        try await repository.insert(document)
        if !documents.contains(where: { $0.id == document.id }) {
            documents.insert(document, at: 0)
        }
    }
}

/// 화면 수명 동안 요청을 한 번만 완료합니다. 실패 후에는 같은 입력으로 재시도할 수 있습니다.
@MainActor @Observable
final class DiaryCreationController {
    private(set) var isSaving = false
    private(set) var hasCreated = false
    var errorMessage: String?

    func create(draft: DiaryDraft, library: DiaryLibrary) async -> Bool {
        guard !isSaving, !hasCreated else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            let document = try DiaryDocument.create(from: draft)
            try await library.insert(document)
            hasCreated = true
            errorMessage = nil
            return true
        } catch {
            errorMessage = "다이어리를 만들지 못했어요. 입력한 내용은 유지됩니다.\n\(error.localizedDescription)"
            return false
        }
    }
}

import SwiftUI

struct DiaryPageManagementView: View {
    let diaryID: UUID
    let select: (UUID) -> Void
    @Environment(DiaryLibrary.self) private var library
    @State private var busy = false
    @State private var errorMessage: String?
    @State private var deleting: DiaryPage?
    @State private var protections: [ProtectedPageSnapshot] = []

    private var document: DiaryDocument? { library.documents.first { $0.id == diaryID } }

    var body: some View {
        Group {
            if let document {
                List {
                    Section("페이지 · 드래그하여 순서 변경") {
                        ForEach(Array(document.pages.enumerated()), id: \.element.id) { index, page in
                            VStack(alignment: .leading, spacing: 8) {
                                Button("\(index + 1)페이지 · \(page.paper.title)") { select(page.id) }
                                    .accessibilityIdentifier("manage-page-\(index + 1)")
                                HStack {
                                    Button("복제", systemImage: "square.on.square") { duplicate(page, in: document) }
                                    Spacer()
                                    Button("휴지통으로", systemImage: "trash", role: .destructive) { deleting = page }
                                        .disabled(document.pages.count <= 1)
                                }.font(.caption).buttonStyle(.borderless)
                            }
                        }
                        .onMove { source, destination in
                            var ids = document.pages.map(\.id)
                            ids.move(fromOffsets: source, toOffset: destination)
                            mutate(document, .reorder(ids))
                        }
                        Button("새 페이지 추가", systemImage: "plus") {
                            let page = document.newPage()
                            mutate(document, .append(page, after: nil), selected: page.id)
                        }.accessibilityIdentifier("add-page")
                        if document.pages.count == 1 {
                            Text("마지막 페이지는 삭제할 수 없어요.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Section("저장 충돌 보호 사본") {
                        Text("기존 페이지를 덮어쓰지 않고 새 페이지로 복구합니다. 사본은 복구 후에도 보관합니다.")
                            .font(.caption).foregroundStyle(.secondary)
                        ForEach(protections) { protection in
                            VStack(alignment: .leading) {
                                Text(protection.title)
                                Text(protection.createdAt, style: .date).font(.caption)
                                Button("새 페이지로 복구") { recover(protection, in: document) }
                                    .buttonStyle(.borderless)
                            }
                        }
                        if protections.isEmpty { Text("보호 사본이 없어요.").foregroundStyle(.secondary) }
                    }
                    Section("페이지 휴지통 · \(document.trash.count)개") {
                        Text("영구 삭제하지 않습니다. 필기와 사진을 보관하며 원래 위치에 복원합니다.")
                            .font(.caption).foregroundStyle(.secondary)
                        ForEach(document.trash) { entry in
                            HStack {
                                Text("이전 \(entry.originalIndex + 1)페이지 · \(entry.page.paper.title)")
                                Spacer()
                                Button("복원") { mutate(document, .restore(entry.id), selected: entry.id) }
                                    .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            } else { ContentUnavailableView("다이어리를 찾을 수 없어요", systemImage: "book.closed") }
        }
        .task {
            do {
                let ink = try await PageInkStore.shared.protections(diaryID: diaryID)
                let decoration = try await PageDecorationStore.shared.protections(diaryID: diaryID)
                protections = (ink + decoration).sorted { $0.createdAt > $1.createdAt }
            } catch { errorMessage = "보호 사본을 불러오지 못했어요. 사본은 삭제하지 않았습니다.\n\(error.localizedDescription)" }
        }
        .disabled(busy)
        .environment(\.editMode, .constant(.active))
        .navigationTitle("페이지 관리")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("페이지를 휴지통으로 이동할까요?", isPresented: Binding(
            get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
            if let page = deleting, let document {
                Button("휴지통으로 이동", role: .destructive) { mutate(document, .trash(page.id)); deleting = nil }
            }
            Button("취소", role: .cancel) { deleting = nil }
        } message: { Text("필기·텍스트·사진은 유지되며 페이지 관리에서 복원할 수 있어요.") }
        .alert("페이지 변경을 저장하지 못했어요", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("다시 불러오기") { Task { await library.load() } }
            Button("확인", role: .cancel) { }
        } message: { Text(errorMessage ?? "") }
    }

    private func recover(_ protection: ProtectedPageSnapshot, in document: DiaryDocument) {
        guard !busy else { return }
        guard let source = (document.pages + document.trash.map(\.page)).first(where: { $0.id == protection.pageID }) else {
            errorMessage = "사본의 원본 페이지 정보를 찾지 못했어요. 파일은 보존됩니다."
            return
        }
        busy = true
        Task { @MainActor in
            defer { busy = false }
            do {
                let copy = try await DiaryPageManager().recover(protection, source: source)
                try await library.updatePages(expected: document, mutation: .append(copy, after: nil))
                select(copy.id)
            } catch { errorMessage = error.localizedDescription }
        }
    }

    private func duplicate(_ page: DiaryPage, in document: DiaryDocument) {
        guard !busy else { return }
        busy = true
        Task { @MainActor in
            defer { busy = false }
            do {
                let copy = try await DiaryPageManager().duplicate(page)
                try await library.updatePages(expected: document, mutation: .append(copy, after: page.id))
                select(copy.id)
            } catch { errorMessage = error.localizedDescription }
        }
    }

    private func mutate(_ document: DiaryDocument, _ mutation: DiaryPageMutation, selected: UUID? = nil) {
        guard !busy else { return }
        busy = true
        Task { @MainActor in
            defer { busy = false }
            do {
                try await library.updatePages(expected: document, mutation: mutation)
                if let selected { select(selected) }
            } catch { errorMessage = error.localizedDescription }
        }
    }
}

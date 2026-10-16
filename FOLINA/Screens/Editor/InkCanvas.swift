import SwiftUI
import PencilKit

/// SwiftUI 레이아웃은 고정 페이지 좌표를 함께 확대합니다. PKDrawing 자체를 재변환하지 않습니다.
struct InkCanvas: UIViewRepresentable {
    let session: InkEditorSession
    let tool: PKTool
    let touchEnabled: Bool

    func makeCoordinator() -> Coordinator { Coordinator(session: session) }
    func makeUIView(context: Context) -> PKCanvasView {
        session.canvas.delegate = context.coordinator
        return session.canvas
    }
    func updateUIView(_ view: PKCanvasView, context: Context) {
        view.tool = tool
        view.drawingPolicy = touchEnabled ? .anyInput : .pencilOnly
        view.isUserInteractionEnabled = session.ready
    }
    static func dismantleUIView(_ view: PKCanvasView, coordinator: Coordinator) { view.delegate = nil }

    @MainActor final class Coordinator: NSObject, PKCanvasViewDelegate {
        let session: InkEditorSession
        init(session: InkEditorSession) { self.session = session }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) { session.changed() }
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            // 긴 획 동안은 디바운스, 획을 마치면 즉시 확정 저장합니다.
            Task { @MainActor in _ = await session.flush(); session.updateUndo() }
        }
    }
}

/// 읽기에서는 PKCanvasView를 만들지 않고 원본 드로잉의 표시용 이미지만 생성합니다.
struct PageInkOverlay: View {
    let page: DiaryPage
    let refresh: Int
    @State private var ink: PageInk?
    @State private var failed = false

    var body: some View {
        GeometryReader { geometry in
            if let ink, let drawing = try? PKDrawing(data: ink.payload) {
                Image(uiImage: drawing.image(from: CGRect(x: 0, y: 0, width: ink.width, height: ink.height), scale: 1))
                    .resizable().frame(width: geometry.size.width, height: geometry.size.height)
            }
            if failed {
                Label("필기 불러오기 실패 · 편집에서 재시도", systemImage: "exclamationmark.triangle")
                    .font(.caption).padding(8).background(.regularMaterial)
            }
        }
        .allowsHitTesting(false)
        .task(id: refresh) {
            do {
                let loaded = try await PageInkStore.shared.load(page: page)
                if let loaded { _ = try PKDrawing(data: loaded.payload) }
                ink = loaded
                failed = false
            } catch { ink = nil; failed = true }
        }
    }
}

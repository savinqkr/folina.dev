import SwiftUI
import PencilKit

private enum InkTool: String, CaseIterable, Identifiable {
    case pen, marker, eraser
    var id: Self { self }
    var title: String { switch self { case .pen: "펜"; case .marker: "형광펜"; case .eraser: "지우개" } }
    var icon: String { switch self { case .pen: "pencil.tip"; case .marker: "highlighter"; case .eraser: "eraser" } }
}

struct DiaryEditorView: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: InkEditorSession
    @State private var selection: InkTool = .pen
    @State private var color: Color = .black
    @State private var penWidth = 3.0
    @State private var markerWidth = 18.0
    @State private var touchEnabled = true
    @State private var closing = false
    @State private var zoom = 1.0

    init(title: String, page: DiaryPage) {
        self.title = title
        _session = State(initialValue: InkEditorSession(page: page))
    }

    private var tool: PKTool {
        switch selection {
        case .pen: PKInkingTool(.pen, color: UIColor(color), width: penWidth)
        case .marker: PKInkingTool(.marker, color: UIColor(color).withAlphaComponent(0.35), width: markerWidth)
        case .eraser: PKEraserTool(.vector)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            FolinaHeader()
            HStack {
                Button { close() } label: { Label("읽기로", systemImage: "chevron.left") }
                    .disabled(closing || !session.ready)
                Text(title).font(.headline).lineLimit(1)
                Spacer()
                Text(session.status).font(.caption).accessibilityIdentifier("ink-save-status")
                if session.errorMessage != nil {
                    Button("다시 시도") {
                        Task { if session.ready { _ = await session.flush() } else { await session.load() } }
                    }
                }
                if !session.ready { Button("읽기로 돌아가기") { dismiss() } }
            }.padding(16)
            toolbar
            if let error = session.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red).padding(8)
            }
            GeometryReader { geometry in
                let size = session.drawingSize
                let scale = max(0.01, min((geometry.size.width - 40) / size.width,
                                         (geometry.size.height - 40) / size.height)) * zoom
                ScrollView([.horizontal, .vertical]) {
                    ZStack {
                        DiaryPaperSurface(pattern: session.page.paper)
                        InkCanvas(session: session, tool: tool, touchEnabled: touchEnabled)
                            .allowsHitTesting(!closing)
                    }
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .shadow(color: .black.opacity(0.16), radius: 12, y: 6)
                    .scaleEffect(scale)
                    .frame(width: size.width * scale, height: size.height * scale)
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                    .accessibilityIdentifier("ink-canvas")
                }
                .scrollDisabled(touchEnabled)
            }
        }
        .background(FolinaTheme.Palette.collection)
        .preferredColorScheme(.light)
        .interactiveDismissDisabled()
        .task { await session.load() }
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active else { return }
            let background = UIApplication.shared.beginBackgroundTask(withName: "필기 저장", expirationHandler: nil)
            Task { @MainActor in
                _ = await session.flush()
                if background != .invalid { UIApplication.shared.endBackgroundTask(background) }
            }
        }
    }

    private var toolbar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 14) {
                ForEach(InkTool.allCases) { item in
                    Button { selection = item } label: {
                        Image(systemName: item.icon).font(.title2).frame(width: 46, height: 46)
                            .background(selection == item ? FolinaTheme.Palette.spine.opacity(0.18) : .clear,
                                        in: RoundedRectangle(cornerRadius: 10))
                    }
                    .accessibilityLabel(item.title)
                    .accessibilityAddTraits(selection == item ? .isSelected : [])
                }
                Divider().frame(height: 30)
                ColorPicker("색상", selection: $color, supportsOpacity: false).labelsHidden()
                    .disabled(selection == .eraser)
                Slider(value: selection == .marker ? $markerWidth : $penWidth,
                       in: selection == .marker ? 8...40 : 1...12)
                    .frame(width: 110).disabled(selection == .eraser).accessibilityLabel("필기 굵기")
                Button { session.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                    .disabled(!session.canUndo).accessibilityLabel("실행 취소")
                Button { session.redo() } label: { Image(systemName: "arrow.uturn.forward") }
                    .disabled(!session.canRedo).accessibilityLabel("다시 실행")
                Toggle("손가락 필기", isOn: $touchEnabled).fixedSize()
                    .accessibilityHint("끄면 손가락으로 확대된 페이지를 이동할 수 있어요")
                Button { zoom = max(1, zoom - 0.5) } label: { Image(systemName: "minus.magnifyingglass") }
                    .disabled(zoom <= 1).accessibilityLabel("축소")
                Button("\(Int(zoom * 100))%") { zoom = 1 }.accessibilityLabel("페이지 맞춤")
                Button { zoom = min(3, zoom + 0.5) } label: { Image(systemName: "plus.magnifyingglass") }
                    .disabled(zoom >= 3).accessibilityLabel("확대")
            }.padding(.horizontal, 16).frame(minHeight: 60)
        }
        .background(.white)
        .disabled(!session.ready || closing)
    }

    private func close() {
        closing = true
        Task { @MainActor in
            if await session.flush() { dismiss() }
            closing = false
        }
    }
}

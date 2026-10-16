import SwiftUI
import PencilKit
import PhotosUI

private enum InkTool: String, CaseIterable, Identifiable {
    case select, pen, marker, eraser
    var id: Self { self }
    var title: String { switch self { case .select: "선택"; case .pen: "펜"; case .marker: "형광펜"; case .eraser: "지우개" } }
    var icon: String { switch self { case .select: "cursorarrow"; case .pen: "pencil.tip"; case .marker: "highlighter"; case .eraser: "eraser" } }
}

struct DiaryEditorView: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: InkEditorSession
    @State private var objects: DecorationEditorSession
    @State private var photoItem: PhotosPickerItem?
    @State private var loadingPhoto = false
    @State private var selection: InkTool = .pen
    @State private var color: Color = .black
    @State private var penWidth = 3.0
    @State private var markerWidth = 18.0
    @State private var touchEnabled = true
    @State private var closing = false
    @State private var zoom = 1.0
    @State private var showingPenSettings = false
    @State private var showingObjectSettings = false

    init(title: String, page: DiaryPage) {
        self.title = title
        _session = State(initialValue: InkEditorSession(page: page))
        _objects = State(initialValue: DecorationEditorSession(page: page))
    }

    private var tool: PKTool {
        switch selection {
        case .select: PKInkingTool(.pen, color: .black, width: penWidth)
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
                    .disabled(closing || loadingPhoto || objects.importing || !session.ready || !objects.ready)
                Text(title).font(.headline).lineLimit(1)
                Spacer()
                Label(saveStatus, systemImage: session.errorMessage != nil || objects.errorMessage != nil ? "exclamationmark.circle" : "checkmark.circle")
                    .font(.caption).foregroundStyle(.secondary)
                    .accessibilityValue("\(session.status) · \(objects.status)")
                    .accessibilityIdentifier("ink-save-status")
                if session.errorMessage != nil || objects.errorMessage != nil {
                    Button("다시 시도") {
                        Task {
                            if session.ready { _ = await session.flush() } else { await session.load() }
                            if session.ready {
                                if objects.ready { _ = await objects.flush() } else { await objects.load(size: session.drawingSize) }
                            }
                        }
                    }
                }
                if !session.ready || !objects.ready { Button("읽기로 돌아가기") { dismiss() } }
            }.padding(.horizontal, 20).padding(.vertical, 12).tint(FolinaTheme.Palette.ink)
            if session.hasConflict || objects.hasConflict {
                Text("기존 저장은 유지됩니다. ‘읽기로’에서 현재 변경의 보호 사본 저장을 확인한 뒤, 페이지 관리의 보호 사본을 새 페이지로 복구할 수 있어요.").font(.caption).padding(8)
            }
            toolbar
            if let error = session.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red).padding(8)
            }
            if let error = objects.errorMessage {
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
                            .allowsHitTesting(!closing && objects.ready && selection != .select)
                        PageObjectLayer(content: objects.content, session: objects,
                                        interactive: selection == .select && objects.ready && !closing)
                    }
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .shadow(color: .black.opacity(0.16), radius: 12, y: 6)
                    .scaleEffect(scale)
                    .frame(width: size.width * scale, height: size.height * scale)
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                    .accessibilityIdentifier("ink-canvas")
                }
                .scrollDisabled(selection != .select && touchEnabled)
            }
        }
        .background(FolinaTheme.Palette.collection)
        .preferredColorScheme(.light)
        .interactiveDismissDisabled()
        .task {
            await session.load()
            if session.ready { await objects.load(size: session.drawingSize) }
        }
        .onChange(of: selection) { _, tool in if tool != .select { objects.selectedID = nil } }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            loadingPhoto = true
            Task { @MainActor in
                defer { loadingPhoto = false; photoItem = nil }
                do {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        selection = .select
                        await objects.importPhoto(data)
                    } else { objects.reportImportFailure("선택한 사진 데이터를 읽지 못했어요.") }
                } catch { objects.reportImportFailure("사진을 불러오지 못했어요. 다시 선택해 주세요.") }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active else { return }
            let background = UIApplication.shared.beginBackgroundTask(withName: "필기 저장", expirationHandler: nil)
            Task { @MainActor in
                _ = await session.flush()
                _ = await objects.flush()
                if background != .invalid { UIApplication.shared.endBackgroundTask(background) }
            }
        }
    }

    private var saveStatus: String {
        if session.hasConflict || objects.hasConflict { return "보호 사본 보관됨" }
        if session.errorMessage != nil || objects.errorMessage != nil { return "저장 상태 확인" }
        if !session.ready || !objects.ready { return "불러오는 중" }
        if session.status.contains("대기") || objects.status.contains("대기") { return "저장 대기" }
        if session.status.contains("중") || objects.status.contains("중") { return "저장 중" }
        return "자동 저장됨"
    }

    private var toolbar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                drawingTools
                toolbarDivider
                insertionTools
                toolbarDivider
                contextualSettings
                toolbarDivider
                historyTools
                zoomMenu
            }
            .padding(.horizontal, 20).padding(.vertical, 10)
        }
        .scrollIndicators(.hidden)
        .background(.white)
        .overlay(alignment: .bottom) { FolinaTheme.Palette.border.frame(height: 1) }
        .tint(FolinaTheme.Palette.ink)
        .disabled(!session.ready || !objects.ready || closing || loadingPhoto || objects.importing)
    }

    private var drawingTools: some View {
        HStack(spacing: 4) {
            ForEach(InkTool.allCases) { item in
                Button { selection = item } label: {
                    Image(systemName: item.icon)
                }
                .buttonStyle(EditorToolButtonStyle(selected: selection == item))
                .accessibilityLabel(item.title).help(item.title)
                .accessibilityAddTraits(selection == item ? .isSelected : [])
            }
        }
    }

    private var insertionTools: some View {
        HStack(spacing: 4) {
            Button {
                selection = .select
                objects.addText()
                showingObjectSettings = true
            } label: { Image(systemName: "textformat") }
                .buttonStyle(EditorToolButtonStyle()).accessibilityLabel("텍스트 추가").help("텍스트 추가")
            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                Image(systemName: "photo")
            }
            .buttonStyle(EditorToolButtonStyle()).accessibilityLabel("사진 추가").help("사진 추가")
        }
    }

    @ViewBuilder private var contextualSettings: some View {
        if selection == .select {
            Button { showingObjectSettings.toggle() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                    Text(objects.selected?.kind == .photo ? "사진 속성" : objects.selected?.kind == .text ? "텍스트 속성" : "객체 목록")
                        .font(.subheadline.weight(.medium))
                }.padding(.horizontal, 12).frame(height: 44)
            }
            .buttonStyle(.plain)
            .background(FolinaTheme.Palette.canvas, in: RoundedRectangle(cornerRadius: 10))
            .popover(isPresented: $showingObjectSettings) {
                ScrollView { PageObjectInspector(session: objects) }
                    .frame(width: 320, height: 520)
                    .presentationCompactAdaptation(.sheet)
            }
        } else if selection != .eraser {
            Button { showingPenSettings.toggle() } label: {
                HStack(spacing: 10) {
                    Circle().fill(color).frame(width: 20, height: 20)
                        .overlay(Circle().strokeBorder(FolinaTheme.Palette.border))
                    Text("\(Int(selection == .marker ? markerWidth : penWidth)) pt")
                        .font(.caption.monospacedDigit())
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                }.padding(.horizontal, 12).frame(height: 44)
            }
            .buttonStyle(.plain)
            .background(FolinaTheme.Palette.canvas, in: RoundedRectangle(cornerRadius: 10))
            .accessibilityLabel("필기 색상과 굵기 설정")
            .popover(isPresented: $showingPenSettings) { penSettings.presentationCompactAdaptation(.sheet) }
        } else {
            Text("벡터 지우개").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 12)
        }
    }

    private var penSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(selection.title + " 설정").font(.headline)
            ColorPicker("색상", selection: $color, supportsOpacity: false)
            VStack(alignment: .leading, spacing: 8) {
                Text("굵기").font(.subheadline)
                Slider(value: selection == .marker ? $markerWidth : $penWidth,
                       in: selection == .marker ? 8...40 : 1...12).accessibilityLabel("필기 굵기")
            }
            Divider()
            Toggle("손가락으로도 필기", isOn: $touchEnabled)
                .accessibilityHint("끄면 Pencil로 필기하고 손가락으로 페이지를 이동합니다")
        }.padding(24).frame(width: 300).tint(FolinaTheme.Palette.ink)
    }

    private var historyTools: some View {
        HStack(spacing: 0) {
            Button { session.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                .buttonStyle(EditorToolButtonStyle()).disabled(!session.canUndo || selection == .select)
                .accessibilityLabel("필기 실행 취소").help("필기 실행 취소")
            Button { session.redo() } label: { Image(systemName: "arrow.uturn.forward") }
                .buttonStyle(EditorToolButtonStyle()).disabled(!session.canRedo || selection == .select)
                .accessibilityLabel("필기 다시 실행").help("필기 다시 실행")
        }
    }

    private var zoomMenu: some View {
        Menu {
            Button("페이지 맞춤") { zoom = 1 }
            Button("확대", systemImage: "plus.magnifyingglass") { zoom = min(3, zoom + 0.5) }.disabled(zoom >= 3)
            Button("축소", systemImage: "minus.magnifyingglass") { zoom = max(1, zoom - 0.5) }.disabled(zoom <= 1)
        } label: {
            HStack(spacing: 6) {
                Text("\(Int(zoom * 100))%").font(.caption.monospacedDigit())
                Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
            }.padding(.horizontal, 12).frame(height: 44)
        }.accessibilityLabel("페이지 확대율")
    }

    private var toolbarDivider: some View {
        FolinaTheme.Palette.border.frame(width: 1, height: 24).padding(.horizontal, 6)
    }

    private func close() {
        closing = true
        Task { @MainActor in
            let inkSaved = await session.flush()
            let objectsSaved = await objects.flush()
            if (inkSaved || session.currentIsProtected) && (objectsSaved || objects.currentIsProtected) {
                dismiss()
            }
            closing = false
        }
    }
}

private struct EditorToolButtonStyle: ButtonStyle {
    var selected = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .medium))
            .frame(width: 44, height: 44)
            .foregroundStyle(selected ? Color.white : FolinaTheme.Palette.ink)
            .background(selected ? FolinaTheme.Palette.ink : configuration.isPressed ? FolinaTheme.Palette.selection : Color.clear,
                        in: RoundedRectangle(cornerRadius: 11))
            .opacity(isEnabled ? 1 : 0.3)
    }
}

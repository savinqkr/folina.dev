import SwiftUI
import ImageIO
import UniformTypeIdentifiers

/// 원본 사진은 보존하고 표시용 디코딩 크기만 제한합니다.
enum PhotoPreview {
    static func decode(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        if let type = CGImageSourceGetType(source), (type as String) == UTType.gif.identifier { return nil }
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 2048
              ] as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }
}

extension ObjectColor {
    var swiftUIColor: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }
    init(_ color: Color) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        red = Double(r); green = Double(g); blue = Double(b); alpha = Double(a)
    }
}

struct PageObjectVisual: View {
    let object: PageObject
    let diaryID: UUID
    @State private var photo: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if object.kind == .text {
                Text(object.text)
                    .font(.system(size: object.fontSize))
                    .foregroundStyle(object.color.swiftUIColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ZStack {
                    if object.photoStyle == .polaroid { Color.white }
                    if let photo {
                        Image(uiImage: photo).resizable().scaledToFit()
                            .padding(object.photoStyle == .polaroid ? 10 : 0)
                            .padding(.bottom, object.photoStyle == .polaroid ? 24 : 0)
                    } else {
                        Label(failed ? "사진 불러오기 실패" : "사진 불러오는 중", systemImage: "photo")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if object.photoStyle == .corners {
                        VStack {
                            HStack { corner; Spacer(); corner.rotationEffect(.degrees(90)) }
                            Spacer()
                            HStack { corner.rotationEffect(.degrees(-90)); Spacer(); corner.rotationEffect(.degrees(180)) }
                        }.padding(2)
                    }
                }
            }
        }
        .frame(width: object.width, height: object.height)
        .clipped()
        .task(id: object.assetID) {
            guard object.kind == .photo, let asset = object.assetID else { return }
            do {
                let data = try await PageDecorationStore.shared.photo(diaryID: diaryID, assetID: asset)
                photo = PhotoPreview.decode(data)
                failed = photo == nil
            } catch { failed = true }
        }
    }

    private var corner: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 24, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 24))
            path.closeSubpath()
        }
        .fill(Color(red: 0.9, green: 0.86, blue: 0.75))
        .frame(width: 24, height: 24)
    }
}

/// 편집과 읽기가 같은 객체 시각 요소·페이지 좌표를 사용합니다.
struct PageObjectLayer: View {
    let content: PageDecoration
    var session: DecorationEditorSession? = nil
    var interactive = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.contentShape(Rectangle()).onTapGesture { session?.selectedID = nil }
            ForEach(content.objects.sorted { $0.zIndex < $1.zIndex }) { object in
                EditablePageObject(object: object, diaryID: content.diaryID,
                    selected: interactive && session?.selectedID == object.id,
                    editingText: interactive && session?.editingTextID == object.id,
                    beginTextEditing: { session?.editingTextID = object.id },
                    endTextEditing: {
                        if session?.editingTextID == object.id { session?.editingTextID = nil }
                    },
                    select: { session?.selectedID = object.id },
                    update: { change in session?.update(object.id, change) })
                    .position(x: object.x, y: object.y)
                    .zIndex(Double(object.zIndex))
            }
        }
        .frame(width: content.width, height: content.height)
        .coordinateSpace(name: "decoration-page")
        .allowsHitTesting(interactive)
    }
}

private struct EditablePageObject: View {
    let object: PageObject
    let diaryID: UUID
    let selected: Bool
    let editingText: Bool
    let beginTextEditing: () -> Void
    let endTextEditing: () -> Void
    let select: () -> Void
    let update: ((inout PageObject) -> Void) -> Void
    @State private var dragOrigin: CGPoint?
    @State private var scaleOrigin: CGSize?
    @State private var rotateOrigin: Double?
    @State private var handleOrigin: CGSize?

    var body: some View {
        objectContent
            .overlay { selectionBorder.allowsHitTesting(false) }
            .contentShape(Rectangle())
            .overlay(alignment: .bottomTrailing) { resizeHandle }
            .rotationEffect(.degrees(object.rotation))
            .accessibilityLabel(object.kind == .text ? "텍스트: \(object.text)" : "사진")
    }

    @ViewBuilder private var objectContent: some View {
        if object.kind == .text && editingText {
            InlinePageTextEditor(object: object, update: update, endEditing: endTextEditing)
                .frame(width: object.width, height: object.height)
                .clipped()
        } else {
            PageObjectVisual(object: object, diaryID: diaryID)
                .onTapGesture {
                    select()
                    if object.kind == .text { beginTextEditing() }
                }
                .gesture(moveGesture)
                .simultaneousGesture(scaleGesture)
                .simultaneousGesture(rotationGesture)
        }
    }

    @ViewBuilder private var selectionBorder: some View {
        if selected {
            Rectangle().stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
        }
    }

    @ViewBuilder private var resizeHandle: some View {
        if selected {
            Circle().fill(Color.blue).frame(width: 12, height: 12)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .accessibilityLabel("객체 크기 조절")
                .gesture(resizeGesture)
                .alignmentGuide(.trailing) { $0[HorizontalAlignment.center] }
                .alignmentGuide(.bottom) { $0[VerticalAlignment.center] }
        }
    }

    private var moveGesture: some Gesture {
        DragGesture(coordinateSpace: .named("decoration-page"))
            .onChanged(moveObject)
            .onEnded { _ in dragOrigin = nil }
    }

    private var scaleGesture: some Gesture {
        MagnifyGesture()
            .onChanged(scaleObject)
            .onEnded { _ in scaleOrigin = nil }
    }

    private var rotationGesture: some Gesture {
        RotateGesture()
            .onChanged(rotateObject)
            .onEnded { _ in rotateOrigin = nil }
    }

    private var resizeGesture: some Gesture {
        DragGesture(coordinateSpace: .named("decoration-page"))
            .onChanged(resizeObject)
            .onEnded { _ in handleOrigin = nil }
    }

    private func moveObject(_ value: DragGesture.Value) {
        select()
        if dragOrigin == nil { dragOrigin = CGPoint(x: object.x, y: object.y) }
        guard let origin = dragOrigin else { return }
        let x: Double = Double(origin.x + value.translation.width)
        let y: Double = Double(origin.y + value.translation.height)
        update { object in
            object.x = x
            object.y = y
        }
    }

    private func scaleObject(_ value: MagnifyGesture.Value) {
        select()
        if scaleOrigin == nil { scaleOrigin = CGSize(width: object.width, height: object.height) }
        guard let origin = scaleOrigin else { return }
        let minimumFactor: Double = 24 / min(Double(origin.width), Double(origin.height))
        let factor: Double = max(minimumFactor, Double(value.magnification))
        let width: Double = Double(origin.width) * factor
        let height: Double = Double(origin.height) * factor
        update { object in
            object.width = width
            object.height = height
        }
    }

    private func rotateObject(_ value: RotateGesture.Value) {
        select()
        if rotateOrigin == nil { rotateOrigin = object.rotation }
        guard let origin = rotateOrigin else { return }
        let degrees: Double = origin + value.rotation.degrees
        update { $0.rotation = degrees }
    }

    private func resizeObject(_ value: DragGesture.Value) {
        if handleOrigin == nil { handleOrigin = CGSize(width: object.width, height: object.height) }
        guard let origin = handleOrigin else { return }
        let radians: Double = object.rotation * Double.pi / 180
        let translationX: Double = Double(value.translation.width)
        let translationY: Double = Double(value.translation.height)
        let dx: Double = cos(radians) * translationX + sin(radians) * translationY
        let dy: Double = -sin(radians) * translationX + cos(radians) * translationY
        let width: Double = max(24, Double(origin.width) + dx)
        let height: Double
        if object.kind == .photo {
            height = Double(origin.height) * width / Double(origin.width)
        } else {
            height = max(24, Double(origin.height) + dy)
        }
        update { object in
            object.width = width
            object.height = height
        }
    }
}

struct PageDecorationOverlay: View {
    let page: DiaryPage
    let refresh: Int
    @State private var content: PageDecoration?
    @State private var failed = false

    var body: some View {
        GeometryReader { geometry in
            if let content {
                PageObjectLayer(content: content)
                    .scaleEffect(x: geometry.size.width / content.width,
                                 y: geometry.size.height / content.height, anchor: .topLeading)
            }
            if failed { Label("꾸미기 불러오기 실패", systemImage: "exclamationmark.triangle").font(.caption) }
        }
        .clipped()
        .allowsHitTesting(false)
        .task(id: refresh) {
            do { content = try await PageDecorationStore.shared.load(page: page); failed = false }
            catch { content = nil; failed = true }
        }
    }
}

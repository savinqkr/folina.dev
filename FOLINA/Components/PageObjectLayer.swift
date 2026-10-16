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
    let select: () -> Void
    let update: ((inout PageObject) -> Void) -> Void
    @State private var dragOrigin: CGPoint?
    @State private var scaleOrigin: CGSize?
    @State private var rotateOrigin: Double?
    @State private var handleOrigin: CGSize?

    var body: some View {
        PageObjectVisual(object: object, diaryID: diaryID)
            .overlay {
                if selected { Rectangle().stroke(.blue, style: StrokeStyle(lineWidth: 2, dash: [8, 4])) }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: select)
            .gesture(DragGesture(coordinateSpace: .named("decoration-page"))
                .onChanged { value in
                    select()
                    if dragOrigin == nil { dragOrigin = CGPoint(x: object.x, y: object.y) }
                    if let origin = dragOrigin { update { $0.x = origin.x + value.translation.width; $0.y = origin.y + value.translation.height } }
                }.onEnded { _ in dragOrigin = nil })
            .simultaneousGesture(MagnifyGesture().onChanged { value in
                select()
                if scaleOrigin == nil { scaleOrigin = CGSize(width: object.width, height: object.height) }
                if let origin = scaleOrigin {
                    let factor = max(24 / min(origin.width, origin.height), value.magnification)
                    update { $0.width = origin.width * factor; $0.height = origin.height * factor }
                }
            }.onEnded { _ in scaleOrigin = nil })
            .simultaneousGesture(RotateGesture().onChanged { value in
                select()
                if rotateOrigin == nil { rotateOrigin = object.rotation }
                if let origin = rotateOrigin { update { $0.rotation = origin + value.rotation.degrees } }
            }.onEnded { _ in rotateOrigin = nil })
            .overlay(alignment: .bottomTrailing) {
                if selected {
                    Circle().fill(.blue).frame(width: 24, height: 24)
                        .accessibilityLabel("객체 크기 조절")
                        .gesture(DragGesture(coordinateSpace: .named("decoration-page")).onChanged { value in
                            if handleOrigin == nil { handleOrigin = CGSize(width: object.width, height: object.height) }
                            if let origin = handleOrigin {
                                update {
                                    let radians = object.rotation * .pi / 180
                                    let dx = cos(radians) * value.translation.width + sin(radians) * value.translation.height
                                    let dy = -sin(radians) * value.translation.width + cos(radians) * value.translation.height
                                    let width = max(24, origin.width + dx)
                                    $0.width = width
                                    $0.height = object.kind == .photo ? origin.height * width / origin.width : max(24, origin.height + dy)
                                }
                            }
                        }.onEnded { _ in handleOrigin = nil })
                }
            }
            .rotationEffect(.degrees(object.rotation))
            .accessibilityLabel(object.kind == .text ? "텍스트: \(object.text)" : "사진")
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

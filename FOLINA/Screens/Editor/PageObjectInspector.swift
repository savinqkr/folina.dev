import SwiftUI

/// 페이지 위 공간을 차지하지 않는 선택 객체의 속성 패널입니다.
struct PageObjectInspector: View {
    let session: DecorationEditorSession

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(session.selected?.kind == .photo ? "사진 속성" : "객체 속성")
                    .font(.headline)
                Spacer()
                Text("\(session.content.objects.count)개 객체").font(.caption).foregroundStyle(.secondary)
            }
            objectPicker
            if let object = session.selected {
                Divider()
                if object.kind == .text { textProperties(object) }
                else { photoProperties(object) }
                transformProperties(object)
                Divider()
                arrangement(object)
            } else {
                ContentUnavailableView("객체를 선택하세요", systemImage: "cursorarrow",
                    description: Text("종이 위의 텍스트나 사진을 누르거나 위 목록에서 선택하세요."))
            }
        }
        .padding(20)
        .frame(width: 320)
        .tint(FolinaTheme.Palette.ink)
    }

    private var objectPicker: some View {
        Picker("선택 객체", selection: Binding(get: { session.selectedID }, set: { session.selectedID = $0 })) {
            Text("선택 없음").tag(UUID?.none)
            ForEach(session.content.objects.sorted { $0.zIndex < $1.zIndex }) { object in
                Text(object.kind == .text ? String(object.text.prefix(16)) : "사진 · \(object.photoStyle.title)")
                    .tag(Optional(object.id))
            }
        }
        .font(.subheadline)
        .padding(10)
        .background(FolinaTheme.Palette.canvas, in: RoundedRectangle(cornerRadius: 10))
    }

    private func textProperties(_ object: PageObject) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("텍스트").font(.caption).foregroundStyle(.secondary)
            TextEditor(text: Binding(get: { session.selected?.text ?? "" }, set: { text in
                session.update(object.id) { $0.text = text }
            }))
            .font(.body).frame(height: 96).padding(8)
            .scrollContentBackground(.hidden)
            .background(FolinaTheme.Palette.canvas, in: RoundedRectangle(cornerRadius: 10))
            .accessibilityLabel("텍스트 내용")
            HStack {
                Text("글자 크기").font(.subheadline)
                Spacer()
                Text("\(Int(object.fontSize)) pt").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                ColorPicker("글자 색상", selection: Binding(get: { session.selected?.color.swiftUIColor ?? .black }, set: { color in
                    session.update(object.id) { $0.color = ObjectColor(color) }
                }), supportsOpacity: false).labelsHidden().accessibilityLabel("글자 색상")
            }
            Slider(value: Binding(get: { session.selected?.fontSize ?? 28 }, set: { size in
                session.update(object.id) { $0.fontSize = size }
            }), in: 10...120).accessibilityLabel("글자 크기")
        }
    }

    private func photoProperties(_ object: PageObject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("프레임").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(PhotoStyle.allCases) { style in
                    Button {
                        session.update(object.id) { $0.photoStyle = style }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: style == .plain ? "photo" : style == .polaroid ? "photo.artframe" : "viewfinder")
                                .font(.system(size: 22, weight: .light)).frame(height: 30)
                            Text(style.title).font(.caption)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(object.photoStyle == style ? FolinaTheme.Palette.selection : FolinaTheme.Palette.canvas,
                                    in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(object.photoStyle == style ? FolinaTheme.Palette.spine : .clear))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(object.photoStyle == style ? .isSelected : [])
                }
            }
        }
    }

    private func transformProperties(_ object: PageObject) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("크기").font(.subheadline)
                Spacer()
                iconButton("축소", "minus.magnifyingglass") {
                    session.update(object.id) { $0.width *= 0.9; $0.height *= 0.9 }
                }
                iconButton("확대", "plus.magnifyingglass") {
                    session.update(object.id) { $0.width *= 1.1; $0.height *= 1.1 }
                }
            }
            HStack {
                Text("회전").font(.subheadline)
                Spacer()
                Text("\(Int(object.rotation.truncatingRemainder(dividingBy: 360)))°")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                iconButton("왼쪽 회전", "rotate.left") { session.update(object.id) { $0.rotation -= 15 } }
                iconButton("오른쪽 회전", "rotate.right") { session.update(object.id) { $0.rotation += 15 } }
            }
        }
    }

    private func arrangement(_ object: PageObject) -> some View {
        HStack(spacing: 8) {
            iconButton("뒤로 보내기", "square.3.layers.3d.down.right") { session.moveSelected(forward: false) }
            iconButton("앞으로 가져오기", "square.3.layers.3d") { session.moveSelected(forward: true) }
            iconButton("종이 가운데로", "scope") {
                session.update(object.id) { $0.x = session.content.width / 2; $0.y = session.content.height / 2 }
            }
            Spacer()
            Button(role: .destructive) { session.deleteSelected() } label: {
                Image(systemName: "trash").frame(width: 44, height: 44)
            }.buttonStyle(.plain).foregroundStyle(.red).accessibilityLabel("객체 삭제")
        }
    }

    private func iconButton(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: icon).frame(width: 44, height: 44) }
            .buttonStyle(.plain)
            .background(FolinaTheme.Palette.canvas, in: RoundedRectangle(cornerRadius: 9))
            .accessibilityLabel(title).help(title)
    }
}

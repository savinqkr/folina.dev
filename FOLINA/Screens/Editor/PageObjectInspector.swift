import SwiftUI

struct PageObjectInspector: View {
    let session: DecorationEditorSession

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Picker("객체", selection: Binding(get: { session.selectedID }, set: { session.selectedID = $0 })) {
                    Text("선택 해제").tag(UUID?.none)
                    ForEach(session.content.objects.sorted { $0.zIndex < $1.zIndex }) { object in
                        Text(object.kind == .text ? String(object.text.prefix(16)) : "사진 · \(object.photoStyle.title)")
                            .tag(Optional(object.id))
                    }
                }
                .frame(maxWidth: 300)
                if let object = session.selected {
                    Button("뒤로", systemImage: "square.3.layers.3d.down.right") { session.moveSelected(forward: false) }
                    Button("앞으로", systemImage: "square.3.layers.3d") { session.moveSelected(forward: true) }
                    Button("가운데로") {
                        session.update(object.id) { $0.x = session.content.width / 2; $0.y = session.content.height / 2 }
                    }
                    Button("삭제", systemImage: "trash", role: .destructive) { session.deleteSelected() }
                }
            }.font(.caption)
            if let object = session.selected {
                if object.kind == .text {
                    HStack {
                        TextEditor(text: Binding(get: { session.selected?.text ?? "" }, set: { text in
                            session.update(object.id) { $0.text = text }
                        }))
                        .font(.body)
                        .frame(height: 80)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.gray.opacity(0.3)))
                        .accessibilityLabel("텍스트 내용")
                        VStack {
                            Text("글자 크기 \(Int(object.fontSize))")
                            Slider(value: Binding(get: { session.selected?.fontSize ?? 28 }, set: { size in
                                session.update(object.id) { $0.fontSize = size }
                            }), in: 10...120).frame(width: 120).accessibilityLabel("글자 크기")
                        }.font(.caption)
                        ColorPicker("글자 색상", selection: Binding(get: { session.selected?.color.swiftUIColor ?? .black }, set: { color in
                            session.update(object.id) { $0.color = ObjectColor(color) }
                        }), supportsOpacity: false).labelsHidden().accessibilityLabel("글자 색상")
                    }
                } else {
                    Picker("사진 프레임", selection: Binding(get: { session.selected?.photoStyle ?? .plain }, set: { style in
                        session.update(object.id) { $0.photoStyle = style }
                    })) {
                        ForEach(PhotoStyle.allCases) { style in Text(style.title).tag(style) }
                    }.pickerStyle(.segmented)
                }
                HStack {
                    Text("크기")
                    Button("축소") { session.update(object.id) { $0.width *= 0.9; $0.height *= 0.9 } }
                    Button("확대") { session.update(object.id) { $0.width *= 1.1; $0.height *= 1.1 } }
                    Spacer()
                    Text("회전 \(Int(object.rotation.truncatingRemainder(dividingBy: 360)))°")
                    Button("왼쪽 회전") { session.update(object.id) { $0.rotation -= 15 } }
                    Button("오른쪽 회전") { session.update(object.id) { $0.rotation += 15 } }
                }.font(.caption)
            } else {
                Text("객체를 탭하거나 목록에서 선택하세요. 드래그로 이동, 두 손가락으로 크기·회전을 조절합니다.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8).background(.white)
    }
}

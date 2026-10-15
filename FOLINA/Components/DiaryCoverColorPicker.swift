import SwiftUI
import UIKit

/// 이름과 박스 없이 동일한 크기의 원으로 제공하는 표지 팔레트.
struct DiaryCoverColorPicker: View {
    @Binding var draft: DiaryDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("표지 색상")
                .font(FolinaTheme.Typography.label)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 48, maximum: 48), spacing: 12)],
                      alignment: .leading, spacing: 12) {
                ForEach(DiaryCoverTone.creationOptions) { tone in
                    let selected = draft.customColor == nil && draft.tone == tone
                    Button {
                        draft.selectTone(tone)
                    } label: {
                        swatch(tone.color, selected: selected)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tone.title)
                    .accessibilityValue(selected ? "선택됨" : "선택 안 됨")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("tone-\(tone.id)")
                }
                ColorPicker("사용자 색상", selection: customSelection, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 48, height: 48)
                    .background {
                        Circle().strokeBorder(draft.customColor == nil ? Color.clear : FolinaTheme.Palette.ink,
                                              lineWidth: 2)
                    }
                    .accessibilityLabel("사용자 색상 선택")
                    .accessibilityValue(draft.customColor == nil ? "선택 안 됨" : "선택됨")
                    .accessibilityIdentifier("tone-custom")
            }
        }
    }

    private var customSelection: Binding<Color> {
        Binding {
            draft.coverColor
        } set: { color in
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return }
            draft.customColor = DiaryCustomColor(red: Double(red), green: Double(green), blue: Double(blue))
        }
    }

    private func swatch(_ color: Color, selected: Bool) -> some View {
        Circle()
            .fill(color)
            .overlay { Circle().strokeBorder(.black.opacity(0.12), lineWidth: 1) }
            .overlay {
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(FolinaTheme.Palette.ink)
                }
            }
            .frame(width: 32, height: 32)
            .padding(5)
            .overlay {
                Circle().strokeBorder(selected ? FolinaTheme.Palette.ink : .clear, lineWidth: 2)
            }
            .frame(width: 48, height: 48)
            .contentShape(Circle())
    }
}

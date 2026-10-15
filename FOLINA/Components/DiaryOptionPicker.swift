import SwiftUI

/// 선택 표시·접근성·식별자를 공유하는 재사용 옵션 그룹.
struct DiaryOptionPicker<Option: DiaryOption, Content: View>: View {
    @ScaledMetric(relativeTo: .subheadline) private var minimumOptionWidth = 115
    let title: String
    let options: [Option]
    @Binding var selection: Option
    let identifier: String
    @ViewBuilder let label: (Option) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(FolinaTheme.Typography.label)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumOptionWidth), spacing: 8)], spacing: 8) {
                ForEach(options) { option in
                    Button {
                        selection = option
                    } label: {
                        HStack(spacing: 5) {
                            label(option)
                                .lineLimit(2, reservesSpace: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.semibold))
                                .opacity(selection == option ? 1 : 0)
                                .accessibilityHidden(true)
                        }
                        .font(FolinaTheme.Typography.body)
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .background(selection == option ? FolinaTheme.Palette.selection : FolinaTheme.Palette.surface,
                                    in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(selection == option ? FolinaTheme.Palette.spine : FolinaTheme.Palette.border,
                                              lineWidth: 1)
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.title)
                    .accessibilityValue(selection == option ? "선택됨" : "선택 안 됨")
                    .accessibilityAddTraits(selection == option ? .isSelected : [])
                    .accessibilityIdentifier("\(identifier)-\(option.id)")
                }
            }
        }
        .foregroundStyle(FolinaTheme.Palette.ink)
    }
}

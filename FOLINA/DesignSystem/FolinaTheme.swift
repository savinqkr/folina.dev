import SwiftUI

/// Figma v5 책장 홈(27:15)에서 확인한 색상과 공통 스타일.
enum FolinaTheme {
    enum Palette {
        static let canvas = color(0xF8F9FB)
        static let surface = Color.white
        static let collection = color(0xE8EDF1)
        static let selection = color(0xEDF1F4)
        static let border = color(0xE5E9EE)
        static let ink = color(0x20252A)
        static let secondary = color(0x7D8590)
        static let sage = color(0xBBCDC5)
        static let slateBlue = color(0xC5D4E0)
        static let rose = color(0xD7C3CD)
        static let paperEdge = color(0xE7E5E1)
        static let steel = color(0x9DA9B0)
        static let spine = color(0x798C9B)
        static let softSpine = color(0x9B9AA1)

        private static func color(_ hex: UInt32) -> Color {
            Color(red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255,
                  blue: Double(hex & 255) / 255)
        }
    }

    enum Typography {
        static let title = Font.title.weight(.semibold)
        static let brand = Font.title3.weight(.semibold)
        static let body = Font.subheadline
        static let label = Font.subheadline.weight(.semibold)
        static let cover = Font.headline
        static let caption = Font.caption
    }

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let page: CGFloat = 35
        static let section: CGFloat = 56
    }
}

struct FolinaPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FolinaTheme.Typography.label)
            .padding(.horizontal, FolinaTheme.Spacing.medium)
            .frame(minHeight: 44)
            .foregroundStyle(FolinaTheme.Palette.surface)
            .background(FolinaTheme.Palette.ink.opacity(configuration.isPressed ? 0.75 : 1),
                        in: RoundedRectangle(cornerRadius: 8))
    }
}

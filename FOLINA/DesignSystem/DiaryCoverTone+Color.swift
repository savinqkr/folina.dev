import SwiftUI

extension DiaryCoverTone {
    var color: Color {
        switch self {
        case .sage: FolinaTheme.Palette.sage
        case .slateBlue: FolinaTheme.Palette.slateBlue
        case .rose: FolinaTheme.Palette.rose
        case .cocoa: FolinaTheme.Palette.cocoa
        case .butter: FolinaTheme.Palette.butter
        case .lavender: FolinaTheme.Palette.lavender
        case .kraft: FolinaTheme.Palette.kraft
        }
    }
}

extension DiaryCustomColor {
    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: 1) }
}

extension DiaryDraft {
    var coverColor: Color { customColor?.color ?? tone.color }
}

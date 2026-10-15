import Foundation

/// 책장 표시용 값. 영구 저장 모델과 사용자 데이터 저장소를 정의하지 않습니다.
struct DiarySummary: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let cover: DiaryCoverStyle
}

struct DiaryCoverStyle {
    let binding: DiaryBinding
    let tone: DiaryCoverTone
    let design: DiaryCoverDesign
    let customColor: DiaryCustomColor?

    init(binding: DiaryBinding, tone: DiaryCoverTone, design: DiaryCoverDesign = .classic,
         customColor: DiaryCustomColor? = nil) {
        self.binding = binding
        self.tone = tone
        self.design = design
        self.customColor = customColor
    }
}

enum DiaryBinding: String, Codable, CaseIterable {
    case ringBinder
    case spiral
    case hardcover
    case softcover
}

enum DiaryCoverTone: String, Codable, CaseIterable {
    case sage
    case slateBlue
    case rose
    case cocoa
    case butter
    case lavender
    case kraft
}

enum DiaryCoverDesign: String, Codable {
    case classic
    case leatherWrap
    case botanicalWindow
    case kraft
}

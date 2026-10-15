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
}

enum DiaryBinding {
    case ringBinder
    case hardcover
    case softcover
}

enum DiaryCoverTone {
    case sage
    case slateBlue
    case rose
}

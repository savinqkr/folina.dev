import Foundation

/// 화면에서만 유지되는 생성 옵션. 영구 저장 스키마나 실제 용지 규격은 정의하지 않습니다.
struct DiaryDraft: Equatable, Codable {
    var name = ""
    var kind: DiaryKind = .dated
    var binding: DiaryBinding = .ringBinder
    var tone: DiaryCoverTone = .sage
    var coverStyle: CreationCoverStyle = .classic
    var paper: DiaryPaper = .blank
    var orientation: DiaryOrientation = .portrait

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "나의 다이어리" : trimmed
    }

    var previewSummary: DiarySummary {
        DiarySummary(id: "creation-preview", title: displayName, subtitle: kind.title,
                     cover: DiaryCoverStyle(binding: binding, tone: tone, design: coverStyle.design))
    }

    var selectionDescription: String {
        [kind.title, binding.title, tone.title, coverStyle.title, paper.title, orientation.title]
            .joined(separator: " · ")
    }
}

protocol DiaryOption: Hashable, Identifiable {
    var title: String { get }
}

extension DiaryOption where Self: RawRepresentable, RawValue == String {
    var id: String { rawValue }
}

enum DiaryKind: String, CaseIterable, Codable, DiaryOption {
    case dated, freeform, scrapbook
    var title: String {
        switch self {
        case .dated: "날짜형 다이어리"
        case .freeform: "자유 기록형 다이어리"
        case .scrapbook: "자유 스크랩북"
        }
    }
}

extension DiaryBinding: DiaryOption {
    /// 책장 샘플의 스프링 제본은 보존하되 생성 옵션은 이번 요청의 세 가지로 제한합니다.
    static let creationOptions: [Self] = [.ringBinder, .hardcover, .softcover]
    var title: String {
        switch self {
        case .ringBinder: "링 바인더"
        case .hardcover: "하드커버 노트"
        case .softcover: "일반 제본형 노트"
        case .spiral: "스프링 노트"
        }
    }
}

extension DiaryCoverTone: DiaryOption {
    static let creationOptions: [Self] = [.sage, .slateBlue, .lavender, .kraft, .cocoa]
    var title: String {
        switch self {
        case .sage: "세이지"
        case .slateBlue: "슬레이트 블루"
        case .lavender: "라벤더"
        case .kraft: "크라프트"
        case .cocoa: "코코아"
        case .rose: "로즈"
        case .butter: "버터"
        }
    }
}

enum CreationCoverStyle: String, CaseIterable, Codable, DiaryOption {
    case classic, botanicalWindow
    var title: String { self == .classic ? "기본형" : "식물 창 장식" }
    var design: DiaryCoverDesign { self == .classic ? .classic : .botanicalWindow }
}

enum DiaryPaper: String, CaseIterable, Codable, DiaryOption {
    case blank, lined, grid, dotted
    var title: String {
        switch self {
        case .blank: "무지"
        case .lined: "줄노트"
        case .grid: "모눈"
        case .dotted: "도트"
        }
    }
}

enum DiaryOrientation: String, CaseIterable, Codable, DiaryOption {
    case portrait, landscape
    var title: String { self == .portrait ? "세로" : "가로" }
}

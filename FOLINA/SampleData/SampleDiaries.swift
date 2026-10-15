/// 화면 시연 전용 데이터. 사용자 데이터로 저장하거나 자동 생성하지 않습니다.
enum SampleDiaries {
    static let bookshelf: [DiarySummary] = [
        DiarySummary(id: "sample-seasons", title: "사계절의 기록",
                     subtitle: "날짜형 · 링바인더",
                     cover: DiaryCoverStyle(binding: .ringBinder, tone: .sage)),
        DiarySummary(id: "sample-daily", title: "2026 DAILY",
                     subtitle: "날짜형 · 양장노트",
                     cover: DiaryCoverStyle(binding: .hardcover, tone: .slateBlue)),
        DiarySummary(id: "sample-bullet", title: "나의 불렛저널",
                     subtitle: "자유 기록 · 일반 제본",
                     cover: DiaryCoverStyle(binding: .softcover, tone: .rose)),
        DiarySummary(id: "sample-travel", title: "여행의 조각",
                     subtitle: "스크랩북 · 가죽 랩",
                     cover: DiaryCoverStyle(binding: .hardcover, tone: .cocoa, design: .leatherWrap)),
        DiarySummary(id: "sample-ideas", title: "작은 아이디어",
                     subtitle: "자유 기록 · 스프링 노트",
                     cover: DiaryCoverStyle(binding: .spiral, tone: .butter)),
        DiarySummary(id: "sample-reading", title: "독서 노트",
                     subtitle: "독서 기록 · 윈도형 린넨",
                     cover: DiaryCoverStyle(binding: .hardcover, tone: .lavender, design: .botanicalWindow)),
        DiarySummary(id: "sample-mind", title: "오늘의 마음",
                     subtitle: "자유 기록 · 크라프트 노트",
                     cover: DiaryCoverStyle(binding: .softcover, tone: .kraft, design: .kraft))
    ]
}

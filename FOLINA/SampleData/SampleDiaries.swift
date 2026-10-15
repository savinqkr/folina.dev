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
                     cover: DiaryCoverStyle(binding: .softcover, tone: .rose))
    ]
}

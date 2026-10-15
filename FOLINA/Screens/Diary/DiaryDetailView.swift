import SwiftUI

struct DiaryDetailView: View {
    let document: DiaryDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DiaryCoverView(diary: document.summary)
                    .frame(maxWidth: .infinity)
                Text(document.title).font(.title).accessibilityAddTraits(.isHeader)
                Text(document.options.selectionDescription)
                Text("페이지 \(document.pages.count)개 · A4")
                Text("생성일: \(document.createdAt.formatted(date: .abbreviated, time: .shortened))")
                Text("최근 수정: \(document.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                if let page = document.pages.first {
                    Text("페이지 크기: \(page.widthMM.formatted()) × \(page.heightMM.formatted()) mm")
                    if let date = page.date {
                        Text("첫 페이지 날짜: \(String(format: "%04d-%02d-%02d", date.year, date.month, date.day))")
                    }
                }
                Text("읽기 및 페이지 편집 기능은 준비 중이에요.")
                    .foregroundStyle(.secondary)
            }
            .padding(32)
        }
        .navigationTitle("다이어리 정보")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .background(FolinaTheme.Palette.canvas)
        .accessibilityIdentifier("diary-detail")
    }
}

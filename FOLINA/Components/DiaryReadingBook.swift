import SwiftUI

/// 읽기 종이만 담당합니다. 편집기나 페이지 이동 제스처를 소유하지 않습니다.
struct DiaryReadingPaper: View {
    let page: DiaryPage
    let inkRefresh: Int
    let number: Int
    let isSelected: Bool
    let isBookmarked: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            ZStack(alignment: .topTrailing) {
                GeometryReader { geometry in
                    let width = page.widthMM * 4
                    let height = page.heightMM * 4
                    DiaryPaperSurface(pattern: page.paper)
                        .frame(width: width, height: height)
                        .scaleEffect(geometry.size.width / width, anchor: .topLeading)
                }
                PageInkOverlay(page: page, refresh: inkRefresh)
                VStack {
                    HStack {
                        if let date = page.date { Text(date.readingLabel) }
                        Spacer(minLength: 0)
                    }
                    Spacer(minLength: 0)
                    Text("\(number)").monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(FolinaTheme.Palette.secondary)
                .padding(20)
                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(FolinaTheme.Palette.ink)
                        .padding(.trailing, 16)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(FolinaTheme.Palette.spine.opacity(isSelected ? 0.45 : 0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .aspectRatio(page.widthMM / page.heightMM, contentMode: .fit)
        .accessibilityLabel("\(number)페이지, \(page.paper.title)\(page.date.map { ", \($0.readingLabel)" } ?? "")")
        .accessibilityValue(isBookmarked ? "책갈피 있음" : "책갈피 없음")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("선택하여 이 페이지의 책갈피를 관리합니다")
        .accessibilityIdentifier("reading-page-\(number)")
    }
}

/// 제본은 외형만 바꿉니다. 빈 슬롯은 실제 페이지로 만들거나 번호를 붙이지 않습니다.
struct DiaryReadingBook: View {
    let document: DiaryDocument
    let indices: [Int]
    let spread: Bool
    let selectedID: UUID?
    var inkRefresh: Int = 0
    let select: (UUID) -> Void

    var body: some View {
        GeometryReader { geometry in
            let ratios = indices.map { document.pages[$0].widthMM / document.pages[$0].heightMM }
            let fallback = ratios.first ?? (210.0 / 297.0)
            let ratio = ratios.reduce(0, +) + (spread && indices.count == 1 ? fallback : 0)
            let height = max(1, min(geometry.size.height - 36, (geometry.size.width - 48) / max(ratio, 0.1)))
            let width = height * ratio
            HStack(spacing: 10) {
                ForEach(indices, id: \.self) { index in
                    let page = document.pages[index]
                    DiaryReadingPaper(page: page, inkRefresh: inkRefresh, number: index + 1,
                                      isSelected: selectedID == page.id,
                                      isBookmarked: document.bookmarks.contains(page.id)) {
                        select(page.id)
                    }
                    .frame(width: height * (page.widthMM / page.heightMM), height: height)
                }
                if spread && indices.count == 1 {
                    Color.clear.frame(width: height * fallback, height: height)
                        .accessibilityHidden(true)
                }
            }
            .padding(12)
            .background {
                ReadingBookCover(binding: document.options.binding, color: document.options.coverColor)
            }
            .overlay(alignment: spread ? .center : .leading) {
                ReadingBookSpine(binding: document.options.binding)
                    .frame(width: 34, height: height)
                    .offset(x: spread ? 0 : -6)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .frame(width: width + 34, height: height + 24)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

private struct ReadingBookCover: View {
    let binding: DiaryBinding
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: binding == .hardcover ? 7 : 11)
            .fill(color.gradient)
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(.black.opacity(binding == .hardcover ? 0.22 : 0.08), lineWidth: 2)
            }
            .background {
                RoundedRectangle(cornerRadius: 5)
                    .fill(FolinaTheme.Palette.paperEdge)
                    .padding(.horizontal, 5)
                    .offset(y: binding == .hardcover ? 7 : 4)
            }
            .shadow(color: FolinaTheme.Palette.ink.opacity(0.18), radius: 12, x: 2, y: 12)
    }
}

private struct ReadingBookSpine: View {
    let binding: DiaryBinding
    private var rings: Bool { binding == .ringBinder || binding == .spiral }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(colors: [.black.opacity(rings ? 0.12 : 0.18),
                                               .white.opacity(0.7), .black.opacity(0.12)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: rings ? 16 : (binding == .hardcover ? 12 : 6))
            if rings {
                RoundedRectangle(cornerRadius: 3)
                    .fill(FolinaTheme.Palette.steel.gradient).frame(width: 7)
                VStack(spacing: 0) {
                    ForEach(0..<7) { _ in
                        MetalBinderRing().frame(maxHeight: .infinity)
                    }
                }
                .padding(.vertical, 20)
            }
        }
    }
}

extension DiaryDate {
    var readingLabel: String { String(format: "%04d-%02d-%02d", year, month, day) }
}

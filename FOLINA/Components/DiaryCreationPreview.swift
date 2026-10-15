import SwiftUI

/// Figma v5의 펼친 다이어리 구도. 크기는 화면 내 비율이며 실제 용지 규격이 아닙니다.
struct DiaryCreationPreview: View {
    let draft: DiaryDraft

    private var bookHeight: CGFloat { draft.orientation == .portrait ? 332 : 215 }

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 560, geometry.size.height / (bookHeight + 40))
            spread
                .frame(width: 529, height: bookHeight)
                .scaleEffect(scale)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("다이어리 미리보기")
        .accessibilityValue("\(draft.displayName) · \(draft.selectionDescription)")
        .accessibilityIdentifier("creation-preview")
    }

    private var spread: some View {
        ZStack {
            RoundedRectangle(cornerRadius: draft.binding == .hardcover ? 6 : 11)
                .fill(draft.coverColor.gradient)
                .overlay {
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(.white.opacity(0.4), lineWidth: 1)
                }
                .shadow(color: FolinaTheme.Palette.ink.opacity(0.22), radius: 12, x: 2, y: 14)
            RoundedRectangle(cornerRadius: 5)
                .fill(FolinaTheme.Palette.paperEdge)
                .frame(width: 495, height: bookHeight - 25)
                .offset(y: 9)
                .overlay(alignment: .bottom) {
                    ForEach(0..<4) { index in
                        Rectangle().fill(.black.opacity(0.07))
                            .frame(width: 488, height: 0.5)
                            .offset(y: CGFloat(index) * -2 + 8)
                    }
                }
            HStack(spacing: 10) {
                PreviewPaper(pattern: draft.paper)
                PreviewPaper(pattern: draft.paper)
            }
            .frame(width: 495, height: bookHeight - 25)
            .offset(y: -4)
            gutter
            if draft.binding == .ringBinder {
                VStack(spacing: 0) {
                    ForEach(0..<7) { _ in
                        MetalBinderRing().frame(maxHeight: .infinity)
                    }
                }
                .padding(.vertical, 28)
            } else if draft.binding == .hardcover {
                Rectangle()
                    .fill(FolinaTheme.Palette.spine.gradient)
                    .frame(width: 6, height: bookHeight - 30)
                    .offset(x: 9, y: 10)
            }
        }
    }

    private var gutter: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(LinearGradient(colors: [.black.opacity(0.12), .white.opacity(0.8), .black.opacity(0.17)],
                                 startPoint: .leading, endPoint: .trailing))
            .frame(width: draft.binding == .ringBinder ? 16 : 9, height: bookHeight - 27)
            .overlay {
                if draft.binding == .ringBinder {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(FolinaTheme.Palette.steel.gradient)
                        .frame(width: 8, height: bookHeight - 55)
                }
            }
    }
}

private struct PreviewPaper: View {
    let pattern: DiaryPaper

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(red: 1, green: 0.996, blue: 0.984))
            .overlay {
                Canvas { context, size in
                    let inset: CGFloat = 17
                    let step: CGFloat = 15
                    var marks = Path()
                    if pattern == .lined || pattern == .grid {
                        for y in stride(from: inset, through: size.height - inset, by: step) {
                            marks.move(to: CGPoint(x: inset, y: y))
                            marks.addLine(to: CGPoint(x: size.width - inset, y: y))
                        }
                    }
                    if pattern == .grid {
                        for x in stride(from: inset, through: size.width - inset, by: step) {
                            marks.move(to: CGPoint(x: x, y: inset))
                            marks.addLine(to: CGPoint(x: x, y: size.height - inset))
                        }
                    }
                    if pattern == .dotted {
                        for x in stride(from: inset, through: size.width - inset, by: step) {
                            for y in stride(from: inset, through: size.height - inset, by: step) {
                                marks.addEllipse(in: CGRect(x: x, y: y, width: 1.5, height: 1.5))
                            }
                        }
                        context.fill(marks, with: .color(FolinaTheme.Palette.spine.opacity(0.45)))
                    } else {
                        context.stroke(marks, with: .color(FolinaTheme.Palette.spine.opacity(0.25)), lineWidth: 0.6)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .shadow(color: .black.opacity(0.06), radius: 1, y: 1)
    }
}

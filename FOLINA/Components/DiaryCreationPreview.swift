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

    @ViewBuilder
    private var spread: some View {
        if draft.binding == .hardcover {
            hardcoverSpread
        } else {
            standardSpread
        }
    }

    private var standardSpread: some View {
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
                standardPage(isLeft: true)
                standardPage(isLeft: false)
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
            }
        }
    }

    private func standardPage(isLeft: Bool) -> some View {
        let depth = 0.12
        return PreviewPaper(pattern: draft.paper)
            .overlay {
                LinearGradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.55),
                    .init(color: .white.opacity(0.18), location: 0.73),
                    .init(color: .black.opacity(depth * 0.2), location: 0.88),
                    .init(color: .black.opacity(depth), location: 1)
                ], startPoint: isLeft ? .leading : .trailing,
                   endPoint: isLeft ? .trailing : .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    /// 양쪽 보드·면지·곡면 종이를 분리해 일반 제본보다 단단한 두께를 표현합니다.
    private var hardcoverSpread: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(draft.coverColor.gradient)
                .frame(height: bookHeight - 2)
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(.black.opacity(0.22), lineWidth: 1)
                }
                .offset(y: 5)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 2, y: 13)

            HStack(spacing: 8) {
                hardcoverBoard
                hardcoverBoard
            }
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [draft.coverColor, .black.opacity(0.32), draft.coverColor],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 20, height: bookHeight - 4)

            HStack(spacing: 5) {
                hardcoverPage(isLeft: true)
                hardcoverPage(isLeft: false)
            }
            .frame(width: 491, height: bookHeight - 32)
            .offset(y: -5)
            hardcoverRibbon
        }
    }

    private var hardcoverRibbon: some View {
        SatinBookmarkShape()
            .fill(LinearGradient(stops: [
                .init(color: FolinaTheme.Palette.spine, location: 0),
                .init(color: FolinaTheme.Palette.slateBlue, location: 0.3),
                .init(color: .white.opacity(0.95), location: 0.45),
                .init(color: FolinaTheme.Palette.slateBlue, location: 0.6),
                .init(color: FolinaTheme.Palette.spine, location: 1)
            ], startPoint: .leading, endPoint: .trailing))
            .overlay {
                SatinBookmarkShape()
                    .stroke(.white.opacity(0.45), lineWidth: 0.5)
            }
            .overlay {
                // 아래쪽이 살짝 들린 접힘. 광택 띠와 구분되는 부드러운 가로 음영입니다.
                LinearGradient(colors: [.clear, .black.opacity(0.2), .white.opacity(0.25), .clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 14)
                    .offset(y: (bookHeight - 5) / 2 - 29)
                    .mask(SatinBookmarkShape())
            }
            .frame(width: 30, height: bookHeight - 5)
            .shadow(color: .black.opacity(0.2), radius: 1.8, x: 2, y: 2)
            .offset(x: 20, y: 15)
            .accessibilityHidden(true)
    }

    private var hardcoverBoard: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(draft.coverColor)
            .overlay {
                LinearGradient(colors: [.white.opacity(0.26), .clear, .black.opacity(0.16)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(.white.opacity(0.3), lineWidth: 0.8)
                    .padding(2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .shadow(color: .black.opacity(0.18), radius: 1, y: 3)
    }

    private func hardcoverPage(isLeft: Bool) -> some View {
        ZStack {
            // 단면을 두 덩어리로 나눠 책등까지 한 장처럼 붙어 보이지 않게 합니다.
            ForEach(0..<5) { index in
                HardcoverPageShape(isLeft: isLeft)
                    .fill(FolinaTheme.Palette.paperEdge)
                    .overlay {
                        HardcoverPageShape(isLeft: isLeft)
                            .stroke(.black.opacity(0.08), lineWidth: 0.5)
                    }
                    .offset(x: isLeft ? -0.4 : 0.4, y: CGFloat(5 - index) * 1.5)
            }
            PreviewPaper(pattern: draft.paper)
                .overlay {
                    LinearGradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.25), location: 0.72),
                        .init(color: .black.opacity(0.04), location: 0.9),
                        .init(color: .black.opacity(0.19), location: 1)
                    ], startPoint: isLeft ? .leading : .trailing,
                       endPoint: isLeft ? .trailing : .leading)
                }
                .clipShape(HardcoverPageShape(isLeft: isLeft))
                .shadow(color: .black.opacity(0.1), radius: 2, x: isLeft ? -1 : 1, y: 2)
        }
    }

    private var gutter: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(LinearGradient(colors: [.black.opacity(0.12), .white.opacity(0.8), .black.opacity(0.17)],
                                 startPoint: .leading, endPoint: .trailing))
            .opacity(draft.binding == .softcover ? 0.8 : 1)
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

/// 면지의 위·아래 곡선과 중앙으로 내려앉는 안쪽 모서리.
private struct HardcoverPageShape: Shape {
    let isLeft: Bool

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 5))
        path.addQuadCurve(to: CGPoint(x: 5, y: 0), control: .zero)
        path.addCurve(to: CGPoint(x: w, y: 8),
                      control1: CGPoint(x: w * 0.55, y: -2),
                      control2: CGPoint(x: w - 15, y: 1))
        path.addLine(to: CGPoint(x: w, y: h - 4))
        path.addCurve(to: CGPoint(x: 5, y: h),
                      control1: CGPoint(x: w - 18, y: h - 12),
                      control2: CGPoint(x: w * 0.5, y: h))
        path.addQuadCurve(to: CGPoint(x: 0, y: h - 5), control: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return isLeft ? path : path.applying(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: w, ty: 0))
    }
}

/// 안쪽 책등에서 시작해 종이 위로 흐르는 띠와 V자 꼬리.
private struct SatinBookmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: 2, y: 0))
        path.addLine(to: CGPoint(x: 12, y: 0))
        path.addCurve(to: CGPoint(x: 28, y: h),
                      control1: CGPoint(x: 10, y: h * 0.35),
                      control2: CGPoint(x: 12, y: h * 0.72))
        path.addLine(to: CGPoint(x: 20, y: h - 7))
        path.addLine(to: CGPoint(x: 15, y: h + 1))
        path.addCurve(to: CGPoint(x: 2, y: 0),
                      control1: CGPoint(x: 0, y: h * 0.73),
                      control2: CGPoint(x: 1, y: h * 0.33))
        path.closeSubpath()
        return path
    }
}

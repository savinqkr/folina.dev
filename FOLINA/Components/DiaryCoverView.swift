import SwiftUI

/// 표지·종이 단면·제본을 겹쳐 그립니다. 이미지 다운로드 없이 같은 외형을 유지합니다.
struct DiaryCoverView: View {
    let diary: DiarySummary

    private var coverColor: Color { diary.cover.tone.color }

    private var isBinder: Bool { diary.cover.binding == .ringBinder }
    private var isHardcover: Bool { diary.cover.binding == .hardcover }
    private var corner: CGFloat { diary.cover.design == .leatherWrap ? 9 : (isHardcover ? 5 : 9) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 바닥에 닿는 그림자와 떨어진 부분의 부드러운 그림자를 나눕니다.
            RoundedRectangle(cornerRadius: corner)
                .fill(FolinaTheme.Palette.ink.opacity(0.18))
                .frame(width: 174, height: 261)
                .blur(radius: 8)
                .offset(x: 12, y: 16)

            book
                .rotation3DEffect(.degrees(-11), axis: (x: 0, y: 1, z: 0),
                                  anchor: .leading, perspective: 0.22)
                .rotationEffect(.degrees(isBinder ? -2 : (isHardcover ? 1 : -1)), anchor: .bottom)
                .offset(x: 5, y: 2)
        }
        // 원근·링·종이 단면까지 카드 안에 들어가는 여백입니다.
        .frame(width: 192, height: 287, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    private var book: some View {
        ZStack(alignment: .topLeading) {
            // 두께를 받치는 뒷표지입니다.
            RoundedRectangle(cornerRadius: corner)
                .fill(coverColor.gradient)
                .overlay {
                    RoundedRectangle(cornerRadius: corner)
                        .strokeBorder(FolinaTheme.Palette.ink.opacity(0.22), lineWidth: 0.8)
                }
                .frame(width: 180, height: 269)
                .offset(x: 8, y: 11)

            paperBlock

            if isHardcover { ribbon }

            frontCover
            bindingDecoration
            coverTitle
            DiaryCoverDecoration(design: diary.cover.design, color: coverColor)

            if diary.cover.binding == .softcover && diary.cover.design == .classic {
                elasticBand
            }
        }
        .frame(width: 188, height: 280, alignment: .topLeading)
    }

    private var paperBlock: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(LinearGradient(colors: [Color.white, FolinaTheme.Palette.paperEdge,
                                          Color.white, FolinaTheme.Palette.paperEdge],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Canvas { context, size in
                    var lines = Path()
                    // 오른쪽에는 낱장 단면, 아래에는 겹친 종이의 가로선을 그립니다.
                    for x in stride(from: CGFloat(0), through: size.width, by: 1.7) {
                        lines.move(to: CGPoint(x: x, y: 0))
                        lines.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    for y in stride(from: size.height - 14, through: size.height, by: 1.7) {
                        lines.move(to: CGPoint(x: 0, y: y))
                        lines.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(lines, with: .color(.black.opacity(0.12)), lineWidth: 0.45)
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(.black.opacity(0.12), lineWidth: 0.6)
            }
            .frame(width: 175, height: 260)
            .offset(x: 10, y: 13)
    }

    private var frontCover: some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(coverColor)
            .overlay {
                LinearGradient(stops: [
                    .init(color: .white.opacity(0.34), location: 0),
                    .init(color: .white.opacity(0.04), location: 0.12),
                    .init(color: .black.opacity(0.07), location: 0.19),
                    .init(color: .clear, location: 0.26),
                    .init(color: .white.opacity(0.12), location: 0.66),
                    .init(color: .black.opacity(0.12), location: 1)
                ], startPoint: .leading, endPoint: .trailing)
            }
            .overlay { CoverMaterial(isCloth: isHardcover && diary.cover.design != .leatherWrap) }
            .clipShape(RoundedRectangle(cornerRadius: corner))
            .overlay {
                RoundedRectangle(cornerRadius: corner)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.65), .clear,
                                                          .black.opacity(0.18)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing),
                                  lineWidth: 1)
            }
            .frame(width: 180, height: 269)
            .shadow(color: .black.opacity(0.14), radius: 1.2, x: 2, y: 2)
    }

    @ViewBuilder
    private var bindingDecoration: some View {
        if isBinder {
            binderRings
        } else if diary.cover.binding == .spiral {
            spiralBinding
        } else {
            // 천 제본의 책등과 표지에 눌린 홈입니다.
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [coverColor, (diary.cover.design == .leatherWrap ? Color.black.opacity(0.25)
                                               : FolinaTheme.Palette.spine.opacity(0.6)),
                                              coverColor, .black.opacity(0.15)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: isHardcover ? 20 : 13, height: 268)
            Rectangle()
                .fill(.black.opacity(0.13))
                .frame(width: 1, height: 257)
                .shadow(color: .white.opacity(0.7), radius: 0.6, x: 1, y: 0)
                .offset(x: isHardcover ? 23 : 16, y: 6)
        }
    }

    private var spiralBinding: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(.black.opacity(0.12))
                .frame(width: 9, height: 252)
                .offset(x: 2, y: 8)
            ForEach(0..<13, id: \.self) { index in
                ZStack {
                    Capsule().fill(.black.opacity(0.4)).frame(width: 5, height: 7).offset(x: 7)
                    Ellipse()
                        .stroke(LinearGradient(colors: [.black.opacity(0.6), .white,
                                                       FolinaTheme.Palette.spine],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2.5)
                        .frame(width: 18, height: 9)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 1, y: 2)
                }
                .frame(width: 22, height: 12)
                .offset(x: -9, y: 14 + CGFloat(index) * 19)
            }
        }
    }

    private var binderRings: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(colors: [.black.opacity(0.15), .white.opacity(0.15),
                                              .black.opacity(0.12)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 15, height: 249)
                .offset(x: 3, y: 10)
            ForEach(0..<6, id: \.self) { index in
                MetalBinderRing().offset(x: -9, y: 29 + CGFloat(index) * 40)
            }
        }
    }

    @ViewBuilder
    private var coverTitle: some View {
        if isBinder {
            VStack(alignment: .leading, spacing: 12) {
                Text("PERSONAL JOURNAL").font(.system(size: 7, weight: .medium)).tracking(1.1)
                Text(diary.title)
                    .font(FolinaTheme.Typography.handwrittenCover)
                    .fixedSize(horizontal: false, vertical: true)
                Rectangle().fill(FolinaTheme.Palette.ink.opacity(0.2)).frame(height: 0.6)
                Text("VOL. 01  /  2026").font(.system(size: 8)).tracking(0.6)
            }
            .foregroundStyle(FolinaTheme.Palette.ink.opacity(0.8))
            .padding(14)
            .frame(width: 126, alignment: .leading)
            .background(Color(white: 0.97), in: RoundedRectangle(cornerRadius: 2))
            .overlay {
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(.black.opacity(0.09), lineWidth: 0.7)
            }
            .shadow(color: .black.opacity(0.13), radius: 1, x: 0.5, y: 1.5)
            .offset(x: 34, y: 62)
        } else if diary.cover.design == .classic && diary.cover.binding != .spiral {
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(FolinaTheme.Palette.ink.opacity(0.12), lineWidth: 0.6)
                .frame(width: 132, height: 224)
                .offset(x: 32, y: 21)
        }
    }

    private var ribbon: some View {
        UnevenRoundedRectangle(bottomLeadingRadius: 1, bottomTrailingRadius: 4)
            .fill(LinearGradient(colors: [FolinaTheme.Palette.spine, coverColor,
                                          FolinaTheme.Palette.spine],
                                 startPoint: .leading, endPoint: .trailing))
            .frame(width: 10, height: 28)
            .rotationEffect(.degrees(-7), anchor: .top)
            .offset(x: 131, y: 251)
    }

    private var elasticBand: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(LinearGradient(colors: [FolinaTheme.Palette.softSpine,
                                          FolinaTheme.Palette.rose,
                                          FolinaTheme.Palette.softSpine],
                                 startPoint: .leading, endPoint: .trailing))
            .frame(width: 7, height: 270)
            .shadow(color: .black.opacity(0.2), radius: 1, x: 1.5, y: 0)
            .offset(x: 160, y: 0)
    }
}

/// 좌표로 결정하는 은은한 종이·천 재질입니다. 다시 그려도 무늬가 바뀌지 않습니다.
private struct CoverMaterial: View {
    let isCloth: Bool

    var body: some View {
        Canvas { context, size in
            if isCloth {
                var weave = Path()
                for x in stride(from: CGFloat(0), through: size.width, by: 2.5) {
                    weave.move(to: CGPoint(x: x, y: 0))
                    weave.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: CGFloat(0), through: size.height, by: 3) {
                    weave.move(to: CGPoint(x: 0, y: y))
                    weave.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(weave, with: .color(.white.opacity(0.1)), lineWidth: 0.5)
            }
            for index in 0..<600 {
                let x = CGFloat((index * 73 + 19) % 997) / 997 * size.width
                let y = CGFloat((index * 137 + 41) % 991) / 991 * size.height
                let grain = Path(ellipseIn: CGRect(x: x, y: y, width: 0.7, height: 0.7))
                context.fill(grain, with: .color(index.isMultiple(of: 2)
                                               ? .white.opacity(0.13) : .black.opacity(0.05)))
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview("제본별 입체 표지") {
    HStack(spacing: 30) {
        ForEach(SampleDiaries.bookshelf) { diary in
            DiaryCoverView(diary: diary)
        }
    }
    .padding(30)
    .background(FolinaTheme.Palette.collection)
}

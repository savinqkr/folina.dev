import SwiftUI

/// 표지·종이 단면·제본을 겹쳐 그립니다. 이미지 다운로드 없이 같은 외형을 유지합니다.
struct DiaryCoverView: View {
    let diary: DiarySummary

    private var coverColor: Color {
        switch diary.cover.tone {
        case .sage: FolinaTheme.Palette.sage
        case .slateBlue: FolinaTheme.Palette.slateBlue
        case .rose: FolinaTheme.Palette.rose
        }
    }

    private var isBinder: Bool { diary.cover.binding == .ringBinder }
    private var isHardcover: Bool { diary.cover.binding == .hardcover }
    private var corner: CGFloat { isHardcover ? 5 : 9 }

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

            if diary.cover.binding == .softcover { elasticBand }
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
            .overlay { CoverMaterial(isCloth: isHardcover) }
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
        } else {
            // 천 제본의 책등과 표지에 눌린 홈입니다.
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [coverColor, FolinaTheme.Palette.spine.opacity(0.6),
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

    private var binderRings: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(colors: [.black.opacity(0.15), .white.opacity(0.15),
                                              .black.opacity(0.12)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 15, height: 249)
                .offset(x: 3, y: 10)
            ForEach(0..<6, id: \.self) { index in
                metalRing.offset(x: -9, y: 29 + CGFloat(index) * 40)
            }
        }
    }

    private var metalRing: some View {
        ZStack {
            // 구멍 안쪽과 금속이 닿는 부분의 그림자입니다.
            Capsule().fill(.black.opacity(0.38)).frame(width: 7, height: 11).offset(x: 10)
            Ellipse()
                .stroke(.black.opacity(0.24), lineWidth: 4)
                .frame(width: 28, height: 12)
                .blur(radius: 1)
                .offset(x: 1, y: 3)
            Ellipse()
                .stroke(LinearGradient(stops: [
                    .init(color: Color(white: 0.38), location: 0),
                    .init(color: .white, location: 0.24),
                    .init(color: Color(white: 0.67), location: 0.48),
                    .init(color: Color(white: 0.91), location: 0.67),
                    .init(color: Color(white: 0.32), location: 1)
                ], startPoint: .top, endPoint: .bottom), lineWidth: 3.6)
                .frame(width: 28, height: 12)
            Ellipse()
                .trim(from: 0.52, to: 0.94)
                .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                .frame(width: 27, height: 11)
        }
        .frame(width: 32, height: 18)
    }

    @ViewBuilder
    private var coverTitle: some View {
        if isBinder {
            VStack(alignment: .leading, spacing: 12) {
                Text("PERSONAL JOURNAL").font(.system(size: 7, weight: .medium)).tracking(1.1)
                Text(diary.title)
                    .font(.system(size: 19, weight: .medium, design: .serif))
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
        } else {
            VStack(spacing: 17) {
                Text(isHardcover ? "D A I L Y   N O T E S" : "M Y   J O U R N A L")
                    .font(.system(size: 7, weight: .medium))
                Rectangle().fill(FolinaTheme.Palette.ink.opacity(0.24)).frame(width: 30, height: 0.7)
                Text(diary.title)
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("2 0 2 6").font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(FolinaTheme.Palette.ink.opacity(0.7))
            .shadow(color: .white.opacity(0.6), radius: 0.3, x: 0, y: 1)
            .frame(width: 130)
            .offset(x: 32, y: 65)

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

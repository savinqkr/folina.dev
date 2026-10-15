import SwiftUI

/// 제목 없이 재질과 장식만으로 구분하는 추가 표지 디자인.
struct DiaryCoverDecoration: View {
    let design: DiaryCoverDesign
    let color: Color

    @ViewBuilder
    var body: some View {
        switch design {
        case .classic:
            EmptyView()
        case .leatherWrap:
            leatherWrap
        case .botanicalWindow:
            botanicalWindow
        case .kraft:
            kraftPocket
        }
    }

    private var leatherWrap: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 5)
                .stroke(.white.opacity(0.4), style: StrokeStyle(lineWidth: 0.7, dash: [2, 3]))
                .frame(width: 164, height: 250)
                .offset(x: 8, y: 9)
            RoundedRectangle(cornerRadius: 9)
                .fill(color)
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(LinearGradient(colors: [.clear, .clear, .black.opacity(0.12)],
                                             startPoint: .top, endPoint: .bottom))
                }
                .frame(width: 66, height: 54)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.white.opacity(0.35), style: StrokeStyle(lineWidth: 0.7, dash: [2, 3]))
                        .padding(5)
                }
                .shadow(color: .black.opacity(0.16), radius: 2, x: -1, y: 3)
                .offset(x: 119, y: 107)
            Circle()
                .fill(LinearGradient(colors: [Color(white: 0.85), FolinaTheme.Palette.kraft,
                                              FolinaTheme.Palette.cocoa],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay { Circle().fill(.white.opacity(0.12)) }
                .overlay { Circle().strokeBorder(.white.opacity(0.45), lineWidth: 0.7) }
                .frame(width: 13, height: 13)
                .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                .offset(x: 133, y: 127)
        }
        .frame(width: 188, height: 269, alignment: .topLeading)
    }

    private var botanicalWindow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(FolinaTheme.Palette.ink.opacity(0.14))
                .frame(width: 111, height: 153)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(white: 0.97))
                .frame(width: 103, height: 145)
                .overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(.black.opacity(0.14), lineWidth: 1)
                }
            Capsule()
                .fill(FolinaTheme.Palette.spine.opacity(0.65))
                .frame(width: 1.4, height: 85)
                .rotationEffect(.degrees(18))
            ForEach(0..<4, id: \.self) { index in
                Ellipse()
                    .fill(LinearGradient(colors: [FolinaTheme.Palette.sage,
                                                  FolinaTheme.Palette.spine.opacity(0.6)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 13, height: 30)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -45 : 45))
                    .offset(x: index.isMultiple(of: 2) ? -7 : 7,
                            y: CGFloat(index) * 17 - 28)
            }
        }
        .frame(width: 111, height: 153)
        .offset(x: 41, y: 49)
    }

    private var kraftPocket: some View {
        ZStack(alignment: .topLeading) {
            // 끼워 둔 무지 메모지와 접힌 종이 포켓.
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(white: 0.96))
                .frame(width: 88, height: 107)
                .rotationEffect(.degrees(-6))
                .shadow(color: .black.opacity(0.12), radius: 1, y: 2)
                .offset(x: 46, y: 76)
            Rectangle()
                .fill(FolinaTheme.Palette.sage.opacity(0.85))
                .frame(width: 47, height: 15)
                .rotationEffect(.degrees(-11))
                .offset(x: 66, y: 70)
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(colors: [.white.opacity(0.18), .clear, .black.opacity(0.1)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .frame(width: 126, height: 90)
                .overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(.black.opacity(0.12), lineWidth: 0.7)
                }
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0.5, y: 2)
                .offset(x: 32, y: 147)
            Path { path in
                path.move(to: CGPoint(x: 33, y: 148))
                path.addLine(to: CGPoint(x: 95, y: 186))
                path.addLine(to: CGPoint(x: 157, y: 148))
            }
            .stroke(.black.opacity(0.12), lineWidth: 0.7)
        }
        .frame(width: 180, height: 269, alignment: .topLeading)
    }
}

import SwiftUI

/// 책장 표지와 생성 미리보기에서 공유하는 금속 링.
struct MetalBinderRing: View {
    var body: some View {
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
}

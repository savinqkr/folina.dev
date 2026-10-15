import SwiftUI

struct BookshelfSidebar: View {
    @Binding var isExpanded: Bool
    @State private var noticeTitle = ""
    @State private var showsNotice = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sidebar.left")
                            .frame(width: 20)
                        if isExpanded {
                            Text("메뉴 접기")
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                    }
                    .font(FolinaTheme.Typography.body)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: isExpanded ? .leading : .center)
                    .padding(.horizontal, isExpanded ? 12 : 0)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(FolinaTheme.Palette.secondary)
                .accessibilityLabel(isExpanded ? "사이드바 접기" : "사이드바 펼치기")
                .accessibilityValue(isExpanded ? "펼쳐짐" : "접힘")
                .accessibilityIdentifier("sidebar-toggle")

                ForEach(Menu.allCases) { menu in
                    Button {
                        if menu != .diaries {
                            noticeTitle = menu.title
                            showsNotice = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: menu.symbol)
                                .font(.system(size: 18, weight: .regular))
                                .frame(width: 20)
                            if isExpanded {
                                Text(menu.title)
                                    .font(FolinaTheme.Typography.body)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: isExpanded ? .leading : .center)
                        .padding(.horizontal, isExpanded ? 12 : 0)
                        .foregroundStyle(menu == .diaries ? FolinaTheme.Palette.ink : FolinaTheme.Palette.secondary)
                        .background(menu == .diaries ? FolinaTheme.Palette.selection : .clear,
                                    in: RoundedRectangle(cornerRadius: 7))
                        .contentShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(menu.title)
                    .accessibilityHint(menu == .diaries ? "현재 화면" : "준비 중인 메뉴")
                    .accessibilityAddTraits(menu == .diaries ? .isSelected : [])
                    .accessibilityIdentifier("sidebar-\(menu.rawValue)")
                    .help(menu.title)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 24)
        }
        .frame(width: isExpanded ? 208 : 68)
        .background(FolinaTheme.Palette.surface)
        .overlay(alignment: .trailing) {
            Rectangle().fill(FolinaTheme.Palette.border).frame(width: 1)
        }
        .alert(noticeTitle, isPresented: $showsNotice) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("이 메뉴는 준비 중이에요.")
        }
    }

    private enum Menu: String, CaseIterable, Identifiable {
        case diaries, freeGoods, myGoods, market, settings
        var id: String { rawValue }
        var title: String {
            switch self {
            case .diaries: "내 다이어리"
            case .freeGoods: "무료 굿즈"
            case .myGoods: "내 굿즈"
            case .market: "마켓"
            case .settings: "설정"
            }
        }
        var symbol: String {
            switch self {
            case .diaries: "books.vertical"
            case .freeGoods: "gift"
            case .myGoods: "square.stack"
            case .market: "bag"
            case .settings: "gearshape"
            }
        }
    }
}

import SwiftUI

struct DiaryCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft = DiaryDraft()
    @State private var showsStorageNotice = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                FolinaHeader(section: "CREATE")
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        introduction
                        if geometry.size.width >= 900 {
                            HStack(alignment: .top, spacing: 21) {
                                settings.frame(width: (geometry.size.width - 91) * 0.455)
                                previewPanel.frame(maxWidth: .infinity)
                            }
                        } else {
                            VStack(spacing: 24) {
                                previewPanel
                                settings
                            }
                        }
                    }
                    .padding(.horizontal, geometry.size.width >= 600 ? FolinaTheme.Spacing.page : 16)
                    .padding(.vertical, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .background(FolinaTheme.Palette.canvas)
        .foregroundStyle(FolinaTheme.Palette.ink)
        .preferredColorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("diary-creation")
        .alert("저장 기능 준비 중", isPresented: $showsStorageNotice) {
            Button("계속 꾸미기", role: .cancel) { }
        } message: {
            Text("현재는 미리보기만 제공해요. 다이어리는 생성되거나 저장되지 않으며 책장에 추가되지 않아요.")
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                dismiss()
            } label: {
                Label("책장으로 돌아가기", systemImage: "chevron.left")
                    .font(FolinaTheme.Typography.body)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("creation-back")
            Text("새 다이어리 만들기")
                .font(FolinaTheme.Typography.title)
                .accessibilityAddTraits(.isHeader)
            Text("나만의 기록 방식과 다이어리 외형을 조합해 보세요.")
                .font(FolinaTheme.Typography.body)
                .foregroundStyle(FolinaTheme.Palette.secondary)
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                Text("다이어리 이름").font(FolinaTheme.Typography.label)
                TextField("나의 다이어리", text: $draft.name)
                    .font(FolinaTheme.Typography.body)
                    .padding(12)
                    .background(FolinaTheme.Palette.canvas, in: RoundedRectangle(cornerRadius: 8))
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit { isNameFocused = false }
                    .accessibilityLabel("다이어리 이름")
                    .accessibilityIdentifier("diary-name")
            }
            DiaryOptionPicker(title: "기록 방식", options: DiaryKind.allCases,
                              selection: $draft.kind, identifier: "kind") { Text($0.title) }
            DiaryOptionPicker(title: "다이어리 외형", options: DiaryBinding.creationOptions,
                              selection: $draft.binding, identifier: "binding") { Text($0.title) }
            DiaryCoverColorPicker(draft: $draft)
            DiaryOptionPicker(title: "표지 스타일", options: CreationCoverStyle.allCases,
                              selection: $draft.coverStyle, identifier: "cover") { Text($0.title) }
            DiaryOptionPicker(title: "속지", options: DiaryPaper.allCases,
                              selection: $draft.paper, identifier: "paper") { Text($0.title) }
            DiaryOptionPicker(title: "페이지 방향", options: DiaryOrientation.allCases,
                              selection: $draft.orientation, identifier: "orientation") { Text($0.title) }
        }
        .padding(24)
        .background(FolinaTheme.Palette.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private var previewPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("실시간 미리보기")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(draft.selectionDescription)
                .font(FolinaTheme.Typography.caption)
                .foregroundStyle(FolinaTheme.Palette.secondary)
                .accessibilityIdentifier("preview-selection")
            DiaryCreationPreview(draft: draft)
                .frame(height: 350)
            HStack(spacing: 18) {
                DiaryCoverView(diary: draft.previewSummary)
                    .scaleEffect(x: draft.orientation == .landscape ? 0.48 : 0.36,
                                 y: draft.orientation == .landscape ? 0.25 : 0.36)
                    .frame(width: 100, height: 110)
                VStack(alignment: .leading, spacing: 8) {
                    Text(draft.displayName).font(FolinaTheme.Typography.label).lineLimit(3)
                    Text("표지 미리보기 · \(draft.coverStyle.title)")
                        .font(FolinaTheme.Typography.caption)
                        .foregroundStyle(FolinaTheme.Palette.secondary)
                }
            }
            Text("외형을 바꿔도 선택한 기록 방식과 속지는 유지돼요.")
                .font(FolinaTheme.Typography.caption)
                .foregroundStyle(FolinaTheme.Palette.secondary)
            Divider()
            Text("지금은 미리보기 단계예요. 저장하거나 책장에 추가하지 않아요. 뒤로 가면 선택 내용은 초기화돼요.")
                .font(FolinaTheme.Typography.body)
                .fixedSize(horizontal: false, vertical: true)
            Button("다이어리 만들기") {
                showsStorageNotice = true
            }
            .buttonStyle(FolinaPrimaryButtonStyle())
            .accessibilityIdentifier("creation-submit")
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(24)
        .background(FolinaTheme.Palette.collection, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview("새 다이어리 만들기") {
    NavigationStack { DiaryCreationView() }
}

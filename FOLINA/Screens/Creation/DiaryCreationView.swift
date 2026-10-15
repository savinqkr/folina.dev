import SwiftUI

struct DiaryCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft = DiaryDraft()
    @Environment(DiaryLibrary.self) private var library
    @State private var creation = DiaryCreationController()
    @FocusState private var isNameFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                FolinaHeader()
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        introduction
                        if geometry.size.width >= 900 {
                            CreationPanelColumns {
                                settings
                                previewPanel
                            }
                        } else {
                            VStack(spacing: 24) {
                                previewPanel
                                settings
                            }
                        }
                    }
                    .padding(.horizontal, FolinaTheme.Spacing.horizontalPage(width: geometry.size.width))
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
        .disabled(creation.isSaving || creation.hasCreated)
        .alert("생성 실패", isPresented: Binding(
            get: { creation.errorMessage != nil },
            set: { if !$0 { creation.errorMessage = nil } })) {
            Button("확인", role: .cancel) { creation.errorMessage = nil }
        } message: {
            Text(creation.errorMessage ?? "")
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
        .frame(maxHeight: .infinity, alignment: .top)
        .background(FolinaTheme.Palette.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private var coverPreviewImage: some View {
        DiaryCoverView(diary: draft.previewSummary)
            .scaleEffect(x: draft.orientation == .landscape ? 0.78 : 0.58,
                         y: draft.orientation == .landscape ? 0.4 : 0.58)
            .frame(width: 150, height: 185)
    }

    private var coverPreviewDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(draft.displayName).font(FolinaTheme.Typography.label).lineLimit(3)
            Text("표지 미리보기 · \(draft.coverStyle.title)")
                .font(FolinaTheme.Typography.caption)
                .foregroundStyle(FolinaTheme.Palette.secondary)
        }
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
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 18) {
                    coverPreviewImage
                    coverPreviewDetails.frame(minWidth: 150, maxWidth: .infinity, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 12) {
                    coverPreviewImage
                    coverPreviewDetails
                }
            }
            Text("외형을 바꿔도 선택한 기록 방식과 속지는 유지돼요.")
                .font(FolinaTheme.Typography.caption)
                .foregroundStyle(FolinaTheme.Palette.secondary)
            Divider()
            Text("A4 크기의 첫 페이지 1개를 만들고 이 기기에 저장해요. 날짜형은 오늘 날짜로 시작해요.")
                .font(FolinaTheme.Typography.body)
                .fixedSize(horizontal: false, vertical: true)
            Button(creation.isSaving ? "저장 중…" : "다이어리 만들기") {
                Task { @MainActor in
                    if await creation.create(draft: draft, library: library) { dismiss() }
                }
            }
            .disabled(!library.isReady || creation.isSaving || creation.hasCreated)
            .buttonStyle(FolinaPrimaryButtonStyle())
            .accessibilityIdentifier("creation-submit")
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(24)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(FolinaTheme.Palette.collection, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview("새 다이어리 만들기") {
    NavigationStack { DiaryCreationView() }.environment(DiaryLibrary())
}

/// 두 패널의 자연스러운 높이를 측정해 긴 쪽에 맞춰 같은 높이를 제안합니다.
private struct CreationPanelColumns: Layout {
    private let spacing: CGFloat = 21
    private let leadingFraction: CGFloat = 0.455

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return .zero }
        let width = proposal.width ?? 900
        let widths = columnWidths(total: width)
        let height = zip(subviews, widths).map { view, columnWidth in
            view.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil)).height
        }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let widths = columnWidths(total: bounds.width)
        subviews[0].place(at: bounds.origin, anchor: .topLeading,
                          proposal: ProposedViewSize(width: widths[0], height: bounds.height))
        subviews[1].place(at: CGPoint(x: bounds.minX + widths[0] + spacing, y: bounds.minY),
                          anchor: .topLeading,
                          proposal: ProposedViewSize(width: widths[1], height: bounds.height))
    }

    private func columnWidths(total: CGFloat) -> [CGFloat] {
        let available = max(0, total - spacing)
        return [available * leadingFraction, available * (1 - leadingFraction)]
    }
}

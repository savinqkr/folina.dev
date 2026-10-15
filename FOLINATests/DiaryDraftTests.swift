import Testing
@testable import FOLINA

struct DiaryDraftTests {
    @Test func appearanceChangesPreserveContentChoices() {
        for kind in DiaryKind.allCases {
            for paper in DiaryPaper.allCases {
                for orientation in DiaryOrientation.allCases {
                    var draft = DiaryDraft()
                    draft.name = "나의 기록"
                    draft.kind = kind
                    draft.paper = paper
                    draft.orientation = orientation
                    for binding in DiaryBinding.creationOptions {
                        for tone in DiaryCoverTone.creationOptions {
                            for style in CreationCoverStyle.allCases {
                                draft.binding = binding
                                draft.tone = tone
                                draft.coverStyle = style
                                #expect(draft.kind == kind)
                                #expect(draft.paper == paper)
                                #expect(draft.orientation == orientation)
                                #expect(draft.name == "나의 기록")
                                #expect(draft.previewSummary.cover.binding == binding)
                                #expect(draft.previewSummary.cover.tone == tone)
                                #expect(draft.previewSummary.cover.design == style.design)
                                #expect(draft.selectionDescription.contains(paper.title))
                                #expect(draft.selectionDescription.contains(orientation.title))
                            }
                        }
                    }
                }
            }
        }
    }

    @Test func nameFallbackDoesNotMutateEnteredName() {
        var draft = DiaryDraft()
        draft.name = " \n "
        #expect(draft.displayName == "나의 다이어리")
        draft.name = "  여행 일기  "
        #expect(draft.previewSummary.title == "여행 일기")
        #expect(draft.name == "  여행 일기  ")
    }

    @Test func creationBindingsDoNotChangeBookshelfStyles() {
        #expect(DiaryBinding.creationOptions == [.ringBinder, .hardcover, .softcover])
        #expect(DiaryBinding.allCases.contains(.spiral))
    }
}

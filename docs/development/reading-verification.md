# 읽기 및 책갈피 검증

- 원본/근거: 4차 개발 요청 · 저장소 코드 및 테스트
- 확인일: 2026-10-16 (한국 시간)
- 문서 상태: 정적 검사 수행 / Xcode 및 수동 검증 미실행

## 이번 환경에서 수행한 검사

- tree-sitter-swift로 Swift 소스 전체 구문 파싱: 통과. 컴파일·타입 검사와 다릅니다.
- Markdown 상대 파일 링크, 에셋 JSON, diff 공백, 기존 Xcode 설정 불변 검사: 통과.
- Linux에 Swift/Xcode/Apple SDK/iPad 시뮬레이터가 없어 앱 빌드·단위/UI 테스트·시각 비교는 미실행입니다.

## 작성한 자동 테스트 — 미실행

| 테스트 | 확인 대상 |
|---|---|
| DiaryReadingPositionTests | 0/1페이지 경계, 5페이지 홀수 펼침, 첫/끝 이동, 직접 점프, 회전과 재배열 후 UUID 유지, 창 크기 |
| DiaryBookmarkStorageTests | 두 다이어리 분리, 추가/해제, 디스크 저장 후 새 컨테이너 재로딩, 다른 문서의 페이지 거부, 기존 버전 1 JSON 호환성 |
| DiaryStorageTests 추가 | 저장 실패 시 목록의 책갈피 유지와 재시도 |
| BookshelfUITests 추가 | 실제 생성·책장 열기·목차 점프·회전·책갈피 추가·종료/재실행·목록 이동·해제 |

테스트의 여러 페이지는 경계 조건을 위한 격리된 테스트 데이터입니다. 앱의 사용자 다이어리에 가짜 페이지를 삽입하지 않습니다.

## Mac Xcode 수동 확인

1. 기존 설치/시뮬레이터 데이터를 삭제하지 말고 3차 버전에서 만든 다이어리를 준비합니다. 별도 테스트 기기를 사용하고 중요한 원본 저장소는 보존합니다.
2. `FOLINA.xcodeproj`를 열고 `FOLINA` 스킴, iPadOS 18.2 이상 iPad 시뮬레이터를 선택합니다. ⌘B/⌘R, ⌘U로 빌드와 전체 기존/추가 테스트를 실행하고 결과를 기록합니다.
3. 기존 다이어리와 새 다이어리를 책장에서 엽니다. 제목·실제 속지·방향/비율·기존 날짜를 확인하고, 1페이지만 있으면 다음·이전 모두 비활성화되는지 확인합니다. 샘플은 읽기 링크가 없어야 합니다.
4. 링·하드커버·일반 제본을 각각 생성하여 외형·종이 단면·제본 위치를 확인합니다. 무지·줄·모눈·도트, 가로 속지도 확인합니다.
5. 세로/가로 회전, Split View와 Stage Manager 창 크기를 바꿉니다. 선택한 페이지가 유지되고 글자·종이가 잘리지 않는지 확인합니다. 큰 글자·VoiceOver·동작 줄이기도 확인합니다.
6. 목차에서 페이지를 선택하고, 펼침에서 오른쪽 종이를 선택한 뒤 회전하여 선택 페이지 유지와 책갈피 대상을 확인합니다. 현재 생성 UI는 1페이지이므로 여러 페이지·홀수 끝·회전의 자동 검증은 `DiaryReadingPositionTests`를 사용합니다. 여러 페이지 수동 시각 검증에는 별도 테스트 대상/디버그 픽스처가 필요하며 이번 앱에 시연 페이지를 넣지는 않았습니다.
7. 책갈피 추가 → 책갈피 목록 → 해당 페이지 이동 → 책장 복귀 → 앱 완전 종료·재실행 → 같은 다이어리 열기로 유지 여부를 확인합니다. 다른 다이어리에 섞이지 않는지, 해제 후 재실행해도 해제 상태인지 확인합니다.
8. 저장 실패의 자동 검증은 주입한 저장소 오류를 사용합니다. 실제 저장 용량 부족·프로세스 강제 종료 중 저장은 별도 테스트 기기에서 확인해야 합니다. 실패 안내가 나타나고 기존 데이터가 유지되는지 확인합니다.
9. 편집 준비 중 안내와 책장 복귀를 확인합니다. [읽기 명세](../design/reading-spec.md)의 원본 차이를 고려해 실제 화면을 Figma와 비교하고 PR에 캡처를 첨부합니다.

실제 페이지 말림은 이번 구현에 없습니다. 스와이프·버튼 연속 입력 시 한 번씩만 이동하는지는 실기기에서 추가 확인해야 합니다.

## 이번 작업의 변경 파일

| 구분 | 파일 |
|---|---|
| 추가 | `FOLINA/Components/DiaryReadingBook.swift` |
| 추가 | `FOLINA/Models/DiaryReadingPosition.swift` |
| 추가 | `FOLINATests/DiaryReadingTests.swift` |
| 추가 | `docs/design/reading-spec.md` |
| 추가 | `docs/development/reading-verification.md` |
| 수정 | `FOLINA/Components/DiaryCreationPreview.swift` |
| 수정 | `FOLINA/DesignSystem/FolinaTheme.swift` |
| 수정 | `FOLINA/Models/DiaryDocument.swift` |
| 수정 | `FOLINA/Persistence/DiaryLibrary.swift` |
| 수정 | `FOLINA/Persistence/DiaryRepository.swift` |
| 수정 | `FOLINA/Screens/Bookshelf/BookshelfView.swift` |
| 수정 | `FOLINA/Screens/Creation/DiaryCreationView.swift` |
| 수정 | `FOLINA/Screens/Diary/DiaryDetailView.swift` |
| 수정 | `FOLINATests/DiaryStorageTests.swift` |
| 수정 | `FOLINAUITests/BookshelfUITests.swift` |
| 수정 | `docs/README.md` |
| 수정 | `docs/architecture/data-model.md` |
| 수정 | `docs/architecture/decisions.md` |
| 수정 | `docs/architecture/overview.md` |
| 수정 | `docs/design/navigation.md` |
| 수정 | `docs/design/screen-spec.md` |
| 수정 | `docs/development/backlog.md` |
| 수정 | `docs/development/changelog.md` |
| 수정 | `docs/product/feature-spec.md` |
| 수정 | `docs/product/mvp-scope.md` |
| 수정 | `docs/product/policies.md` |

### 후속 요청 — 책장 방향 구분

추가 수정: `FOLINA/Models/DiarySummary.swift`, `FOLINA/Models/DiaryDraft.swift`, `FOLINA/Components/DiaryCard.swift`, `FOLINA/Components/DiaryCoverView.swift`. 문서/표시 투영에 방향을 전달하고 표지 비율 및 가로형/세로형 설명을 적용했습니다. Mac에서 두 방향을 각각 생성해 책장 표지와 제목 정렬을 비교해야 합니다.

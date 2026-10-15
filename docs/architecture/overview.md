# 아키텍처 개요

- 원본/근거: 사용자 요청 및 저장소 직접 확인
- 확인일: 2026-10-15 (한국 시간, 외부 원본은 접근 시도일)
- 문서 상태: 3차 로컬 저장 구조 작성 / Mac 빌드 검증 필요

## 확인된 현재 구현

3차 개발은 2차 PR #3이 병합된 main `d6cad22`에서 시작했습니다.

```text
FOLINA/
├── ContentView.swift                      # 라이브러리 생성·주입·시작 시 로딩
├── Models/DiaryDraft.swift                # 기존 화면 입력과 옵션
├── Models/DiaryDocument.swift             # 문서·페이지 영구 데이터 값
├── Models/DiarySummary.swift              # 책장 표시용 투영
├── Persistence/DiaryRepository.swift      # SwiftData 저장 어댑터
├── Persistence/DiaryLibrary.swift         # 목록·로딩·생성 상태와 오류
├── Screens/Bookshelf/BookshelfView.swift   # 실제 목록과 별도 샘플 영역
├── Screens/Creation/DiaryCreationView.swift
├── Screens/Diary/DiaryDetailView.swift     # 저장 정보 진입점
└── SampleData/SampleDiaries.swift         # 시연 전용, 저장하지 않음
```

`ContentView`가 `DiaryLibrary`를 환경에 주입합니다. 시작 시 저장소를 열고 읽으며 실패 시 재시도를 제공합니다. 생성 컨트롤러는 중복 요청을 막고 저장소의 명시적 저장이 성공한 뒤에만 목록을 갱신합니다. 생성 화면은 성공 반환 후 dismiss하여 책장으로 복귀합니다. 빈 이름·실패 시 입력과 화면을 유지합니다. 저장 중에는 옵션·뒤로 가기·최종 버튼을 비활성화합니다.

저장 작업은 MainActor에서 직렬화되며 async 인터페이스로 View와 분리했습니다. 현재 작은 초기 문서의 SwiftData 작업 자체는 동기식입니다. 대용량 편집 저장 시 별도 ModelActor 등 실행 위치를 재검토해야 합니다. 앱 강제 종료 전 저장 성공하지 않은 입력은 저장 보장 대상이 아닙니다.

SwiftData 컨테이너와 전용 context는 저장 어댑터가 유지합니다. 오류 시 fallback 메모리 저장소를 만들지 않습니다. [데이터 모델](data-model.md), [기술 결정](decisions.md)을 참고합니다.

폴더는 기존 Xcode의 `PBXFileSystemSynchronizedRootGroup` 아래에 있어 소스 목록을 수동 편집하지 않습니다. 기존 테스트 타깃과 프로젝트 설정을 유지합니다.

## 확인된 프로젝트 설정

[FOLINA.xcodeproj/project.pbxproj](../../FOLINA.xcodeproj/project.pbxproj) 기준입니다.

| 항목 | 값 |
|---|---|
| 생성 도구 기록 | Xcode 16.2 |
| Swift 언어 모드 | 5.0 |
| 최소 운영체제 | iOS / iPadOS 18.2 |
| 기기군 | `1,2`: iPhone과 iPad |
| iPad 방향 | 세로·거꾸로 세로·가로 양방향 |
| 앱 번들 ID | `com.folina.FOLINA` |
| 코드 서명 | Automatic |

사용자는 iPad용 제품으로 설명했지만 현재 설정은 iPhone도 지원합니다. iPad 전용 전환 여부는 미결정이며 이번 작업에서 설정을 변경하지 않습니다. 최소 지원 버전의 제품 적합성도 원본 확인 후 결정해야 합니다.

## 빌드 및 검증 제한

현재 클라우드는 Linux이며 Swift, Xcode, Apple SDK와 iOS 시뮬레이터를 사용할 수 없습니다. `xcodebuild -version`은 명령 없음으로 실패했습니다. Linux용 Swift만 설치해도 SwiftUI iOS 앱을 빌드할 수 없습니다.

앱 빌드·실행과 단위/UI 테스트는 미실행입니다. Mac과 호환되는 Xcode, iOS 18.2 이상을 지원하는 시뮬레이터가 필요합니다. Mac에서 프로젝트의 스킴과 사용 가능한 iPad 시뮬레이터를 먼저 확인한 뒤 해당 대상으로 빌드·테스트해야 합니다. 이 절차는 현재 환경에서 검증되지 않았습니다.

## 미결정 사항

필기·미디어 저장, 백업 포맷과 클라우드 동기화는 후속 설계 대상입니다. 이번 단계에서는 SwiftData 로컬 저장만 구현합니다.

## 2차 개발 — 생성 옵션 화면 (당시 구현 기록)

- `ContentView`의 `NavigationStack`에서 책장 → `DiaryCreationView`로 이동합니다. 뒤로 가면 생성 화면의 `@State` 초안은 해제됩니다.
- `Models/DiaryDraft.swift`의 값 타입에 이름·기록 방식·제본·색상·표지 스타일·속지·방향을 보관합니다. 저장 스키마를 확정하지 않고 향후 저장 계층에 전달할 수 있는 값으로 분리했습니다.
- `Screens/Creation/DiaryCreationView.swift`가 상태를 소유하고, `DiaryOptionPicker`는 `Binding`으로 각 필드만 수정합니다.
- `DiaryCreationPreview`는 같은 초안을 읽어 펼친 속지를 그립니다. `DiaryCoverView`는 초안의 표시용 투영을 받아 표지 스타일을 표시합니다.
- `FolinaHeader`, `MetalBinderRing`, `DiaryCoverTone+Color`는 책장·생성 화면에서 공유합니다. 기존 샘플과 제본 스타일을 유지합니다.
- 세부 동작·디자인 차이·Mac 검증 절차는 [생성 화면 명세](../design/creation-spec.md)를 참조합니다.

# 아키텍처 개요

- 원본/근거: 사용자 요청 및 저장소 직접 확인
- 확인일: 2026-10-15 (한국 시간, 외부 원본은 접근 시도일)
- 문서 상태: 책장 홈 구조 작성 / Mac 빌드 검증 필요

## 확인된 현재 구현

문서 구축 PR #1이 병합된 `main` 커밋 `7fd35f2`에서 책장 홈 개발을 시작했습니다. 아래 파일은 이번 기능 브랜치의 구현입니다.

```text
FOLINA/
├── FOLINAApp.swift                # 앱 시작
├── ContentView.swift              # 책장 조립 및 샘플 주입
├── Screens/Bookshelf/BookshelfView.swift
├── Components/DiaryCard.swift
├── Components/DiaryCoverDecoration.swift # 추가 표지 장식
├── Components/DiaryCoverView.swift
├── DesignSystem/FolinaTheme.swift
├── Models/DiarySummary.swift       # 책장 표시용 값
└── SampleData/SampleDiaries.swift  # 저장하지 않는 샘플
```

책장 화면은 주입받은 목록을 표시합니다. 표지의 제본·색상·장식 디자인 종류를 분리하여 다른 외형을 추가할 수 있게 구성했습니다. 영구 저장 모델·저장소는 없습니다. 2차 개발에서 생성 옵션 화면과 화면 내 초안 모델을 추가했습니다.

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

목표 아키텍처 패턴, 상태 관리, 저장 방식, 동기화 여부는 확정하지 않았습니다. 원본 요구사항을 확인한 뒤 대안을 검토하고 중요한 결정은 [기술 결정](decisions.md)에 기록합니다.

## 2차 개발 — 생성 옵션 화면

- `ContentView`의 `NavigationStack`에서 책장 → `DiaryCreationView`로 이동합니다. 뒤로 가면 생성 화면의 `@State` 초안은 해제됩니다.
- `Models/DiaryDraft.swift`의 값 타입에 이름·기록 방식·제본·색상·표지 스타일·속지·방향을 보관합니다. 저장 스키마를 확정하지 않고 향후 저장 계층에 전달할 수 있는 값으로 분리했습니다.
- `Screens/Creation/DiaryCreationView.swift`가 상태를 소유하고, `DiaryOptionPicker`는 `Binding`으로 각 필드만 수정합니다.
- `DiaryCreationPreview`는 같은 초안을 읽어 펼친 속지를 그립니다. `DiaryCoverView`는 초안의 표시용 투영을 받아 표지 스타일을 표시합니다.
- `FolinaHeader`, `MetalBinderRing`, `DiaryCoverTone+Color`는 책장·생성 화면에서 공유합니다. 기존 샘플과 제본 스타일을 유지합니다.
- 세부 동작·디자인 차이·Mac 검증 절차는 [생성 화면 명세](../design/creation-spec.md)를 참조합니다.

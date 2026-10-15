# 아키텍처 개요

- 원본/근거: 사용자 요청 및 저장소 직접 확인
- 확인일: 2026-10-15 (한국 시간, 외부 원본은 접근 시도일)
- 문서 상태: 현재 저장소 확인 완료 / 목표 아키텍처 미결정

## 확인 근거

기준 커밋은 `ab8756e` (`Initial Commit`)입니다. 아래는 코드와 프로젝트 설정에서 확인한 사실이며 외부 기획·디자인 원본을 반영한 목표 구조가 아닙니다.

## 확인된 현재 구현

- [FOLINAApp.swift](../../FOLINA/FOLINAApp.swift): SwiftUI 앱 시작 지점. `WindowGroup`에서 `ContentView`를 표시합니다.
- [ContentView.swift](../../FOLINA/ContentView.swift): 지구 시스템 아이콘과 `Hello, world!` 문구를 세로로 배치한 기본 화면, `#Preview` 선언입니다.
- `FOLINA/Assets.xcassets`와 `FOLINA/Preview Content`: 기본 리소스 구조입니다.
- `FOLINATests`: Swift Testing 기반의 비어 있는 예제 테스트입니다. 기능 검증문은 없습니다.
- `FOLINAUITests`: 앱 실행, 실행 시간 측정, 스크린샷 수집용 템플릿 코드입니다.

현재 다이어리·다꾸 기능, 데이터 모델, 영구 저장, 백엔드 연동은 구현되어 있지 않습니다. 프로젝트에 외부 Swift 패키지 의존성 선언도 발견되지 않았습니다.

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

# FOLINA 개발 문서 안내

- 원본/근거: [PRD](https://app.notion.com/p/3f91e7915bce8167a6aff13f6915004e) · [기능 명세](https://app.notion.com/p/3f91e7915bce81f89817c482350c29da) · [IA](https://app.notion.com/p/3f91e7915bce812b9cb6bba4345c) · [MVP 정책](https://app.notion.com/p/3f91e7915bce8177a7fcf5b86d220de7) · [상품 및 데이터 모델](https://app.notion.com/p/3f91e7915bce813085e3fe2b6ae1f8a0) · [개발 핸드오프 및 백로그](https://app.notion.com/p/3f91e7915bce81e78a27d64a54ec2f67) · [Figma](https://www.figma.com/design/FFQxwcgxtazngCK8Sp26hv/Untitled) · [FigJam](https://www.figma.com/board/xe98koWxDTV0LYXXboiROy/Untitled)
- 확인일: 2026-10-15 (한국 시간, 외부 원본은 접근 시도일)
- 문서 상태: 관리 규칙 확정 / Figma 및 Notion 일부 확인 / 나머지 원본 확인 필요

## 원본과 GitHub 문서의 역할

사용자 요청으로 확정한 문서 관리 원칙입니다.

| 위치 | 관리하는 원본 |
|---|---|
| Notion | 제품 기획, 기능 명세, 정책, 데이터 모델 |
| Figma | UI 디자인, 디자인 시스템, 화면 구성 |
| FigJam | 사용자 흐름, 정보 구조, 기능별 프로세스 |
| GitHub docs | 개발에 필요한 확정 사항을 정리한 참조용 명세 |

Notion·Figma·FigJam을 원본(Source of Truth)으로 유지합니다. GitHub 문서는 원본을 대체하지 않습니다. Figma에서는 최신 MVP UX 디자인 페이지의 v5로 수정된 화면을 우선 참고합니다. 이는 사용자가 지정한 참조 기준이며, 해당 화면을 직접 확인했다는 뜻은 아닙니다.

## 확인 상태와 표기

- **확정 요구사항**: 사용자 명시 지시 또는 실제 열람한 원본에서 확정된 요구사항. 근거를 함께 기록합니다.
- **확인된 구현**: 저장소 코드·설정에서 확인한 현재 상태. 제품 요구사항과 구분합니다.
- **제안사항**: 검토 전 아이디어이며 구현 승인이나 확정 요구사항으로 취급하지 않습니다.
- **미결정 사항**: 책임자의 확인이 필요한 선택. 모호한 요구사항은 질문하고 임의 확정하지 않습니다.
- **자료 확인 필요**: 원본을 읽지 못했거나 해당 내용을 아직 확인하지 못한 상태입니다.

모든 문서는 한국어 Markdown으로 작성하고 상단에 원본 링크, 확인일, 상태를 기록합니다. 외부 원본의 확인일은 본문을 실제 읽은 날로 갱신하며, 실패한 접근 시도와 구분합니다.

## 원본 접근 결과

최초 문서 구축 당시 원본 링크 8개에 HTTPS 접근을 시도했으나 모두 네트워크 프록시의 `Tunnel connection failed: 403 Forbidden`으로 차단되었습니다. 당시에는 본문을 열람하지 못했습니다. 문서 공개 여부·계정 권한·내용·최신 버전은 판정할 수 없습니다.

Notion IA 링크는 제공받은 주소를 그대로 기록했습니다. 유효한 문서 주소인지도 추가 확인이 필요합니다.

이후 연결된 Figma 도구로 페이지 `26:2`와 v5 책장 홈 `27:15`를 열람했습니다. 현재 확인 범위와 차이는 [화면 명세](design/screen-spec.md)에 기록합니다. SVG 파일 다운로드는 네트워크 403으로 차단되었습니다. 나머지 제품·디자인 원본과 저장소 사이의 차이는 아직 비교할 수 없습니다. 미확인을 불일치나 일치로 해석하지 않습니다. 추후 차이가 발견되면 원본 위치/버전, GitHub 문서 위치, 서로 다른 내용과 영향을 보고하고 확인 전 조용히 덮어쓰지 않습니다.

## 문서 지도

| 문서 | 역할 |
|---|---|
| [제품 개요](product/prd.md) | 제품 목적과 사용자 |
| [기능 명세](product/feature-spec.md) | 확정 기능과 수용 기준 |
| [MVP 범위](product/mvp-scope.md) | 포함·제외 범위 |
| [정책](product/policies.md) | 제품 동작 정책 |
| [디자인 시스템](design/design-system.md) | 디자인 토큰·컴포넌트 |
| [화면 명세](design/screen-spec.md) | 화면 상태·인터랙션 |
| [생성 화면](design/creation-spec.md) | 2차 개발 옵션·미리보기·검증 절차 |
| [탐색 구조](design/navigation.md) | IA·사용자 흐름·화면 전환 |
| [아키텍처 개요](architecture/overview.md) | 현재 코드 구조와 실행 제약 |
| [데이터 모델](architecture/data-model.md) | 확정 데이터 구조·저장 방식 |
| [기술 결정](architecture/decisions.md) | 결정 근거와 대안 |
| [로드맵](development/roadmap.md) | 개발 단계 |
| [백로그](development/backlog.md) | 작업과 미확인 항목 |
| [변경 내역](development/changelog.md) | 실제 변경 기록 |

## 작업 절차

1. 루트 [AGENTS.md](../AGENTS.md), 이 안내, 작업 관련 문서와 연결된 원본을 읽습니다.
2. 원본 접근 실패나 모호한 요구사항은 보고·질문합니다. 확인되지 않은 기능을 임의 확정하지 않습니다.
3. 기존 체크아웃의 별도 작업 브랜치에서 개발합니다. main 직접 수정과 자동 병합은 금지합니다.
4. 구현 시 관련 명세·기술 문서와 변경 내역을 함께 갱신합니다. 중요한 기술 결정은 결정 기록에 근거와 함께 남깁니다.
5. Figma 변경이 필요하면 원본을 임의 수정하지 않고 변경안을 제안합니다.
6. 가능한 검증을 수행하고 실행하지 못한 검증을 명시한 뒤 Pull Request로 검토합니다.

한 내용은 담당 문서 한 곳에서 관리하고 다른 문서에서는 링크합니다. 자료 확인이 필요한 항목의 통합 목록은 [백로그](development/backlog.md)에서 관리합니다.

## 3차 개발 원본 확인 — 2026-10-16

연결된 Notion 도구로 기능 명세·MVP 정책·상품 및 데이터 모델을 열람했습니다. 관련 확인 내용과 범위 차이는 [제품 정책](product/policies.md) 및 [데이터 모델](architecture/data-model.md)에 반영했습니다. 이전 프록시 차단 기록은 당시 결과이며 현재 접근 불가를 의미하지 않습니다. 모든 원본을 확인한 것은 아닙니다.

실제 로컬 생성·책장 연결 및 오류 처리는 구현했으며 [Mac 검증 절차](development/local-storage-verification.md)를 따릅니다. Linux에서 앱 실행 결과는 확인하지 못했습니다.

## 4차 개발 — 읽기 및 페이지 탐색

Figma v5 읽기 27:125를 2026-10-16에 열람했습니다. 원본 에셋 다운로드 403과 구현 차이는 [읽기 명세](design/reading-spec.md)에, 수동/자동 검증 상태는 [읽기 검증](development/reading-verification.md)에 기록합니다. 기존 저장 모델의 선택적 책갈피 확장은 [데이터 모델](architecture/data-model.md)을 참고합니다.

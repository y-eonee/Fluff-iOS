# DESIGN.md — 대표 화면 4종 기반 전체 플로우 UI 마이그레이션 명세

> **역할:** 디자인 토큰 + 화면 설계 명세 + 화면 이름별 매칭 + 기존 UI의 구조적 교체 규칙을 하나로 묶은 실행 문서.
> **버전:** 1.0 · **기준일:** 2026-11-16 · **기준 기기:** 390 × 844 px 모바일 세로.
> **출처:** 원본 Figma의 실제 레이어 속성, 별도 시각적 디자인 시스템 프레임, 현재 기록된 전체 플로우 화면 매칭 명세.
> **주의:** 본 문서는 Figma를 수정하지 않는다. 단순 스타일 교체만 수행하는 것은 불합격. 이미지 에셋은 Figma를 통해 재사용해야 하며, 이 텍스트만으로 이미지 바이트가 전달되지는 않는다.

## 00. Document Overview

- Figma 파일: https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb
- 시각적 디자인 시스템: https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb?node-id=1675-3945 — `[DS] 4 Representative Screens · Full UI Spec`
- 원본 4화면 부모 프레임: https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb?node-id=1646-5327 — `전면수정- 라인x 버전 통일`
- 버튼 컴포넌트 세트: Figma `1676:4218` (`Button / Four source roles`). **중요: 이 세트의 Disabled 명칭은 아래 07절의 불일치 검수를 우선 적용.**
- 원본(숨김 레이어 포함)에서 구분한 SOLID HEX+Alpha 조합 **35개**, 활성 고유 Gradient 명세 **9개**, 텍스트 속성 조합 **25개** (이 가운데 로컬 스타일 등록 **23개**), 분석된 소스 레이어 **241개**. 실제 플로우 이름 인벤토리 **67개**.
- 디자인 시스템에는 00–10까지 11개 검토 섹션이 있다. 마지막 `10 — Actual Flow Screen-Name Matching`은 실제 이름+ID 출처다.

### 00.1 네 대표 화면의 역할

| 코드 | 대표 화면 | Figma 실제 이름 | Source node | 적용 범위 |
| --- | --- | --- | --- | --- |
| ROOM | 방꾸미기 | 1안 · 방꾸미기 | [Figma #1646:5442](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb?node-id=1646-5442) | 방 편집·가구·벽지·소품 |
| FOCUS | 집중 중 | 03 · 집중 중 · A | [Figma #1654:10121](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb?node-id=1654-10121) | 집중 진행·타이머·휴식 상태 |
| MAKING | 인형 만들기 · 모양 선택 | 개선 / 08 · 모양 선택 / 기본 모양 | [Figma #1654:10366](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb?node-id=1654-10366) | 인형 제작 플로우·단계/모양 선택 |
| COUCH | 소파에서 같이 보기 | S-4 · 소파에서 같이 보는 중 | [Figma #1655:4987](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb?node-id=1655-4987) | 소파/영상 플레이어 및 함께보기 |

### 00.2 이 문서 사용 순서

1. 대상 UI 프레임 이름·상위 플로우·화면 목적을 확인한다.
2. **16/17절의 실제 화면 매칭표**에서 대표 화면·예외를 판정한다. `REVIEW_REQUIRED`면 레이아웃 자동 교체 금지.
3. **12–15절의 해당 화면 구조**를 먼저 적용한다. 배경·카드 계층·고정 위치·Z-order를 확인한다.
4. **03–11절의 실제 토큰 및 컴포넌트**를 역할에 맞게 적용한다. 기존 기능, 상태, 데이터, 내비게이션 연결은 유지한다.
5. **18–22절의 교체 규칙과 QA**를 시행하고 Figma 원본과 시각적으로 대조한다.

## 01. Source of Truth & Priority Rules

**사용자 후속 결정 (2026-11-17):** 상태바에는 별도의 배경색 띠를 두지 않고 해당 화면의 배경이 그대로 이어지도록 한다. 상태바 아이콘은 시스템 표시를 유지한다. 아래 원본 색상·레이어 기록에 상태바 전용 색상이 있더라도 이 사용자 결정을 우선 적용한다.

**로딩 탭바 후속 결정 (2026-11-17):** 로딩 화면(`1825:6433`)의 탭바는 흰색으로 통일하고 아이콘·글자는 검정색으로 표시한다. 원본 시안의 ‘솜뭉치들’·‘마이’ 탭 검정 배경은 적용하지 않는다.

**로딩 장면 후속 결정 (2026-11-17):** 첫 홈 로딩(`1825:6433`)은 별도 방·인형 이미지로 대체하지 않는다. 현재 홈의 실제 3D 방과 저장된 인형을 사용하고, 인형의 도착점은 현재 배치의 화면 좌표에서 계산한다. 홈 진입 효과는 시작 화면과 3D 장면 준비 후 세션당 한 번 재생한다. 방 꾸미기 진입(`1825:8443`)도 현재 가구·인형에 효과를 적용하며 저장 좌표와 편집 이력은 바꾸지 않는다.

**시각적 판단 우선순위**: (1) 현재 대표 4개 원본의 *실제로 보이는* 레이어/속성 → (2) 디자인 시스템의 화면별 명세 → (3) 공통 토큰·재사용 컴포넌트 → (4) 변경 전 화면의 오래된 스타일. **기능 판단 우선순위**: 대상 화면의 기존 프로토타입 상태·인터랙션·연결 → 기능별 플로우 → 새 시각적 표현.

- 원본의 `visible=false` 레이어와 `fill.visible=false` 페인트는 **활성 디자인으로 적용하지 않는다.** 숨김·비활성 옵션은 참고용으로만 기록한다.
- 사용자가 명시한 버튼 역할은 **Disabled=투명도 적용 / Default=흰색 / CTA=검정 그라데이션 / Selected=하늘색 그라데이션**. 정확한 Disabled 불투명도 값은 현재 4개 대표 화면만으로 확정하지 않는다.
- 폰트·그라데이션·배경이 다른 화면 간에는 역할별 예외를 허용한다. 모든 화면을 하나의 미색 배경, 카드형 화면 또는 동일 버튼 크기로 평준화하지 않는다.
- 화면의 기능·문구·데이터·행동·프로토타입 링크를 바꾸지 않는다. 단, 오래된 **시각적 구조**는 디자인 기준과 충돌하면 교체한다.
- 검증되지 않은 값은 `UNVERIFIED`, 애매한 화면 매칭은 `REVIEW_REQUIRED`, 사용되지 않는 숨김 페인트는 `INACTIVE_SOURCE`로 표시한다.
- **절대 규칙:** `기존 기능 유지 ≠ 기존 UI 디자인 유지`.

## 02. Design Principles

1. **4개 화면은 서로 다른 화면 유형**이다. 방 편집은 실제 룸 씬+하단 시트, 집중 진행은 실사 공간+하단 투명/암부 타이머, 인형 제작은 진행 단계+중앙 미리보기+이전/다음, 소파 시청은 캐릭터+플레이어+미디어 제어+CTA이다.
2. 각 화면의 **정보 위계**는 Figma의 시각적 크기·위치·표시 순서로 결정한다. 색상만 맞고 위계가 틀리면 불합격.
3. 한 화면의 컴포넌트를 다른 화면에 이식할 때는 **기능 역할과 상태**가 일치해야 한다. 집중 화면의 진행률과 소파 영상의 타임라인은 같은 프로그레스 바가 아니다.
4. 사각형·그룹·인스턴스·이미지는 가능한 한 Figma 원본 노드를 재사용한다. 이미지와 일러스트를 새 AI 이미지로 임의 교체하지 않는다.
5. 임의의 4/8/12/16 토큰 세트, 폰트 5단계, 통일된 그리드 등을 강제하지 않는다. 실제 소스에는 소수점 크기도 존재한다.
6. 숨김 레이어의 내용을 사용자에게 보이는 기본 UI로 승격하지 않는다.

## 03. Color Tokens — 실제 35개 HEX/Alpha 조합

아래 항목은 대표 4개 원본에 **존재하는 SOLID 페인트 조합(숨김 레이어 포함)**에서 추출된 값이다. 반드시 각 Node의 `visible`과 개별 Fill의 `visible` 상태를 함께 확인하고, 숨김 레이어의 색상을 현재 화면에 자동 적용하지 않는다. 같은 HEX라도 Alpha에 따라 별도 토큰이다. `#000000 / 40%`는 소스에 존재하지만 집중 전경 디밍 레이어가 숨김 상태이므로 **그 용도로는 비활성**이다. 전체 35개 토큰 컬렉션 이름은 `Representative 4 / Source palette` (`VariableCollectionId:1678:4013`), Figma 변수 코드 표기는 `var(--rep4-R-G-B-Alpha)`이다.

| ID | HEX | Alpha | CSS 등가값 | 실제 용도 / 상태 | 화면 | Figma 변수 |
| --- | --- | --- | --- | --- | --- | --- |
| COL-01 | `#FFFFFF` | 100% | `rgba(255, 255, 255, 1)` | 전체 시트·카드·버튼·텍스트 | ROOM / MAKING / COUCH | `VariableID:1678:4014` |
| COL-02 | `#FFFFFF` | 74% | `rgba(255, 255, 255, 0.74)` | 반투명 되돌리기·다시하기 | ROOM | `VariableID:1678:4015` |
| COL-03 | `#000000` | 100% | `rgba(0, 0, 0, 1)` | 본문·아이콘·벡터 | ROOM / MAKING / COUCH | `VariableID:1678:4016` |
| COL-04 | `#B2DDEA` | 100% | `rgba(178, 221, 234, 1)` | 선택 가구·칩 테두리 | ROOM / MAKING | `VariableID:1678:4017` |
| COL-05 | `#F2F2F2` | 70% | `rgba(242, 242, 242, 0.7)` | 가구 비선택 카드 | ROOM | `VariableID:1678:4018` |
| COL-06 | `#000000` | 78% | `rgba(0, 0, 0, 0.78)` | 가구 카드의 비선택 텍스트 | ROOM | `VariableID:1678:4019` |
| COL-07 | `#E5E5E5` | 100% | `rgba(229, 229, 229, 1)` | 일부 카드 테두리 | ROOM | `VariableID:1678:4020` |
| COL-08 | `#181818` | 100% | `rgba(24, 24, 24, 1)` | 텍스트·홈 인디케이터 | ROOM / MAKING | `VariableID:1678:4021` |
| COL-09 | `#6B4A3E` | 100% | `rgba(107, 74, 62, 1)` | 캐릭터 도형·아이콘 | ROOM | `VariableID:1678:4022` |
| COL-10 | `#080808` | 100% | `rgba(8, 8, 8, 1)` | 화면 제목 | ROOM / MAKING | `VariableID:1678:4023` |
| COL-11 | `#F9F9F9` | 100% | `rgba(249, 249, 249, 1)` | 집중/제작 기본 바탕 | FOCUS / MAKING / COUCH | `VariableID:1678:4024` |
| COL-12 | `#000000` | 20% | `rgba(0, 0, 0, 0.2)` | 집중 Frame 배경의 별도 Fill | FOCUS | `VariableID:1678:4025` |
| COL-13 | `#000000` | 40% | `rgba(0, 0, 0, 0.4)` | 집중 숨겨진 디밍 레이어의 Fill (활성 아님) | FOCUS | `VariableID:1678:4026` |
| COL-14 | `#CDB8A6` | 100% | `rgba(205, 184, 166, 1)` | 숨겨진 작업대 구조의 색 | FOCUS | `VariableID:1678:4027` |
| COL-15 | `#E8DDCB` | 100% | `rgba(232, 221, 203, 1)` | 숨겨진 바닥 연장 레이어 | FOCUS | `VariableID:1678:4028` |
| COL-16 | `#4A352A` | 100% | `rgba(74, 53, 42, 1)` | 집중 상태 표시줄 등 브라운 | FOCUS / COUCH | `VariableID:1678:4029` |
| COL-17 | `#6E5244` | 100% | `rgba(110, 82, 68, 1)` | 집중 홈 인디케이터 | FOCUS | `VariableID:1678:4030` |
| COL-18 | `#8FB8AE` | 100% | `rgba(143, 184, 174, 1)` | 집중 숨겨진 원형 버튼 Fill | FOCUS | `VariableID:1678:4031` |
| COL-19 | `#FFFFFF` | 30% | `rgba(255, 255, 255, 0.3)` | 집중 원형 일시정지 배경·반투명 | FOCUS | `VariableID:1678:4032` |
| COL-20 | `#D9D9D9` | 20% | `rgba(217, 217, 217, 0.2)` | 집중 진행 트랙 | FOCUS | `VariableID:1678:4033` |
| COL-21 | `#D4EEF6` | 100% | `rgba(212, 238, 246, 1)` | 집중 채움·제작 진행 막대 | FOCUS / MAKING | `VariableID:1678:4034` |
| COL-22 | `#7A7A7A` | 100% | `rgba(122, 122, 122, 1)` | 일부 상태 테두리 | FOCUS | `VariableID:1678:4035` |
| COL-23 | `#9A9A9A` | 100% | `rgba(154, 154, 154, 1)` | 제작 미완료 단계 텍스트 | MAKING | `VariableID:1678:4036` |
| COL-24 | `#D9D9D9` | 60% | `rgba(217, 217, 217, 0.6)` | 인형제작 상단 진행 트랙 | MAKING | `VariableID:1678:4037` |
| COL-25 | `#1F1F1F` | 100% | `rgba(31, 31, 31, 1)` | 인형제작 보조 버튼 텍스트 | MAKING | `VariableID:1678:4038` |
| COL-26 | `#F9FAFA` | 100% | `rgba(249, 250, 250, 1)` | 소파 상태 표시줄 | COUCH | `VariableID:1678:4039` |
| COL-27 | `#FFFDF8` | 100% | `rgba(255, 253, 248, 1)` | 소파 상태바 부분 바탕 | COUCH | `VariableID:1678:4040` |
| COL-28 | `#F0F5F8` | 100% | `rgba(240, 245, 248, 1)` | 이전/다음 영상 컨트롤 배경 | COUCH | `VariableID:1678:4041` |
| COL-29 | `#707070` | 100% | `rgba(112, 112, 112, 1)` | 그만 보기 텍스트 | COUCH | `VariableID:1678:4042` |
| COL-30 | `#DFF2F8` | 100% | `rgba(223, 242, 248, 1)` | 인형 선택 보조 바탕·소파 중앙 재생 | MAKING / COUCH | `VariableID:1678:4043` |
| COL-31 | `#FFF5D9` | 90% | `rgba(255, 245, 217, 0.9)` | 영상 아트의 달 | COUCH | `VariableID:1678:4044` |
| COL-32 | `#DCFFD1` | 55% | `rgba(220, 255, 209, 0.55)` | 영상 아트의 언덕 | COUCH | `VariableID:1678:4045` |
| COL-33 | `#F25454` | 100% | `rgba(242, 84, 84, 1)` | YouTube 마크 | COUCH | `VariableID:1678:4046` |
| COL-34 | `#FFFFFF` | 90% | `rgba(255, 255, 255, 0.9)` | 플레이어 출처 텍스트 | COUCH | `VariableID:1678:4047` |
| COL-35 | `#FFFFFF` | 40% | `rgba(255, 255, 255, 0.4)` | 동영상 진행 트랙 | COUCH | `VariableID:1678:4048` |

**구분 지침:** `COL-01` 흰색 카드와 `COL-02` 74% 흰색 Glass 버튼을 같은 불투명도로 바꾸지 않는다. `COL-12` 20% 검정 Frame Fill과 `COL-13` 40% 검정 숨김 레이어는 다른 역할이다. 배경 이미지에 적용하는 Overlay는 레이어 가시성까지 확인한다. Gradient 내부 색상은 별도 Gradient 명세에 기록되어 있으며 이 SOLID 표에 없는 색상도 정상이다.

## 04. Gradient Tokens — 활성 고유 패턴 9종

**정의 해석:** `ColorStop`의 Alpha와 **Paint 전체 Opacity**를 별도로 기록한다. `%` 위치는 Figma GradientStops[].position 기준이며 방향은 `gradientTransform = [[a,b,c],[d,e,f]]` 원본 행렬을 우선 복제한다. 일반 CSS의 `to top` 같은 방향 문자열로 변경하면 각도·범위가 달라질 수 있다. 아래 9개는 현재 활성 페인트에서 확인된 서로 다른 정의다.

| ID | 역할 | Source Node | Type | Color Stops | Paint Opacity | Gradient Transform | Scope |
| --- | --- | --- | --- | --- | --- | --- | --- |
| G-01 | 방꾸미기 전체 배경 | `1646:5442` | LINEAR | #FEFEFE 0% / α1 → #E1F8FF 96.978% / α1 | 100% | `[[0.05214,1,-0.03526],[-0.99966,0,1.17609]]` | ROOM |
| G-02 | 선택 가구 카드 / 인형 선택 칩 | `1646:5478` / `1654:10409` | LINEAR | #FEFEFE 0% / α1 → #C5EFFC 96.978% / α1 | 100% | `[[0.03376,0.63031,0.50053],[-0.63031,0.00416,0.92315]]` | ROOM / MAKING |
| G-03 | CTA 검정색 | `1654:10395` / `1655:4998` | LINEAR | #454545 0% / α1 → #212226 100% / α1 | 100% | `[[0.09827,1.43563,-0.49346],[-1.43563,0.01210,1.33282]]` | MAKING / COUCH |
| G-04 | 집중 하단 타이머 오버레이 | `1654:10133` | LINEAR | #000000 0% / α0.02 → #172F36 100% / α1 | 100% | `[[0,1,0],[-1,0,1]]` | FOCUS |
| G-05 | 집중 목표 진행 카드 | `1654:10142` | LINEAR | #525252 0% / α1 → #696969 100% / α1 | 58% | `[[0,1,0],[-1,0,1]]` | FOCUS |
| G-06 | 집중 진행 트랙의 흰색 Stroke | `1654:10145` | LINEAR | #FFFFFF 0% / α1 → #FFFFFF 100% / α1 | 100% | `[[1.95188,0.01515,-1.05923],[-19.84952,1.95188,12.27661]]` | FOCUS |
| G-07 | 인형 만들기·소파 전체 화면의 연한 오버레이 | `1654:10366` / `1655:4987` | LINEAR | #FEFEFE 0% / α1 → #DEE9ED 96.978% / α1 | 25% | `[[0.05214,1,-0.03526],[-0.99966,0,1.17609]]` | MAKING / COUCH |
| G-08 | 인형 만들기 흰 보조 버튼 Stroke | `1654:10394` | LINEAR | #EEEEEE 0% / α1 → #E8E8E8 100% / α1 | 100% | `[[-0.04214,0.56977,0.40389],[-0.56977,-0.00519,0.88272]]` | MAKING |
| G-09 | 소파 동영상 아트/플레이어 | `1655:5003` | LINEAR | #FAECDA 0% / α1 → #D3EDF5 37.981% / α1 → #28BEFA 100% / α1 | 100% | `[[0.8,0.6,0],[-0.6,0.8,0.3]]` | COUCH |

### 04.1 활성 및 숨김 페인트 구분

- `1654:10394` **이전으로 버튼**: G-02 Gradient Fill이 레이어에 존재하지만 `visible=false`; 실제로 보이는 Fill은 **#FFFFFF 100%**. G-08은 활성 Stroke다.
- `1655:4993` 소파 플레이어 외곽 카드: G-02 Fill은 **숨김**, 실제 보이는 Fill은 **#FFFFFF 100%**. Stroke 및 Drop Shadow도 숨김이다.
- `1655:5003` 동영상 플레이어 Stroke의 **Radial #79888C → #B8EFFE**는 Figma에서 `visible=false`: **기본 렌더에 적용 금지**. 이것까지 포함하면 고유 Gradient 데이터 정의는 10종이나 활성 정의는 9종이다.
- 원본 전체 그라데이션 색상만 따로 뽑아 현재 화면의 모든 배경을 그라데이션으로 바꾸지 말 것. G-04는 오직 Focus 타이머 하단 레이어, G-07은 Making/Couch Frame Fill, G-09는 소파 플레이어 콘텐츠에 적용된다.
- Frame에 복수 Fill이 있을 때에는 기존 배열 순서·가시성·합성 상태를 **Figma 그대로 복제**한다. 이미지가 같은 배경을 따로 사용하면 이미지 노드도 유지한다.

## 05. Typography Tokens — 원본에서 확인한 25개 조합

크기 및 Letter Spacing은 소수점까지 소스에서 얻은 값이다. 표시는 이해를 위해 소수점 셋째 자리로 반올림했으며 Figma 속성 변경 시 원본 Node의 원시값을 우선한다. `%` Letter Spacing은 Figma 상대값으로서 CSS에 그대로 `%` 문자열을 입력하지 말고 font-size 대비 `em` 단위로 변환한다 (`-5% = -0.05em`). `Auto` Line Height는 원본 Auto 그대로 둔다.

| ID | Screen | 역할/실제 예 | Font | Size px | Weight | Line Height | Spacing | Align | 원본 Node |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 | FOCUS | 00:18:42 | `Pretendard Regular` | 62 | 400 | 80px | -5% | 좌측 | `1654:10137` |
| T-02 | COUCH | couch time | `Gmarket Sans TTF Medium` | 28 | 500 | Auto | -4% | 좌측 | `1655:4992` |
| T-03 | ROOM | edit my room | `Gmarket Sans TTF Medium` | 25.397 | 500 | Auto | -7% | 중앙 | `1646:5499` |
| T-04 | FOCUS | 현재 집중 시간 | `Pretendard Bold` | 17 | 700 | 26px | -5% | 좌측 | `1654:10134` |
| T-05 | MAKING | 이전으로 | `Pretendard Medium` | 16 | 500 | 28px | +5% | 좌측 | `I1654:10394;1398:4243` |
| T-06 | COUCH | 홈에서 계속 보기 | `Pretendard Medium` | 16 | 500 | 28px | 0% | 좌측 | `I1655:4998;1398:4243` |
| T-07 | FOCUS | 목표 62% | `Pretendard SemiBold` | 15.789 | 600 | 145% | -5% | 좌측 | `1654:10143` |
| T-08 | COUCH | 영상 제목 | `Pretendard Bold` | 15 | 700 | 22px | 0% | 좌측 | `1655:5006` |
| T-09 | ROOM | 초기화 | `Pretendard Regular` | 14 | 400 | Auto | -3% | 좌측 | `1646:5463` |
| T-10 | ROOM | 9:41 | `Pretendard SemiBold` | 14 | 600 | 145% | 0% | 좌측 | `1646:5488` |
| T-11 | MAKING | 인형 모양 안내 | `Pretendard Regular` | 14 | 400 | 145% | -5% | 좌측 | `1654:10413` |
| T-12 | COUCH | 전체화면 아이콘 | `Pretendard Bold` | 14 | 700 | 16px | 0% | 좌측 | `1655:5016` |
| T-13 | COUCH | 빈 버튼 텍스트 레이어 | `Pretendard Medium` | 14 | 500 | 28px | 0% | 중앙 | `I1655:5018;1398:4243` |
| T-14 | COUCH | 플레이 리스트 변경 | `Pretendard Regular` | 14 | 400 | 28px | 0% | 중앙 | `1655:5026` |
| T-15 | ROOM | 말풍선 안내 | `Pretendard Medium` | 13 | 500 | 135% | -3% | 중앙 | `1646:5470` |
| T-16 | FOCUS | 9:41 | `Pretendard Medium` | 13 | 500 | 20px | 0% | 좌측 | `I1654:10131;1070:1435` |
| T-17 | MAKING | 동물 모양 칩 | `Pretendard Regular` | 12.743 | 400 | 150% | -5% | 중앙 | `1654:10408` |
| T-18 | ROOM | 가구 썸네일 이름 | `Pretendard Medium` | 12.285 | 500 | Auto | 0% | 좌측 | `I1646:5478;1590:2233` |
| T-19 | MAKING | 프리셋·커스텀 | `Pretendard Regular` | 12.167 | 400 | 150% | -5% | 중앙 | `1654:10399` |
| T-20 | MAKING | 제작 5단계 레이블 | `Pretendard Medium` | 12 | 500 | 145% | 0% | 중앙 | `1654:10382` |
| T-21 | COUCH | 그만 보기 | `Pretendard Medium` | 12 | 500 | 28px | 0% | 좌측 | `1655:4999` |
| T-22 | COUCH | YouTube 출처 | `Pretendard Medium` | 12 | 500 | 18px | 0% | 좌측 | `1655:5011` |
| T-23 | COUCH | 재생 시간 | `Pretendard Medium` | 11 | 500 | 16px | 0% | 좌측 | `1655:5015` |
| T-24 | FOCUS | 휴식까지 / 세트 레이블 | `Pretendard Regular` | 10.5 | 400 | 145% | 0% | 좌측 | `1654:10151` |
| T-25 | FOCUS | 05:18 / 18:01 | `Pretendard Regular` | 10.5 | 400 | 115% | 0% | 좌측 | `1654:10153` |

### 05.1 타이포 적용 절차

- 화면 제목은 `ROOM/MAKING`의 **Gmarket Sans TTF Medium 약 25.397px** 및 `COUCH`의 **28px**처럼 화면별 실제 크기를 보존한다. 획일적 `headline-lg`로 대체하지 않는다.
- Focus 타이머는 `Pretendard Regular 62px / line-height 80px / letter-spacing -5%`, 집중 라벨은 `Pretendard Bold 17px / 26px`. 카드 안의 42px 타이머로 바꾸지 않는다.
- 제작 단계 라벨은 `Pretendard Medium 12px / 145%`, 활성·완료는 #181818, 미완료는 #9A9A9A. 화면 상태에 따라 단계 기호도 달라진다.
- 주요 CTA는 `Pretendard Medium 16px / 28px`, 흰색 레이블. 흰색 이전 버튼도 16px Medium이지만 Source의 Letter Spacing은 +5%로 차이가 있다.
- Figma 텍스트 스타일 23개는 `Representative4 / ...` 네임스페이스로 생성됨. `Gmarket Sans TTF Medium`의 2개는 현재 편집 환경에서 신규 Style 등록이 불가능하여 **원본 속성만 확인됨**. 자의적으로 Pretendard로 바꿔 등록하지 않는다.
- 동일 크기라도 Line Height와 Spacing이 다르면 별도 Style로 처리한다. 현재 25개 조합을 임의로 5개 램프로 축약하지 않는다.

## 06. Spacing, Rounded, Opacity & Effects — 측정값 기반

### 06.1 정확히 측정한 기하 및 간격

| UI | 원본 수치 | 좌표 / 적용 | 설명 | Source Node |
| --- | --- | --- | --- | --- |
| 공통 화면 프레임 | 390 × 844 | ROOM / FOCUS / MAKING / COUCH | 원본 네 화면 모두 | `1646:5442` |
| 최상위 프레임 모서리 | R28 | ROOM / FOCUS / MAKING / COUCH | 폰 화면 Corner Radius | `1654:10121` |
| Home indicator | 134 × 4 / R2 | 화면 하단 y=831 | 중앙 배치, 화면별 Fill 다름 | `1654:10132` |
| Room Undo/Redo | 37 × 37 / R42 | x=23.23, x=71 / y=494 | 버튼간 실제 시각 간격 10.77px | `1646:5456` |
| Room Reset | 74 × 38 / R19 | x=296, y=493.92 | 독립형 흰색 일반 버튼 | `1646:5462` |
| Room Bottom Edit Sheet | 390 × 325 | x≈0, y=544 | 흰색 시트 / y부터 아래 UI | `1646:5472` |
| Room Furniture Card | 104.89 × 83.16 / R13.23 | 카탈로그 그리드 | 선택/비선택 스타일 구분 | `1646:5478` |
| Focus Goal Card | 326 × 66 / R15 | x≈31.77, y=125 | 상단 반투명 Glass 영역 | `1654:10142` |
| Focus Pause Circle | 73.56 × 73.56 | x≈287.75, y≈638.37 | 현재 실제 표시되는 원형 컨트롤 | `1654:10139` |
| Focus Timer Overlay | 390 × 424 | x=0, y=422 | 하단 Gradient 영역 | `1654:10133` |
| Focus Bottom Progress | 324 × 37.4 | x=33, y=736 | 진행 트랙 + 휴식/세트 레이블 | `1654:10147` |
| Making Step Strip | 342 × 35 | x≈23.8, y≈128.3 | 5단계 상태 | `1654:10380` |
| Making Preview Card | 334.92 × 383.31 / R22 | x≈26.75, y≈186.98 | 인형 전용 미리보기 카드 | `1654:10404` |
| Making Navigation Actions | 354 × 60 | x=18, y=734 | 버튼 폭 171씩, 버튼 사이 12px | `1654:10393` |
| Making Selected Chip | 84.11 × 32.91 / R18.29 | x=24, y≈669.43 | 선택된 곰돌이 | `1654:10409` |
| Making Other Chips | 76.8 × 31.09, 80.46 × 31.09 | x≈200.57, 114.12 | 일반 흰색 선택지 | `1654:10407` |
| Couch Content Card | 358 × 363.99 / R21 | x≈16.46, y≈338.8 | 보이는 Fill은 흰색 | `1655:4993` |
| Couch Player | 329 × 184 / R14 | x=31, y=353 | 카드 내부 플레이어 | `1655:5003` |
| Couch Previous/Next | 44 × 44 / R22 | x=99, 247 / y≈567 | 연한 #F0F5F8 | `1655:4994` |
| Couch CTA | 343 × 46 / R31.75 | x≈23.5, y≈717.46 | 검정 그라데이션 | `1655:4998` |
| Couch Playlist Row | 330 × 46 | x=30, y≈640.85 | 흰색 보조 변경 영역 | `1655:5017` |

**Spacing 주의:** 원본의 간격은 4pt grid로 모두 정규화되어 있지 않다. 방 편집 탭의 텍스트는 각각 별도 배치이고, 제작 선택 칩과 액션 사이의 여백도 다르다. 기존 `xs=4, sm=8, md=12...` 같은 이전 Starter Kit을 강제하지 않는다. 위 측정치가 우선이며 나머지는 원본 Inspect 값을 확인한다.

### 06.2 Effect 및 Opacity

| 기능 | 대상 | Node | 효과 값 | 상태 |
| --- | --- | --- | --- | --- |
| ROOM | 되돌리기/다시하기 | 1646:5456 / 1646:5459 | Glass radius≈3.6; refraction≈0.8; depth=18; lightAngle=-45; dispersion=.5; Fill White α=.74 | 활성 |
| FOCUS | Room background image | 1654:10122 | Progressive Layer Blur radius≈4.263, startRadius=0; 이미지 FILL | 활성 |
| FOCUS | 상단 목표 카드 | 1654:10142 | Glass radius=11; refraction=.25; depth=84; dispersion=.2; Gradient Paint opacity=.58 | 활성 |
| FOCUS | 타이머 라벨 | 1654:10134 | Drop Shadow: #000 alpha=.26; x=1 y=3 blur=5 spread=0 | 활성 |
| FOCUS | 타이머 숫자 | 1654:10137 | Drop Shadow: #000 alpha=.10; x=1 y=3 blur=6.8 spread=0 | 활성 |
| FOCUS | 원형 일시정지 배경 | 1654:10139 | Glass radius≈3.6; refraction≈.8; depth=18; Fill White alpha=.30 | 활성 |
| MAKING | 인형 미리보기 카드 | 1654:10404 | Glass radius≈6.349; refraction≈.8; depth≈31.746 | 활성 |
| MAKING | 인형 배경의 광원 타원 | 1654:10405 | Layer Blur radius≈43.348; Fill #D4EEF6 | 활성 |
| COUCH | 플레이어 외곽 카드 | 1655:4993 | Drop Shadow blur≈10.3, y=4 alpha=.25, source effect.visible=false | INACTIVE_SOURCE |

**렌더링 규칙:** Glass/Progressive Blur 등의 효과는 단색이나 보통 그림자로 임의 치환하지 않는다. 렌더 엔진이 지원하지 않는 효과라면 해당 Figma Node를 재사용하거나 시각적 차이를 `UNVERIFIED / ENGINE_LIMITATION`으로 보고한다. 비활성 Shadow는 켜지 않는다.

## 07. Button System — 역할·상태·폰트·크기까지 구분

**사용자 지정 위계:** `Disabled → Alpha 적용`, `Default → White`, `CTA → Black Gradient`, `Selected → Sky Blue Gradient`. 단, 현재 대표 화면에서 확인된 **'이전으로'**는 Disabled가 아니라 **정상적으로 보이는 흰색 보조 버튼**이다. 디자인 시스템의 `State=Disabled` Variant가 이 버튼을 사용해 붙인 명칭은 **원본의 실제 상태와 불일치**한다. 이 오류를 문서에서 감추지 않는다.

| 역할 | UI | 원본 ID | 크기 px | Radius | Fill | Font / Label | 기타 스타일 | 적용 조건 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Secondary / white | 이전으로 | 1654:10394 | 171 × 60 | 31.75 | #FFFFFF 100% | Pretendard Medium 16/500, LH28, LS+5%, #1F1F1F | Figma Gradient Stroke #EEEEEE→#E8E8E8 | 보이는 정상 버튼. Disabled로 취급 금지 |
| Default / white | 초기화 | 1646:5462 | 74 × 38 | 19 | #FFFFFF 100% | Pretendard Regular 14/400, Auto, LS -3%, #000000 | 검정 Stroke 비활성, 손그림 외곽선·아이콘 별도 | Room reset |
| CTA / dark gradient | 다음으로 | 1654:10395 | 171 × 60 | 31.75 | G-03 #454545→#212226 | Pretendard Medium 16/500, LH28, LS+5%, #FFFFFF | 이전/다음 액션 그룹에서 오른쪽 | MAKING CTA |
| CTA / dark gradient | 홈에서 계속 보기 | 1655:4998 | 343 × 46 | 31.75 | G-03 #454545→#212226 | Pretendard Medium 16/500, LH28, LS0%, #FFFFFF | 전체 하단 주요 액션 | COUCH CTA |
| Selected / sky gradient | 🐻 곰돌이 | 1654:10409 | 84.11 × 32.91 | 18.29 | G-02 #FEFEFE→#C5EFFC | Pretendard Regular 12.743/400, LH150%, LS-5%, #000000 | Stroke #B2DDEA, 0.7px | MAKING Selected |
| Default / choice | 🐰 토끼 / 🐈 고양이 | 1654:10407 / 1654:10411 | 76.8×31.09 / 80.46×31.09 | 18.29 | #FFFFFF 100% | Pretendard Regular 12.743/400, LH150%, LS-5%, #000000 | 검정 Stroke source.visible=false | MAKING Unselected |
| Undo / Redo | 되돌리기·다시하기 | 1646:5456 / 1646:5459 | 37 × 37 | 42 | #FFFFFF 74% | 아이콘 중심 / 본문 라벨 없음 | Glass effect radius3.6 | ROOM icon actions |
| Media Control | 이전 영상·다음 영상 | 1655:4994 / 1655:4995 | 44 × 44 | 22 | #F0F5F8 100% | 아이콘 중심 / 본문 라벨 없음 | 중앙 재생은 별도 버튼 58.5×58.5 | COUCH media control |
| Focus Pause | 현재 표시되는 일시정지 | 1654:10138 / 1654:10139 | 73.56 × 73.56 | 원형 | #FFFFFF 30% | 일시정지 벡터 1654:10140 | Glass, 배경 위 오버레이 | FOCUS media control |
| Disabled (규칙만 존재) | 비활성화 일반 규칙 | UNVERIFIED | UNVERIFIED | UNVERIFIED | 실제 역할별 Fill + Alpha < 100% | Font/Color는 그 버튼의 활성 상태를 참조 | 정확한 alpha·button geometry 미확인 | 실제 비활성 사례 추가 검수 필요 |

### 07.1 실제 마스터와 문서 해석

- Figma 마스터 `Button / Four source roles` = `1676:4218`: `State=Default`, `CTA`, `Selected`, `Disabled` 네 Variant 존재.
- **ISSUE-BTN-01:** `State=Disabled`의 바탕이 된 `1654:10394`는 흰색·Opacity 100%의 `이전으로` 보조 버튼이다. **지금 마스터 이름만 믿고 알파 100%의 비활성화를 구현하면 사용자 규칙 위반**. 해당 Variant는 정확한 Disabled 데이터로 취급하지 않는다.
- **Disabled 구현 가능 범위:** 비활성 기능 여부는 기존 프로토타입의 `enabled` 상태를 따르고 **Alpha를 낮춰야 한다**는 역할 규칙은 확정. 낮출 정확한 불투명도는 `UNVERIFIED`; 기존 프로젝트에서 검증된 Disabled 컴포넌트가 발견되면 그 값을 사용하고, 없으면 사용자 승인 없이 숫자를 발명하지 않는다.
- `State=Selected`는 인형 선택 칩의 *선택된 값*에 대응한다. 다른 화면의 CTA를 Selected 파랑으로 바꾸는 것이 아니다.
- 같은 CTA라도 `MAKING: 171×60`과 `COUCH: 343×46`처럼 레이아웃에 따라 크기가 다르므로 `Size=Flow-specific`으로 구분하고 복제본의 텍스트와 기능만 바꾼다.
- `FOCUS` 원형 일시정지는 CTA 그라데이션 버튼으로 바꾸지 않는다. 컨텍스트 전용 컨트롤이다.

## 08. Component Specifications — 재사용 단위와 전용 단위

기본 컴포넌트 스펙은 **출처 Node + 역할 + 속성 + 상태 + 사용 조건**으로 기록한다. Figma 인스턴스에서 최상위 컴포넌트 Fill과 자식 레이어가 다를 수 있으므로 자식 구조를 유지한다.

| 컴포넌트 | 적용 범위 | Source Nodes | Geometry & Style | 사용 조건 / 유의 |
| --- | --- | --- | --- | --- |
| Navigation / Back | ROOM/FOCUS/MAKING/COUCH | 1646:5500 / 1654:10136 / 1654:10402 / 1655:4997 | 약 32×32; Focus 화면에는 38×38 | 상단 왼쪽, 화면별 대조 / 기존 Back 행동 유지 |
| Room / Background | ROOM | 1646:5443 | 390×390, y132; 내부 Room 이미지 | 방 편집 전용; Focus 실사 배경으로 대체 금지 |
| Character / In-scene | ROOM | 1646:5450 / 1654:10492 | 약 65×72 / 63×87, 소스 인스턴스 | 방 내 인형은 룸 씬에 자연스럽게 중첩 |
| Furniture / Selected Chair | ROOM | 1646:5451 | 113.1×113.1, x306.3 y327.3 | 4가지 변형 인스턴스 중 하나만 보임; hidden others 유지 |
| Room / Undo-Redo | ROOM | 1646:5456 / 1646:5459 | 37×37, White 74%, Glass | 방 조작 이력 연동 |
| Room / Reset | ROOM | 1646:5462 | 74×38, White, Pretendard 14 Regular | 선택/배치 초기화 연동 |
| Room / Tooltip | ROOM | 1646:5465 / 1646:5469 | 100×60; 내용 몸체 100×52 R16 | 드래그 안내, 기능에 맞게 내용 변경 가능 |
| Room / Bottom Editor | ROOM | 1646:5472 | 390×325, y544, White | 4개 탭과 가구 카탈로그 목록 유지 |
| Furniture / Card | ROOM | 1646:5478 / 1646:5480 | 104.89×83.16 R13.23, 선택 sky Gradient/비선택 #F2F2F2 α70% | 선택 상태일 때 Gradient/Stroke, 비선택 opacity 69% |
| Focus / Room Image | FOCUS | 1654:10122 | 450.87×1032.51 x-32.86 y-188.51, progressive blur | 현재 보이는 Background Image, 이미지 교체 금지 |
| Focus / Goal Progress Card | FOCUS | 1654:10141 / 1654:10142 | 326×66 R15, G-05 opacity58% + Glass | 오늘 목표 + 달성률 + 작은 Progress |
| Focus / Timer Overlay | FOCUS | 1654:10133 | 390×424, y422; G-04 | 카드가 아닌 하단 오버레이 |
| Focus / Countdown | FOCUS | 1654:10134 / 1654:10137 | Label 17px Bold; Timer 62px Regular | 라벨과 숫자의 서로 다른 계층 |
| Focus / Pause Control | FOCUS | 1654:10138 / 1654:10139 / 1654:10140 | 73.56 원형 Glass + pause vector | 오버레이와 같이 배치; 숨겨진 D1/ Icon button 제외 |
| Focus / Bottom Set Progress | FOCUS | 1654:10147 / 1654:10148 | 324×37.4 y736; track+fill+시간 라벨 | 휴식·세트 정보; Media progress와 용도 다름 |
| Making / Five Steps | MAKING | 1654:10380 | 342×35, 5 상태 텍스트, track 322.2×7.9 | 완료✓/진행●/미래○의 상태를 실제 플로우 단계로 변환 |
| Making / Hero Character | MAKING | 1654:10403 / 1654:10404 / 1654:10406 | 334.92×383.31 White GLASS / Bear asset 265.1×364.9 | 캐릭터 모양 선택/미리보기 기능 유지 |
| Making / Preset Custom | MAKING | 1654:10396 / 1654:10398 | 133.1×38.7, sky gradient selected segment | 두 가지 모드 전환 |
| Making / Shape Chips | MAKING | 1654:10407 / 1654:10409 / 1654:10411 | White 일반 / Sky Gradient selected, R18.29 | 모양 선택값과 연결 |
| Making / Prev-Next Actions | MAKING | 1654:10393 / 1654:10394 / 1654:10395 | 354×60, White+Black Gradient 171px×2, gap12 | 이전/다음 단계 네비게이션 보존 |
| Couch / Character Asset | COUCH | 1655:4988 / 1655:4996 | Felt couch scene 336×139; Bear 190×248 | 소파 캐릭터와 영상 플레이어 사이 Z-order 보존 |
| Couch / Player Container | COUCH | 1655:4993 | 358×364 R21, 실제 White | 화면 중앙 플레이어 섹션 |
| Couch / Video Player | COUCH | 1655:5003 | 329×184 R14, G-09 | 재생 콘텐츠/출처/시간/진행 표시 |
| Couch / Playback Buttons | COUCH | 1655:4994 / 1655:4995 / 1655:5000 | 이전/다음 44×44, 가운데 약 58.5×58.5 | 제어 기능 유지 |
| Couch / Playlist Change | COUCH | 1655:5017 / 1655:5025 / 1655:5026 | 330×46 White row, Label 14 Regular | 플레이리스트 선택·변경 |
| Couch / Main CTA | COUCH | 1655:4998 | 343×46 Black Gradient; label16 Medium | 홈에서 계속 보기 액션 |
| Couch / Exit Secondary | COUCH | 1655:4999 | Text 12 Medium #707070, y778 | 그만 보기 수행 |

### 08.1 원본 Component/Instance 보존

- 기존 Figma 인스턴스가 존재하면 가능한 한 **원본 인스턴스를 재사용하고 텍스트·상태·에셋만 변경**한다. 신규 의미/크기가 다른 Variant가 필요할 때만 확장하고 이름으로 구분한다.
- 4개 화면에 없는 `Modal`, `Bottom sheet`, `Input`, `Tab` 상태를 억지로 대표 화면에 추가하지 않는다. 대상 플로우에 원래 존재하면 그 기능과 입력 상태를 유지하되, 공통 텍스트/버튼/레이아웃 어휘를 적용한다.
- 버튼, 선택 칩, 미디어 제어, 타이머, 제작 단계 표시, 가구 카드 등 **동일해 보이는 요소도 기능·상태가 다르면 합치지 않는다.**
- 실제 이미지 에셋은 `IMAGE` Fill 또는 컴포넌트 인스턴스 내부에 있을 수 있다. 원본 Figma 접근이 없으면 `ASSET_DEPENDENCY`이며 임의 대체 금지.

## 09. Background System — 동일한 미색으로 통일 금지

| Screen | Canvas | 전체 Frame Fill | 시각 레이어 | 원본 ID | 주의 |
| --- | --- | --- | --- | --- | --- |
| ROOM | 390×844 R28 | G-01 #FEFEFE→#E1F8FF, Paint opacity100% | Room 390×390 at (0,132); character; lower white sheet | 1646:5442 / 1646:5443 | 상단은 밝은 gradient, 실제 방 이미지는 중간, 시트는 y544부터 |
| FOCUS | 390×844 R28 | Frame SOLID #F9F9F9 100% + Black α20% Fill 조합 | Room image (x−32.86,y−188.51,w450.87,h1032.51), progressive blur; Timer G-04 y422→846 | 1654:10121 / 1654:10122 / 1654:10133 | 40% Black rectangle 1654:10123은 **hidden**. 보이는 암부는 하단 Gradient 중심. |
| MAKING | 390×844 R28 | Frame #F9F9F9 + G-07 Paint opacity25% | White hero R22, sky blurred ellipse, character image | 1654:10366 / 1654:10404 / 1654:10405 | 카드/선택 칩/다음 버튼의 각각 다른 Fill을 유지 |
| COUCH | 390×844 R28 | White + #F9F9F9 + G-07 Paint opacity25% (다층 Fill) | Felt sofa + Bear, White player R21, interior blue G-09 | 1655:4987 / 1655:4993 / 1655:5003 | Outer card의 Gradient는 hidden; 플레이어 내부는 실제 Gradient |

### 09.1 배경 레이어 합성 및 에셋

**ROOM:** Root gradient → `Room/background` 이미지/3D 씬(y132) → 캐릭터·선택 가구 → Room Editor Bottom Sheet(y544) → 개별 조작 버튼·네비게이션. **원본 화면의 Z-order와 visible 값을 유지**한다.

**FOCUS:** 이미지 Background는 (−32.86,−188.51)에서 크게 확대/크롭되어 있다. 이 이미지를 미색 평면으로 대체하지 않는다. 하단 Gradient G-04가 y422에서 시작하며 844px 높이 하단으로 흐르고, 상단 목표 카드와 하단 타이머 텍스트가 그 위에 놓인다. 숨김 `1654:10123`(Black 40%)은 사용자에게 보이지 않으므로 **자동 활성 금지**. 숨김 작업대 `1654:10124`와 바닥 연장 `1654:10130`도 기본 렌더에는 표시하지 않는다.

**MAKING:** Frame Fill은 base #F9F9F9와 opacity 25%의 G-07을 함께 갖는다. 중앙 Hero는 white Glass R22이며 소프트 sky 광원 효과와 인형 이미지를 계층적으로 쌓는다. 선택 칩의 Gradient는 Frame 전체 Gradient와 **다른 정의**다.

**COUCH:** Frame의 여러 Fill + 카드는 실제 white. **배경이 그라데이션이라고 해서 플레이어 외곽 카드를 파란 Gradient로 채우지 않는다.** 플레이어 내부 G-09만 파란 쪽으로 진행하는 밝은 3-stop Gradient이고, 실제 동영상 재생 콘텐츠로 대체될 수 있다.

### 09.2 에셋 참조 의존성

- Room 3D 원본 인스턴스: `1646:5443`, 내부 이미지 `I1646:5443;32:2518`.
- Focus 방 이미지: `1654:10122` (Progressive Blur 포함).
- Making 캐릭터: `1654:10406`; Couch 곰 인스턴스 `1655:4996`; 소파 아트 `1655:4988`.
- 이미지 URL/파일 바이트는 이 문서에 포함되지 않는다. Figma의 원본 노드·내부 에셋에 접근하여 재사용한다.
- 가로모드/태블릿의 정확한 레이아웃 값은 이 4개 기준 화면만으로 **UNVERIFIED**. 모바일 세로의 x/y를 가로에 그대로 확대하지 말 것.

## 10. Layout & Visual Hierarchy — 390×844 원본 좌표 기준

네 기준 화면은 모두 Root Frame `layoutMode=NONE`에 절대 배치된 실제 UI를 포함한다. 하위의 일부 그룹은 `HORIZONTAL`/`VERTICAL` Auto Layout이지만, Root의 절대 좌표 전체를 균일한 Auto Layout으로 변환하지 않는다. 현재 Viewport 크기를 기준으로 다음 **구조·상대 앵커·Z-order**를 유지한다.

### 10.1 기준 화면 앵커

| Screen | 요소 | Top-left x,y | Frame size | 시각적 역할 | Node |
| --- | --- | --- | --- | --- | --- |
| ROOM | Root | 0,0 | 390×844 | Root #FEFEFE→#E1F8FF | 1646:5442 |
| ROOM | Header title | 114.7,58 | 161×29 | Gmarket Sans 25.397 Medium | 1646:5499 |
| ROOM | Background 3D room | 0,132 | 390×390 | IMAGE / room instance | 1646:5443 |
| ROOM | Character | 125.1,261.6 | 65×72 | Cotton/State6 | 1646:5450 |
| ROOM | Selected chair | 306.3,327.3 | 113.1×113.1 | Furniture variants | 1646:5451 |
| ROOM | Undo / Redo | 23.2,494 / 71,494 | 37×37 each | White 74%, Glass | 1646:5456 / 1646:5459 |
| ROOM | Reset | 296,493.9 | 74×38 | White general button | 1646:5462 |
| ROOM | Bottom editor | ≈0,544 | 390×325 | White + Tabs + Catalog | 1646:5472 |
| FOCUS | Image room | −32.9,−188.5 | 450.9×1032.5 | IMAGE blur / center cropped | 1654:10122 |
| FOCUS | Back | 21,55.3 | 38×38 | Transparent icon | 1654:10136 |
| FOCUS | Goal progress | 31.8,125 | 326×66 | Glass + G-05 | 1654:10142 |
| FOCUS | Bottom overlay | 0,422 | 390×424 | G-04 | 1654:10133 |
| FOCUS | Current focus label | 38,621.3 | 91×26 | 17 Bold White | 1654:10134 |
| FOCUS | Large timer | 32.1,641.7 | 224×80 | 62 Regular White | 1654:10137 |
| FOCUS | Pause control | 287.7,638.4 | 73.56×73.56 | Glass circle + pause icon | 1654:10138 |
| FOCUS | Bottom progress | 33,736 | 324×37.4 | Track + Fill + Labels | 1654:10147 |
| MAKING | Title | 123,58 | 144×29 | Gmarket Sans 25.397 Medium | 1654:10378 |
| MAKING | Step strip | 23.8,128.3 | 342×35 | 5 steps / track / fill | 1654:10380 |
| MAKING | Hero preview | 26.75,187 | 334.92×383.31 | White Glass / Bear | 1654:10403 |
| MAKING | Preset/Custom | 20.9,587 | 133.1×38.7 | White+Sky segment | 1654:10396 |
| MAKING | Instruction | 24,642.1 | 158×20 | Pretendard 14 Regular | 1654:10413 |
| MAKING | Selected shape | 24,669.4 | 84.11×32.91 | Sky Gradient / Stroke | 1654:10409 |
| MAKING | Prev / Next | 18,734 | 354×60 | 171+12gap+171 | 1654:10393 |
| COUCH | Title | 124,62.5 | 158×32 | Gmarket Sans 28 Medium | 1655:4992 |
| COUCH | Bear | 103.5,96.7 | 190×248 | Character asset | 1655:4996 |
| COUCH | Sofa art | 31.5,207.8 | 336×139 | Felt sofa scene | 1655:4988 |
| COUCH | Outer player card | 16.46,338.8 | 358×364 | White R21 | 1655:4993 |
| COUCH | Player | 31,353 | 329×184 | 3-stop G-09 | 1655:5003 |
| COUCH | Prev/Next player controls | 99,567.3 / 247,567.7 | 44×44 | Soft gray circles | 1655:4994 / 1655:4995 |
| COUCH | Playlist change | 30,640.8 | 330×46 | White row | 1655:5017 |
| COUCH | Main CTA | 23.5,717.5 | 343×46 | G-03 | 1655:4998 |
| COUCH | Exit supporting | 172.5,778.1 | 45×28 | #707070 text | 1655:4999 |

### 10.2 위계 기준

- **ROOM**: Primary = 방 씬과 실제 가구/인형. Secondary = 편집 시트의 선택 카탈로그. Supporting = Undo/Redo, Tooltip, Reset. Navigation = Back/Header.
- **FOCUS**: Primary = 실사 공간 + `00:18:42`과 원형 Pause. Secondary = 상단 오늘 목표 카드 + 하단 세트/휴식 프로그레스. Supporting = 시간 라벨. **기존 흰색 타이머 카드보다 공간의 몰입이 우선**.
- **MAKING**: Primary = 큰 중앙 인형 미리보기. Secondary = 단계 상태와 선택 칩. Actions = 아래 White 이전 / Black 다음. Supporting = 설명·프리셋 전환.
- **COUCH**: Primary = 곰과 소파 + 영상 플레이어. Secondary = 영상 조작/플레이리스트 변경. CTA = 검정색 하단 주요 버튼. Supporting = 회색 종료 텍스트.

### 10.3 구조 원칙

- Safe Area 값은 화면별 상태바·홈 인디케이터 실측으로 표현되며, 이 자료만으로 iOS/Android 모든 기기의 Safe Area를 확정하지 않는다.
- `y=831` Home Indicator처럼 시스템 영역을 고려한다. 헤더/하단 액션을 시스템 바 아래로 밀어내지 않는다.
- 일부 내부 Figma 인스턴스 좌표는 **부모에 상대적**이고, 다른 그룹의 자식은 캔버스 절대처럼 기록되어 있다. 아래에 적힌 `x,y`는 해당 Node의 Figma 원본 좌표다. 부모 계층을 복제할 때는 **절대 합산을 임의로 하지 말고** Figma의 `absoluteBoundingBox`/visual bounds로 검증한다.
- 기준 프레임의 가로모드 Constraint, 스크롤 복구, 반응형 타이포 대응은 `UNVERIFIED`다. 대상 플로우에 이미 구현된 세로·가로 UI가 있으면 기능별 구조를 보존해 확장하고 새 수치를 추정하지 않는다.

## 11. Progress, Timer & Status — 혼용 금지

| UI | Screen | Figma Source | Geometry | Visual | 데이터/라벨 | 금지 |
| --- | --- | --- | --- | --- | --- | --- |
| Focus Today Goal | FOCUS | 1654:10141 / 1654:10142 | 326×66 x≈31.8 y125 | G-05 α58%/Glass R15 | 오늘 목표 + 1시간25분·62% + 트랙287.2×7.9 + 채움169.4×7.9 | 최상단, 미디어 영상 Progress와 무관 |
| Focus Timer | FOCUS | 1654:10134 / 1654:10137 | 라벨 91×26 x38,y621; 숫자224×80 x32,y642 | White, 17 Bold / 62 Regular, 그림자 | 현재 집중 시간 / 00:18:42 | 백그라운드 위 텍스트 오버레이, 흰 타이머 카드 금지 |
| Focus Session/Rest | FOCUS | 1654:10147–1654:10154 | 324×37.4 x33 y736 | 트랙 #D9D9D9 α20 / 채움 #D4EEF6 / 10.5px White | 두 번째 세트 18:01 / 휴식까지 05:18 | 하단 타이머 전용 진행 그룹 |
| Making Five Steps | MAKING | 1654:10380–1654:10392 | 342×35 x23.8 y128.3 | Track #D9D9D9 α60, 322.2×7.9 / Fill #D4EEF6 181×7.9 | ✓ 사진 / ✓ 투명화 / ● 모양 / ○ 꾸미기 / ○ 완성 | 상태/완료 색 #181818·미완료 #9A9A9A |
| Couch Video Progress | COUCH | 1655:5012–1655:5015 | track312×3.9 x10,y167 (player-relative); fill108×4 | Track #FFFFFF α40 / Fill #FFFFFF α100, R2 | 1:12 / 3:40, Scrubber12×12 | 동영상 컨트롤; 오늘 목표나 제작 Step에 사용 금지 |

- 숫자와 진행률 문자열은 예시 데이터다. 실제 적용 시 기존 타이머/영상/세트 상태 로직에서 값만 바인딩한다. 소스의 62%를 모든 사용자에게 고정하지 않는다.
- 일시정지·재개·종료·휴식 전환은 대상 프로토타입에 존재하던 인터랙션을 유지하고, 표시 방식만 기준 화면에 맞춘다.
- 원래 없는 타이머나 프로그레스 바를 전체 화면에 공통 삽입하지 않는다.

## 12. Screen Specification — ROOM / 방꾸미기

**Source:** `1안 · 방꾸미기` (`1646:5442`), 390×844, R28. 이 화면은 방꾸미기/가구 선택/벽지/바닥재/소품 편집 흐름의 디자인 기준이며, Focus 타이머나 영상 플레이어의 시각적 템플릿이 아니다.

### 12.1 레이어 스택 (표시되는 구조)

```text
ROOM FRAME 390x844 [G-01 gradient #FEFEFE → #E1F8FF]
├─ Status bar & system icons: time 9:41 near x26 y14
├─ Back icon x23.5 y58.7 / title 'edit my room' y58
├─ 3D Room background instance x0 y132 w390 h390
│  ├─ Furniture instance(s), selected chair at x306 y327
│  ├─ Character Cotton / bear instances centered in room
│  └─ Instruction bubble: x208 y255 w100 h60
├─ Floating controls near y494
│  ├─ Undo x23.2 / Redo x71, each 37x37 White α74% + Glass
│  └─ Reset x296 74x38 White, 14px Regular
├─ Bottom editor sheet y544, 390x325 White
│  ├─ Tabs: 가구(활성) / 벽지 / 바닥재 / 소품
│  └─ Furniture catalog: selected gradient card, unselected subdued cards
└─ Home indicator x128.5 y831 134x4 R2
```

### 12.2 상세 규칙

- 카탈로그 선택된 가구 카드의 소스는 `1646:5478`: 104.89×83.16 R13.23, G-02 선택 배경과 Stroke #B2DDEA. 이 카드 레이블은 Pretendard Medium 12.285px.
- 비선택 카드 `1646:5480` 등은 #F2F2F2 Alpha70% Fill, Node 자체 opacity≈69%, 라벨 #000000 Alpha78%. **선택된 그라데이션과 구분**한다.
- Room Editor의 4개 탭은 상단 y≈12.9(시트 상대) 위치하며 현재 탭 레이블은 opacity100%, 나머지 비선택은 약48% Node opacity. 실제 탭 전환 시 선택 상태를 교체한다.
- 방의 에셋·가구를 목록의 썸네일과 다른 것으로 자동 변형하지 않는다. 가구 변형 인스턴스 중 `pinkA`가 활성이고 `pinkB` 등 다른 인스턴스는 hidden이다.
- 하단 시트가 존재하기 때문에 상단 룸 콘텐츠를 화면 전체에 Fill하는 Focus 방식으로 교체하지 않는다.

### 12.3 다른 Room 플로우로 확장

- `방꾸미기/01 가구 탭`과 `02 가구 선택`: 같은 Room background, 선택/비선택 카드 Variant, Editor Sheet. 상태·선택값만 변경.
- `03 벽지`, `04 바닥재`, `05 소품`: **탭/선택 목록 내용만 변경**; Room 3D 씬·시트 위치·상단 헤더 구조는 동일 디자인 언어.
- `06–09 꾸미기 및 소품 추가`: 기존 배치·드래그·색상·사진 편집 기능을 유지하며 Room의 Controls/Sheet 패턴 재사용.
- `10 나가기 확인`: 원본 Exit Confirmation 기능 유지. Sheet가 아니라 Modal이면 Modal 기능을 보존하고 공통 Typography/Button을 적용. Room 화면 전체를 Exit Modal로 복제하지 않는다.

## 13. Screen Specification — FOCUS / 집중 진행

**Source:** `03 · 집중 중 · A` (`1654:10121`). 이전에 실패했던 적용 사례의 **필수 전체 구조 교체 기준**이다. 카드 내부에 타이머가 있는 오래된 UI를 꾸미는 것이 아니라 배경·위계·타이머 위치 자체를 기준 화면으로 바꾼다.

### 13.1 렌더 상태가 확인된 실제 레이어 스택

```text
FOCUS FRAME 390x844 [base #F9F9F9 + Black Fill α20%]
├─ FULL-BLEED Room background IMAGE x-32.86 y-188.51 w450.87 h1032.51
│  └─ visible Progressive Layer Blur radius≈4.263
├─ [HIDDEN] Black rectangle #000000 α40%, x-9.5 y-12.6 w420 h857.4
├─ [HIDDEN] Separate editable workbench & Floor continuation
├─ Top system status and Back x21 y55.3 w38 h38
├─ Goal panel group x31.8 y125 w326 h66
│  ├─ Glass + Gray gradient G-05 opacity58%, R15
│  ├─ '오늘 목표' / '1시간 25분 · 62% 달성'
│  └─ Goal progress track #D9D9D9 α20 → fill #D4EEF6
├─ Timer contrast overlay G-04 x0 y422 w390 h424
│  ├─ '현재 집중 시간' x38 y621 17px Bold white
│  ├─ '00:18:42' x32 y642 62px Regular white
│  ├─ Visible Pause circle x287.75 y638.37 d73.56 + Glass
│  └─ Bottom session/rest progress x33 y736 w324 h37
└─ Home indicator x128 y831 w134 h4, #6E5244, Node opacity80%
```

### 13.2 필수 구현 값

- 전체 공간은 **실사 방 이미지가 화면에서 큰 비중을 차지**한다. 새로운 실사 에셋을 생성하지 말고 `1654:10122`를 그대로 참조한다.
- `1654:10123` 검정 40% Rectangle은 **숨김**이므로 보이는 기본 UI에 추가하지 않는다. 이미지가 이미 충분히 대비를 갖추도록 하단 G-04를 표시한다.
- G-04: #000000 **Stop Alpha2%** → #172F36 **Stop Alpha100%**, Fill opacity100%. 시작 y=422, 높이=424.
- 상단 패널: 326×66, y125. 목표 레이블/진행률 숫자 위주이며 `Glass`로 가벼운 중첩감을 준다.
- 타이머 숫자: `62px/400/80px`, `#FFFFFF`, 음의 Letter Spacing, x≈32,y≈642. **화이트 카드에 중앙 00:18:42 배치 금지.**
- Pause: 현재 표시되는 Group `1654:10138` 안의 Ellipse `1654:10139`(White Alpha30%, Glass) + Vector `1654:10140`. 숨겨진 D1 Icon Button `1654:10135` (77×77 Green)을 사용하는 대신 보이는 원형을 우선한다.
- 타이머 하단 정보: `두 번째 세트`, `휴식까지`, 시간 숫자, 하단 bar의 실제 위치/비율을 보존하되 표시 데이터는 기존 타이머에서 공급한다.
- 상단·중앙·하단의 내용 위계를 **한 프레임에 큰 카드 하나로 재합성하지 않는다**.

### 13.3 상태별 매칭

- `집중 중 A/B`: Focus 기준 화면의 레이아웃 구조를 기본으로 적용. A/B는 기존 프로토타입의 선택 조건이 다르면 그 상태 차이를 유지.
- `집중 일시정지 A/B`: 동일 공간·Timer Overlay 구조를 유지하면서 재개/일시정지 등 기존 상태별 Controls와 문구를 반영. 애니메이션·타이머 값이 정지하는 동작도 유지.
- `쉬는 시간 A/B`: 이미지와 오버레이 디자인 어휘는 참조하되 `휴식` 상태 레이블·진행 방식이 달라진다면 원래 기능을 따르며, Focus '현재 집중 시간'을 무조건 그대로 복제하지 않는다.
- `집중 메인/설정/인형 선택`: Focus *기능 계열*이지만 진행 중 타이머 화면은 아니다. 공통 Typography·Back·타이머 관련 스타일은 재사용하되, 본래의 리스트·설정·선택·Sheet를 삭제하지 않는다.

## 14. Screen Specification — MAKING / 인형 제작

**Source:** `개선 / 08 · 모양 선택 / 기본 모양` (`1654:10366`). `선택 가능한 인형 모양`에 초점을 둔 제작 단계 화면이다. 제작 플로우 전체로 확장할 때 개별 단계의 실제 기능을 바꾸지 않는다.

### 14.1 구조와 Z-order

```text
MAKING FRAME 390x844 [#F9F9F9 + G-07 α25%]
├─ Status bar / Back icon x≈24 y≈59 / 'making fluff' title x123 y58
├─ Five-step progress header x23.8 y128.3 w342 h35
│  ├─ ✓ 사진 / ✓ 투명화 [completed]
│  ├─ ● 모양 [current]
│  ├─ ○ 꾸미기 / ○ 완성 [future]
│  └─ Track 322.2×7.9 #D9D9D9 α60 / Fill 181×7.9 #D4EEF6
├─ Hero preview x26.75 y187 w334.92 h383.31
│  ├─ White Glass R22
│  ├─ Sky soft glow Ellipse x43.97 y335.95 294.76×178.27 (Layer Blur43.35)
│  └─ Bear image instance x63.3 y205.4 265.1×364.9
├─ Preset/Custom segmented control x20.9 y587 w133.1 h38.7
├─ Prompt x24 y642: '함께할 인형 모양을 골라주세요'
├─ Choice chips y669: [🐻 곰돌이 selected] [🐈 고양이] [🐰 토끼]
├─ Actions x18 y734 w354 h60: [이전으로 White 171] gap12 [다음으로 Dark 171]
└─ Home indicator x128 y831 w134 h4
```

### 14.2 색상·타이포·상태

- 제목 `Gmarket Sans TTF Medium` 25.397px, #080808. 실제 source `1654:10378`.
- Step bar: completed/current #181818 텍스트 12/500, future #9A9A9A, 같은 고정 5단계 프레임이지만 실제 단계 진행 시 활성 Step index를 바꾼다.
- 선택 칩은 `🐻 곰돌이`가 G-02 Sky gradient, `Stroke #B2DDEA 0.7px`, R18.29, 84.11×32.91. `토끼/고양이`는 White R18.29, 검정 Stroke는 source.visible=false.
- `프리셋/커스텀` 전환은 전체 133.1×38.7 White + Sky 세그먼트, 모드별 상태를 유지한다.
- CTA와 보조 버튼을 둘 다 검정색으로 만들지 않는다. `이전으로 White`와 `다음으로 G-03 Dark`가 **시각적 1·2위계**다.

### 14.3 다른 제작 단계로 확장

- 사진 선택/배경 지우기/위치 조절/사진 확인: **상단 단계 인디케이터·헤더·행동 위계는 공유**, 본래 입력/미리보기/포토 갤러리 기능은 단계에 맞게 유지한다.
- 얼굴 사진 조절/모양 조절/이름 짓기/인형 완성: 단계별 전용 컨텐츠의 실제 정보·상태를 보존하면서 크기·버튼·카드·아이콘 언어만 통일한다.
- 내 인형/인형 프로필/방에 배치하기는 인형 기능 계열에 속하더라도 **5단계 제작 Step을 무조건 표시하지 않는다**. 이 화면들은 목록·프로필·완료 상태 전용 구조를 가진다.
- 이탈 확인 모달: 제작 Step이 그대로 뒤에 남더라도 모달이 활성 화면이면 기존 확인·취소 인터랙션과 가독성 요구를 우선한다.

## 15. Screen Specification — COUCH / 함께 보기

**Source:** `S-4 · 소파에서 같이 보는 중` (`1655:4987`). 공간 속 캐릭터와 실제 미디어 컨트롤이 결합된 특수 화면이다.

### 15.1 구조 및 레이어

```text
COUCH FRAME 390x844 [White, #F9F9F9, G-07 α25% stacked]
├─ Status bar & Back x23.3 y58.7
├─ 'couch time' Gmarket Sans 28 Medium x124 y62.5
├─ Bear character x103.5 y96.7 w190 h248
├─ Felt sofa artwork x31.5 y207.8 w336 h139
├─ White outer media card x16.46 y338.8 w358 h364 R21
│  ├─ Video UI x31 y353 w329 h184 R14 G-09
│  │  ├─ Media text / source / moon + hill art
│  │  ├─ Track312×3.9 α40% / Progress108×4 solid White
│  │  └─ Scrubber12×12 / timestamp '1:12 / 3:40'
│  ├─ Prev x99 y567 / Center Pause ~58.5d / Next x247 y568
│  └─ Playlist Change White row x30 y640.8 w330 h46
├─ Main CTA x23.5 y717.5 w343 h46 Black gradient G-03
├─ '그만 보기' text x172.5 y778 #707070 12 Medium
└─ Home indicator x128 y831 w134 h4 #4A352A
```

### 15.2 시각·행동 규칙

- 외곽 카드 R21, **실제 보이는 White Fill**. 숨겨진 Sky Gradient를 켜지 않는다.
- 콘텐츠 플레이어는 G-09 3-stop Gradient이며 source title `Rainy café mix ☕` 15/700 white, 출처 12/500 white Alpha90%, 재생시각 11/500.
- 미디어 제어 버튼: previous/next `44×44 R22 #F0F5F8`; 가운데 버튼은 약 58.5×58.5 `#DFF2F8`로 구별한다.
- 하단 CTA `홈에서 계속 보기`는 343×46, G-03 Dark Gradient, Label 16 Medium White. 텍스트 보조 액션 `그만 보기`는 #707070 12 Medium으로 위계 차이가 명확하다.
- `Playlist Change`는 White row, Label 14 Regular. CTA의 검정 Gradient를 입히지 않는다.

### 15.3 관련 플로우

- `S-3` 플레이리스트 선택 → 본래 선택 기능과 목록을 유지하되 미디어 카드·타이포·선택 상태 어휘를 재사용.
- `S-4` 같이 보기 → 해당 대표 화면을 **구조적으로 가장 직접적인 기준**으로 사용.
- `S-5` 홈 미니 플레이어 → **풀스크린 Player로 교체 금지**; 작은 플레이어 기능/위치를 유지하면서 관련 컴포넌트 스타일만 통일.
- `S-0`, `S-1`, `S-2` 및 라디오/ASMR/책상 관련 화면은 소파와 공간/재생 요소를 공유할 수 있지만 **자동 레이아웃 전면 교체는 검토 후 적용**한다.

## 16. Screen Name Matching Rules — 전체 화면 이름을 단순 문자열로만 비교하지 말 것

### 16.1 매칭 알고리즘

```pseudo
INPUT targetFrame(name, id, parentFlow, purpose, state, currentElements)
1. frameId가 이미 문서의 17절에 명시되면 해당 행을 우선한다.
2. 동일한 화면 이름이 여러 프레임에 존재할 수 있으므로 ID + parentFlow를 같이 확인한다.
3. 이름 완전 일치 → 기능 키워드 → 상위 플로우 → 화면 목적·행동 → 구조 유사성 순으로 매칭한다.
4. 대표 화면의 핵심 '기능'과 현재 화면의 상태가 일치하면 FULL 또는 STATE_ADAPT 판정.
5. 메인·설정·선택·리스트·스크롤·모달·완료 등 기능이 다르면 STYLE_ONLY / STATE_ADAPT로 제한.
6. 기존 콘텐츠, 입력 값, 내비게이션, 프로토타입 링크의 보존을 먼저 확보한다.
7. 레이아웃은 선택한 Scope의 범위 내에서만 교체한다.
8. 모호하면 REVIEW_REQUIRED로 기록하고 자동 전체 구조 변경을 중지한다.
```

### 16.2 적용 범위의 의미

- `FULL`: 해당 대표 화면과 목적·상태가 사실상 동일한 화면. 기존 UI가 다르면 배경·레이아웃·컴포넌트·정보 위계를 **대표 기준으로 전면 교체**. 기존 기능은 보존.
- `STATE_ADAPT`: 같은 구조 계열이나 일시정지·휴식·선택됨 등 상태가 다름. 기준 구조를 쓰되 버튼 행동·상태 문구·진행률 표현을 실제 상태에 맞춘다.
- `STYLE_ONLY`: 기능 계열은 같지만 설정·갤러리·프로필·목록·상세·미니뷰 등 화면의 목적이 다름. 공통 시스템을 적용하되 **대표 화면 구조 전체를 강제 복제하지 않음**. 필요 시 개별 구성요소를 교체.
- `REVIEW_REQUIRED`: 기능/레이아웃 매칭이 명확하지 않은 상태. 색상 토큰·타이포의 명확한 공통 요소만 적용 가능; 화면 전면 구조 변경은 보류.

### 16.3 중복 이름 및 기능 예외

- `03 · 집중 중 · A`는 원본 대표 `1654:10121`과 실제 플로우 내 `1639:4966`, `1648:4027` 등 **ID가 서로 다르다**. 이름으로 동일 노드를 추정하지 않는다.
- `03 · 사진 선택`, `04 · 배경 지우기`, `05 · 사진 위치 조절` 등이 두 영역에 반복된다. **각 ID를 별도 항목으로 추적**한다.
- `16 · 이탈 확인 모달`은 만드는 플로우 소속일 수 있어도 `MAKING` 5단계 화면 레이아웃을 모달 위에 그대로 덮어쓰면 안 된다.
- `R01 라디오`, `B-6 ASMR`, `S-0 홈`은 네 대표 기능과 단어 일부가 겹친다는 이유로 전체 화면을 자동 교체하지 않는다.

## 17. Full Flow Screen Mapping — 현재 확인된 67개 이름/ID

아래는 Figma 디자인 시스템의 `10 — Actual Flow Screen-Name Matching` 및 실제 플로우 섹션에서 식별된 대상 프레임이다. `Target Node ID`는 **작업 대상 원본**, `Reference Node ID`는 **시각적 기준**이다. 이 파일은 실제 적용용으로 준비한 문서이며 대상 화면 자체를 변경하지는 않았다.

### 17.1 ROOM — 방꾸미기 (10개)

| Target Node ID | Target Screen Name | Reference Node ID | Scope | 매칭 이유 | 적용 규칙 | 기존 기능·예외 |
| --- | --- | --- | --- | --- | --- | --- |
| `1639:5629` | 방꾸미기 / 01 · 가구 탭 | `1646:5442` | FULL | 방꾸미기 + 가구 선택 화면 | Room 이미지·하단 시트·가구 선택 스타일 적용 | 선택 가구·스크롤·드래그 데이터 유지 |
| `1639:5673` | 방꾸미기 / 02 · 가구 선택 | `1646:5442` | FULL | 방꾸미기 + 가구 선택 화면 | Room 이미지·하단 시트·가구 선택 스타일 적용 | 선택 가구·스크롤·드래그 데이터 유지 |
| `1639:5714` | 방꾸미기 / 03 · 벽지 탭 | `1646:5442` | STATE_ADAPT | 방꾸미기 기능/탭 상태 | Room 배경·Editor Sheet 구조 유지, 선택 탭/콘텐츠 교체 | 컬러/사진/소품 기능 보존 |
| `1639:5759` | 방꾸미기 / 04 · 바닥재 탭 | `1646:5442` | STATE_ADAPT | 방꾸미기 기능/탭 상태 | Room 배경·Editor Sheet 구조 유지, 선택 탭/콘텐츠 교체 | 컬러/사진/소품 기능 보존 |
| `1639:5804` | 방꾸미기 / 05 · 소품 탭 | `1646:5442` | STATE_ADAPT | 방꾸미기 기능/탭 상태 | Room 배경·Editor Sheet 구조 유지, 선택 탭/콘텐츠 교체 | 컬러/사진/소품 기능 보존 |
| `1639:5850` | 방꾸미기 / 06 · 꾸미기 · 기본 | `1646:5442` | STATE_ADAPT | 방꾸미기 기능/탭 상태 | Room 배경·Editor Sheet 구조 유지, 선택 탭/콘텐츠 교체 | 컬러/사진/소품 기능 보존 |
| `1639:5880` | 방꾸미기 / 07 · 꾸미기 · 컬러 | `1646:5442` | STATE_ADAPT | 방꾸미기 기능/탭 상태 | Room 배경·Editor Sheet 구조 유지, 선택 탭/콘텐츠 교체 | 컬러/사진/소품 기능 보존 |
| `1639:5920` | 방꾸미기 / 08 · 꾸미기 · 사진 | `1646:5442` | STATE_ADAPT | 방꾸미기 기능/탭 상태 | Room 배경·Editor Sheet 구조 유지, 선택 탭/콘텐츠 교체 | 컬러/사진/소품 기능 보존 |
| `1639:5953` | 방꾸미기 / 09 · 소품 추가 후 | `1646:5442` | STATE_ADAPT | 방꾸미기 기능/탭 상태 | Room 배경·Editor Sheet 구조 유지, 선택 탭/콘텐츠 교체 | 컬러/사진/소품 기능 보존 |
| `1639:5994` | 방꾸미기 / 10 · 나가기 확인 | `1646:5442` | STATE_ADAPT | ROOM 기능 계열, 모달 상태 | 기존 확인 모달 기능·배경 관계 유지 | Room 전체 화면을 확인 모달 위에 복제 금지 |

### 17.2 FOCUS — 집중/휴식 (13개)

| Target Node ID | Target Screen Name | Reference Node ID | Scope | 매칭 이유 | 적용 규칙 | 기존 기능·예외 |
| --- | --- | --- | --- | --- | --- | --- |
| `1639:4674` | 02 · 집중 중 | `1654:10121` | FULL | 집중 진행 중 시간 표시 | 실사 배경 + 목표 카드 + 하단 G-04/62px 타이머/원형 Pause | A/B 분기 및 상태/시간 유지 |
| `1639:4739` | 00 · 함께 집중할 인형 선택 · 통일안 | `1654:10121` | STYLE_ONLY | 집중 기능의 설정·시작·선택 화면 | 공통 타이포·헤더·버튼을 적용 | 진행 타이머 오버레이/원형 Pause 강제 금지 |
| `1639:4759` | 01 · 집중 메인 · 인형 사이즈 축소 | `1654:10121` | STYLE_ONLY | 집중 기능의 설정·시작·선택 화면 | 공통 타이포·헤더·버튼을 적용 | 진행 타이머 오버레이/원형 Pause 강제 금지 |
| `1639:4829` | 01 · 집중 메인 · 인형 사이즈 축소-스크롤 | `1654:10121` | STYLE_ONLY | 집중 기능의 설정·시작·선택 화면 | 공통 타이포·헤더·버튼을 적용 | 진행 타이머 오버레이/원형 Pause 강제 금지 |
| `1639:4899` | 02 · 집중 설정 · 통일안 | `1654:10121` | STYLE_ONLY | 집중 기능의 설정·시작·선택 화면 | 공통 타이포·헤더·버튼을 적용 | 진행 타이머 오버레이/원형 Pause 강제 금지 |
| `1639:4966` | 03 · 집중 중 · A | `1654:10121` | FULL | 집중 진행 중 시간 표시 | 실사 배경 + 목표 카드 + 하단 G-04/62px 타이머/원형 Pause | A/B 분기 및 상태/시간 유지 |
| `1639:4995` | 04 · 집중 일시정지 · A | `1654:10121` | STATE_ADAPT | 집중 진행·일시정지 상태 | 공간 및 Timer 레이아웃 유지, 버튼 상태 변경 | 실제 타이머 정지 및 재개 로직 유지 |
| `1639:5024` | 05 · 쉬는 시간 · A | `1654:10121` | STATE_ADAPT | 집중 플로우의 휴식 상태 | Focus 공간·하단 진행 영역 스타일 참조 | 휴식 안내/시간·컨트롤은 별도 상태로 유지 |
| `1639:5048` | 03 · 집중 중 · B | `1654:10121` | FULL | 집중 진행 중 시간 표시 | 실사 배경 + 목표 카드 + 하단 G-04/62px 타이머/원형 Pause | A/B 분기 및 상태/시간 유지 |
| `1639:5077` | 04 · 집중 일시정지 · B | `1654:10121` | STATE_ADAPT | 집중 진행·일시정지 상태 | 공간 및 Timer 레이아웃 유지, 버튼 상태 변경 | 실제 타이머 정지 및 재개 로직 유지 |
| `1639:5108` | 05 · 쉬는 시간 · B | `1654:10121` | STATE_ADAPT | 집중 플로우의 휴식 상태 | Focus 공간·하단 진행 영역 스타일 참조 | 휴식 안내/시간·컨트롤은 별도 상태로 유지 |
| `1639:5203` | 02 · 집중 설정 · 통일안 | `1654:10121` | STYLE_ONLY | 집중 기능의 설정·시작·선택 화면 | 공통 타이포·헤더·버튼을 적용 | 진행 타이머 오버레이/원형 Pause 강제 금지 |
| `1648:4027` | 03 · 집중 중 · A | `1654:10121` | FULL | 집중 진행 중 시간 표시 | 실사 배경 + 목표 카드 + 하단 G-04/62px 타이머/원형 Pause | A/B 분기 및 상태/시간 유지 |

### 17.3 MAKING — 인형 만들기 (27개)

| Target Node ID | Target Screen Name | Reference Node ID | Scope | 매칭 이유 | 적용 규칙 | 기존 기능·예외 |
| --- | --- | --- | --- | --- | --- | --- |
| `1639:3700` | 인형만들기 1 · 통일안 | `1654:10366` | STYLE_ONLY | 인형 제작 관련 기능/결과 | 제작 화면의 공통 토큰·액션 위계를 적용 | 완료/배치 불가 등 고유 콘텐츠·상태 유지 |
| `1639:3734` | 01 · 내 인형 | `1654:10366` | STYLE_ONLY | 인형 목록/프로필 기능 | 문서의 공통 텍스트·카드·버튼 언어 적용 | 5단계 제작 Step, 모양 선택 칩 자동 추가 금지 |
| `1639:3911` | 02 · 인형 프로필 | `1654:10366` | STYLE_ONLY | 인형 목록/프로필 기능 | 문서의 공통 텍스트·카드·버튼 언어 적용 | 5단계 제작 Step, 모양 선택 칩 자동 추가 금지 |
| `1639:3993` | 03 · 사진 선택 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:4057` | 04 · 배경 지우기 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:4114` | 05 · 사진 위치 조절 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:4171` | 06 · 사진 확인 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:4321` | 11 · 이름 짓기 / 입력 전 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:4367` | 12 · 이름 짓기 / 입력 후 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:4413` | 13 · 인형 완성 | `1654:10366` | STYLE_ONLY | 인형 제작 관련 기능/결과 | 제작 화면의 공통 토큰·액션 위계를 적용 | 완료/배치 불가 등 고유 콘텐츠·상태 유지 |
| `1639:4433` | 15 · 배치 불가 안내 | `1654:10366` | STYLE_ONLY | 인형 제작 관련 기능/결과 | 제작 화면의 공통 토큰·액션 위계를 적용 | 완료/배치 불가 등 고유 콘텐츠·상태 유지 |
| `1639:4455` | 09 · 인형 모양 조절 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:4511` | 10 · 얼굴 사진 조절 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:4567` | 14 · 방에 배치하기 | `1654:10366` | STYLE_ONLY | 인형 제작 관련 기능/결과 | 제작 화면의 공통 토큰·액션 위계를 적용 | 완료/배치 불가 등 고유 콘텐츠·상태 유지 |
| `1639:4596` | 17 · 인형 프로필 / 하단 기록 (스크롤 상태) | `1654:10366` | STYLE_ONLY | 인형 목록/프로필 기능 | 문서의 공통 텍스트·카드·버튼 언어 적용 | 5단계 제작 Step, 모양 선택 칩 자동 추가 금지 |
| `1639:6041` | 03 · 사진 선택 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:6105` | 04 · 배경 지우기 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:6162` | 05 · 사진 위치 조절 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:6219` | 06 · 사진 확인 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:6259` | 07 · 모양 선택 / 커스텀 기본 | `1654:10366` | STATE_ADAPT | 인형 제작 모양 선택 단계 | G-07 배경·5단계 Step·Hero·칩·이전/다음 기준 | 커스텀/기본 선택값 보존 |
| `1639:6309` | 08 · 모양 선택 / 기본 모양 | `1654:10366` | FULL | 인형 제작 모양 선택 단계 | G-07 배경·5단계 Step·Hero·칩·이전/다음 기준 | 커스텀/기본 선택값 보존 |
| `1639:6369` | 11 · 이름 짓기 / 입력 전 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:6415` | 12 · 이름 짓기 / 입력 후 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:6461` | 13 · 인형 완성 | `1654:10366` | STYLE_ONLY | 인형 제작 관련 기능/결과 | 제작 화면의 공통 토큰·액션 위계를 적용 | 완료/배치 불가 등 고유 콘텐츠·상태 유지 |
| `1639:6481` | 09 · 인형 모양 조절 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:6537` | 10 · 얼굴 사진 조절 | `1654:10366` | STATE_ADAPT | 인형 제작 단계 중 하나 | 5단계·버튼·공통 카드 시각 구조를 해당 기능에 맞춤 | 사진·입력·드래그 및 키보드 기능 유지 |
| `1639:6593` | 14 · 방에 배치하기 | `1654:10366` | STYLE_ONLY | 인형 제작 관련 기능/결과 | 제작 화면의 공통 토큰·액션 위계를 적용 | 완료/배치 불가 등 고유 콘텐츠·상태 유지 |

### 17.4 COUCH — 미디어/소파 (4개)

| Target Node ID | Target Screen Name | Reference Node ID | Scope | 매칭 이유 | 적용 규칙 | 기존 기능·예외 |
| --- | --- | --- | --- | --- | --- | --- |
| `1639:3371` | S-3 · 유튜브 플레이리스트 고르기 | `1655:4987` | STYLE_ONLY | 소파/동영상 관련 다른 상태 | 소파 미디어 스타일·카드·버튼을 해당 UI에 적용 | 홈 미니 플레이어를 풀스크린으로 확대 금지 |
| `1639:3470` | S-5 · 홈 · 시청 중 (미니 플레이어) | `1655:4987` | STYLE_ONLY | 소파/동영상 관련 다른 상태 | 소파 미디어 스타일·카드·버튼을 해당 UI에 적용 | 홈 미니 플레이어를 풀스크린으로 확대 금지 |
| `1646:5715` | S-4 · 소파에서 같이 보는 중 | `1655:4987` | FULL | 소파 함께 시청 실제 진행 | 곰·소파 + White 카드 + G-09 플레이어 + Dark CTA | 현재 재생 상태/시간/목록 유지 |
| `1652:9570` | S-1 · 소파 탭 → 기능 선택 | `1655:4987` | STYLE_ONLY | 소파/동영상 관련 다른 상태 | 소파 미디어 스타일·카드·버튼을 해당 UI에 적용 | 홈 미니 플레이어를 풀스크린으로 확대 금지 |

### 17.5 REVIEW_REQUIRED — 자동 레이아웃 교체 금지 (13개)

| Target Node ID | Target Screen Name | Reference Node ID | Scope | 매칭 이유 | 적용 규칙 | 기존 기능·예외 |
| --- | --- | --- | --- | --- | --- | --- |
| `1639:4589` | 16 · 이탈 확인 모달 | — | REVIEW_REQUIRED | 확정 불가 | 원래 화면 구조·상태 유지; 공통 토큰만 검토 | 필요하면 부모 플로우/상태 확인 후 재매칭 |
| `1639:4703` | 화면 모달 | — | REVIEW_REQUIRED | 확정 불가 | 원래 화면 구조·상태 유지; 공통 토큰만 검토 | 필요하면 부모 플로우/상태 확인 후 재매칭 |
| `1639:5269` | B-6 · ASMR · 재생 중 | — | REVIEW_REQUIRED | 확정 불가 | 원래 화면 구조·상태 유지; 공통 토큰만 검토 | 필요하면 부모 플로우/상태 확인 후 재매칭 |
| `1639:5307` | R01 · 라디오 · 소리 선택·제어 | — | REVIEW_REQUIRED | 확정 불가 | 원래 화면 구조·상태 유지; 공통 토큰만 검토 | 필요하면 부모 플로우/상태 확인 후 재매칭 |
| `1639:5347` | R01 · 라디오 · 소리 선택·제어 - 스크롤 | — | REVIEW_REQUIRED | 확정 불가 | 원래 화면 구조·상태 유지; 공통 토큰만 검토 | 필요하면 부모 플로우/상태 확인 후 재매칭 |
| `1639:5397` | R00 · 홈 · 소파 방 · 라디오 가구 | — | REVIEW_REQUIRED | 확정 불가 | 원래 화면 구조·상태 유지; 공통 토큰만 검토 | 필요하면 부모 플로우/상태 확인 후 재매칭 |
| `1639:5421` | B-6 · ASMR · 일시정지 | — | REVIEW_REQUIRED | 확정 불가 | 원래 화면 구조·상태 유지; 공통 토큰만 검토 | 필요하면 부모 플로우/상태 확인 후 재매칭 |
| `1639:5458` | R02 · 라디오 · 타이머 변경 · A | — | REVIEW_REQUIRED | 확정 불가 | 원래 화면 구조·상태 유지; 공통 토큰만 검토 | 필요하면 부모 플로우/상태 확인 후 재매칭 |
| `1639:5517` | R03 · 라디오 · 다른 소리 · A | — | REVIEW_REQUIRED | 확정 불가 | 원래 화면 구조·상태 유지; 공통 토큰만 검토 | 필요하면 부모 플로우/상태 확인 후 재매칭 |
| `1639:6615` | 16 · 이탈 확인 모달 | — | REVIEW_REQUIRED | 확정 불가 | 원래 화면 구조·상태 유지; 공통 토큰만 검토 | 필요하면 부모 플로우/상태 확인 후 재매칭 |
| `1639:3076` | 책상 인터랙션 | — | REVIEW_REQUIRED | 확정 불가 | 원래 화면 구조·상태 유지; 공통 토큰만 검토 | 필요하면 부모 플로우/상태 확인 후 재매칭 |
| `1573:7963` | S-0 · 홈 · 소파 추가됨 (힌트) | — | REVIEW_REQUIRED | 확정 불가 | 원래 화면 구조·상태 유지; 공통 토큰만 검토 | 필요하면 부모 플로우/상태 확인 후 재매칭 |
| `1652:9632` | S-2 · 같이 볼 솜뭉치 선택 | — | REVIEW_REQUIRED | 확정 불가 | 원래 화면 구조·상태 유지; 공통 토큰만 검토 | 필요하면 부모 플로우/상태 확인 후 재매칭 |

### 17.6 현재 매칭 범위와 검증의 한계

- 이 표는 Figma 디자인 시스템 작성 시 확인된 **67개 선택된 화면 프레임**을 기준으로 한 이름/ID 매칭이다. 프로젝트 파일 전체의 모든 페이지에 있는 모든 프레임의 총개수를 의미하지는 않는다.
- 분포: ROOM 10 / FOCUS 13 / MAKING 27 / COUCH 4 / REVIEW_REQUIRED 13 = 67개.
- REVIEW_REQUIRED 13개는 자동으로 Room/Focus/Making/Couch 중 한 유형에 **강제 할당하지 않는다**. 개별 화면의 기능·상위 플로우를 보고 검토한다.
- 동일 기능이 복제된 프레임들이 다수 있으므로 적용 완료 여부를 **이름이 아니라 Node ID 기준**으로 추적한다.
- 소스 프레임 ID와 대상 프레임 ID를 뒤바꾸지 않도록 한다. 대표 4화면은 원본 보존, 대상 67개만 후속 작업에서 적용 대상이 된다.

## 18. UI Migration Rules — 기존 화면의 시각적 구조까지 교체하는 실행 절차

### 18.1 입력과 출력

**입력**: 이 `DESIGN.md`, 대상 Figma의 정확한 화면 ID, 대상 화면의 기존 UI/프로토타입, 대표 4화면 원본 노드·에셋, 선택한 작업 범위. **출력**: 기존 기능과 흐름은 유지하면서 역할별/화면별 디자인에 맞춘 실제 편집 가능한 대상 Figma 화면, 변경 로그, QA 결과.

### 18.2 필수 9단계

1. **대상 화면 식별:** 이름·ID·부모·기능/상태·가로/세로 여부·현재 프로토타입 링크를 기록한다. 중복 이름은 ID로 식별한다.
2. **기존 기능 스냅샷:** 버튼 행동/화면 전환/입력 데이터/스크롤/모달/휴식·세트 로직/재생 여부 등을 목록화한다. 기존 화면을 삭제하기 전에 검증 가능한 별도 복제본을 확보한다.
3. **매칭:** 17절에서 대상 ID의 `Reference Node ID` 및 `Scope`를 얻는다. REVIEW_REQUIRED는 자동 `FULL` 금지.
4. **구조 차이 분석:** 기존 배경·헤더·중앙 콘텐츠·하단 컨트롤·탭·카드/시트·진행 바·Z-order를 대표 기준과 비교한다. 각 요소마다 `KEEP/REPLACE/REMOVE/ADD/STATE_ADAPT/UNVERIFIED`를 표시한다.
5. **레이아웃 교체:** `FULL`이면 화면 컨테이너의 기존 레이아웃이 대표 화면과 충돌할 경우 대표 구조로 교체한다. **색상/폰트만 바꾸는 변경은 미완료**로 처리한다.
6. **내용/기능 연결:** 새 레이아웃 안에 기존 문구·데이터·상태·타임라인·이동 경로·입력 값·스크롤 기능을 올바른 새 컴포넌트로 다시 연결한다. 대표 화면의 샘플 값/영상 제목을 실제 데이터인 것처럼 고정하지 않는다.
7. **스타일 값 이식:** 03–11절 컬러/그라데이션/타이포/보이는 효과/버튼 Variant를 적용한다. 이미지와 인형은 Figma 소스 인스턴스/에셋 재사용.
8. **화면 상태별 분기 검수:** 일반/선택/비활성, 진행/일시정지/휴식, 리스트/상세/모달/스크롤 상태 등 실제 고유 UI를 유지한다.
9. **전후 시각 QA 및 프로토타입 QA:** 수정 전 대상 화면·대표 화면·수정 후 화면을 나란히 비교하고, 22절 기준을 통과한 경우에만 완료로 보고한다.

### 18.3 자동 구현을 위한 체크 알고리즘

```pseudo
for target in actualFlowScreens:
    mapping = lookupByNodeId(DESIGN_MD.section17, target.id)
    if mapping.scope == REVIEW_REQUIRED:
        record('manual review', target.id)
        continue # 화면 전체 레이아웃 변경 금지
    before = snapshot(target.layout, text, assets, states, interactions, prototypeLinks)
    baseline = loadSource(mapping.ReferenceNodeId)
    assert baseline exists
    differences = compareByRoles(before, baseline)

    if mapping.scope == FULL:
        replaceConflictingUIStructure(target, baseline)  # 배경, 타이머 위치, 카드/시트, 위계 등
    elif mapping.scope == STATE_ADAPT:
        preserveDistinctStateAndPurpose(target)
        applyReusableLayoutAndComponents(target, baseline)
    else: # STYLE_ONLY
        preserveMainLayoutAndInformationArchitecture(target)
        replaceMatchingRoleComponentsOnly(target, baseline)

    applyExactMeasuredTokens(target, sourceVisibleLayersOnly=True)
    preserveOriginalInteractionsAndData(before, target)
    verifyVisualHierarchyAgainstSource(target, baseline)
    verifyPrototypeAndStateTransitions(target, before)
    record('done only if QA passes', target.id)
```

### 18.4 교체가 아닌 유지 대상

- 화면 이름/프레임 ID/역할 식별에 사용되는 정보.
- 기존 UI의 **기능**: 타이머 시간 계산·멈춤/재개, 제작 진행, 드래그, 스크롤, 라디오, 영상 제어, 뒤로가기 확인, 폼/입력/유효성, 화면 전환 링크.
- 현재 플로우에만 있는 필수 콘텐츠: 이름 입력, 사진 업로드, 사진 위치 조절, 완료/오류 안내, 설정 Bottom Sheet, 미디어 목록 등.
- 버튼 문구 및 사용자의 현재 선택 데이터. 화면 예시의 하드코딩 문자열은 테스트 데이터일 수 있다.

### 18.5 구조 교체가 필요한 대상

- **Focus FULL:** 낡은 흰 카드형 대형 타이머 + 가로 일시정지 버튼 + 파스텔 일러스트 배경을 그대로 두고 버튼 Gradient만 바꾼 것은 실패. 실제 공간 이미지 / 상단 목표 Glass / 하단 Timer Gradient / 오버레이형 62px 숫자 / 원형 Pause로 **화면 계층을 새로 구성**한다.
- **Making FULL:** 5단계 진행 상태, 큰 중앙 Hero, 아래 선택 칩, 마지막 White Previous + Black Next 위계가 없다면 구조를 재배치한다.
- **Room FULL:** 상단 방 씬과 하단 별도 Edit Sheet를 분리한다. 벽지/소품 선택 UI도 하단 시트 기반의 편집 위계로 옮긴다.
- **Couch FULL:** 곰/소파와 Player를 같은 콘텐츠 카드에 단순 합치지 않는다. Character·Sofa·White Card·Video·Media Controls·Playlist·CTA를 계층별로 분리한다.

## 19. Component Replacement Rules — 유형별 정확한 교체

| 구형 UI / 문제 | 새 기준 컴포넌트 / 레이아웃 | 적용 화면 | 유지할 기능 | 금지 |
| --- | --- | --- | --- | --- |
| 이전 Focus 타이머 카드 | Focus full-bleed scene + Timer overlay G-04 + 62px number | FOCUS / FULL | 기존 타이머 데이터/세트 진행/일시정지 | 기존 흰색 카드와 1줄 검정 버튼을 그대로 둔 채 표면만 수정 금지 |
| 기존 직사각형 일시정지 버튼 | Focus visible Glass Pause circle source 1654:10138/10139/10140 | FOCUS / FULL | pause/resume handler | 숨겨진 77×77 민트색 D1 button으로 임의 대체 금지 |
| 기존 별도 수치형 목표 카드 | Goal Progress Glass x31.8,y125 326×66 | FOCUS | 목표·달성률·프로그램 상태 | 다른 화면의 진행 bar를 복사 금지 |
| 기존 가구 선택 UI | Room furniture selected Sky Gradient card / subdued unselected cards | ROOM | 가구 선택 인덱스, 썸네일 이미지, 드래그 | 모든 가구 카드에 동일한 Selected Gradient 금지 |
| 독립된 편집 버튼 묶음 | Room Bottom Editor Sheet 390×325 + undo/redo/reset | ROOM | 가구/벽지/바닥재/소품 카테고리 | 미디어 컨트롤로 잘못 교체 금지 |
| 인형 선택 기본 흰 칩 | Making selected G-02, non-selected White; correct selection state | MAKING | 선택 인형 종류/프리셋 | 전체 버튼 CTA Dark로 변경 금지 |
| 제작 하단 행동 버튼 | Previous White 171×60 / Next G-03 Dark 171×60 | MAKING | 이전/다음 단계 경로 | Previous = Disabled라고 가정 금지 |
| 제작 단계 UI | 5 Step Strip with status symbols + track/fill | MAKING | 현재 단계 번호·완료 여부 | 모든 인형 관련 화면에 강제 추가 금지 |
| 기존 미디어 블록 | Couch White outer card + G-09 player | COUCH / FULL | 현재 재생 트랙·타임라인·재생 제어 | 전면 gradient 카드로 일괄 전환 금지 |
| 재생 컨트롤 | 44×44 side controls + middle 58.5 circle | COUCH | previous/play/pause/next | 타이머 Pause 73.56원을 그대로 사용 금지 |
| 소파 전체 주요 버튼 | G-03 Black CTA 343×46 | COUCH | 홈에서 계속 보기 기능 | Selected Sky로 변경 금지 |
| 실제 Disabled 컨트롤 | 기존 role Fill + Alpha 적용 (값 미확인) | 모든 기능 | 기존 비활성/로딩 상태 | Opacity 임의 0.4/0.5/0.6 지정 금지 |

### 19.1 KEEP / REPLACE / REMOVE / ADD 판단 기준

- **KEEP:** 기존 기능과 시각 속성이 기준과 일치함. 같은 소스 인스턴스가 이미 있는 경우.
- **REPLACE:** 시각적/구조적 위계가 다르고 기준 화면이 같은 역할을 보여줌. 예: Focus 이전 카드형 타이머 → 하단 G-04.
- **REMOVE:** 같은 역할의 낡은 요소가 새로운 기준 컴포넌트와 중복될 때. 예: Focus Timer Overlay와 동시에 남아있는 기존 큰 흰 카드.
- **ADD:** 대표 화면에 필수이나 대상에 빠진 시각 요소. 예: Focus 오늘 목표 패널, `FULL`일 때만.
- **STATE_ADAPT:** 실제 목적은 같으나 콘텐츠/상태가 다를 때. 예: 제작 진행 단계의 현재 단계 표시, 휴식 전환, 가구 카테고리.
- **UNVERIFIED:** 원본에 기능 상태/투명도/반응형 명세가 없을 때. 임의 구현 금지, 출처 확보 요청/보고.

## 20. Conflict Resolution & Figma Source Caveats

### 20.1 우선순위 사례

1. 공통 Color `#F9F9F9` vs Focus 실제 Room IMAGE + G-04 → **Focus Screen-specific Background 우선**.
2. 공통 CTA Black Gradient vs Focus Pause Circle → **Focus Timer의 Context-specific control 우선**.
3. 선택 칩 G-02 vs 일반 버튼 White → **버튼/선택지 상태 역할 우선**.
4. Making 기본 화면 vs 제작 과정 다른 단계/입력폼 → **단계 공통 컴포넌트는 공유, 콘텐츠 구조는 기능 보존**.
5. Couch fullscreen player vs Home mini player → **미니 플레이어 본래 기능/크기 우선**, 시각 스타일만 가져옴.
6. Figma 숨김 Paint vs 문서의 스타일 미리보기 → **visible=true 원본 렌더 상태 우선**.
7. 정확한 Alpha 미확인 vs Disabled 네이밍 → **User-defined Disabled opacity requirement + UNVERIFIED**. 잘못된 Source Alpha=100을 장애물 없이 확정값으로 쓰지 않음.

### 20.2 Known Discrepancies

- **ISSUE-001 [중요] — Disabled Variant의 잘못된 라벨:** 디자인 시스템 `1676:4218`의 `State=Disabled`는 원본 흰색 `이전으로`(`1654:10394`)에서 복제됨. 해당 소스 버튼의 Root opacity는 100%이고 활성 Fill도 #FFFFFF 100%다. 정당한 Disabled 상태로 검증되지 않음. 반드시 사용자 규칙(투명도 적용)을 따르되 정확한 Alpha는 미확인.
- **ISSUE-002 — 숨김 검정 디밍 레이어:** Focus `1654:10123` 검정 40% Overlay는 Source `visible=false`. 단순 레이어 조회만으로 활성이라고 판단하지 말 것.
- **ISSUE-003 — Focus 구형 민트색 Pause 인스턴스:** `1654:10135`는 `visible=false`. 보이는 Pause는 `1654:10138/10139`이다.
- **ISSUE-004 — Couch Card의 숨김 Paint:** `1655:4993`의 Sky gradient Fill, Stroke, Drop Shadow는 숨김. 현재 활성은 Solid White.
- **ISSUE-005 — Gmarket 폰트:** 원본에는 Gmarket Sans TTF Medium 타이틀이 2종 있지만 현재 폰트 로딩 환경에서 신규 Text Style 등록 불가. 원본 폰트를 문서상 유지하고 대체폰트 자동 사용 금지.
- **ISSUE-006 — 390×844 이외의 반응형 구조:** 원본 4화면의 독립적인 가로/태블릿 실측 기준이 부족하므로 `UNVERIFIED`. 구형 화면의 가로모드가 이미 구현되어 있다면 기존 기능은 유지, 새 레이아웃 값 임의 생성 금지.
- **ISSUE-007 — 디자인 시스템 스크린 매칭의 13개 검토 항목:** 라디오/ASMR/홈/확인 모달은 원본 4개 중 하나로 자동 전면 교체하면 잘못된 화면이 될 수 있다.
- **ISSUE-008 — 매칭 67개의 범위:** 이는 대상 네 플로우 섹션에서 수집한 선택된 모바일 화면 인벤토리이며 파일 전체의 모든 화면을 완전 수집했다는 의미가 아니다.

### 20.3 임의값 생성 금지

**금지:** 새로운 Shadow 토큰·임의 Font Size·무조건 4px Grid·실제로 없는 Disabled Alpha 값·모든 화면의 미색 배경·동일 높이 CTA·강제 프로그레스 바·이미지/일러스트 임의 생성·대표 인형 이미지 교체.

**가능:** 원본에서 확인된 수치/페인트/상태를 데이터에 맞춰 재사용, 원본의 정확한 Node ID/에셋 연결, 인터랙션을 보존하는 레이아웃 재배치, 화면별 역할에 맞는 패턴의 조건부 사용.

## 21. Implementation Examples — 대표 기능별 실제 대상 4건

### EX-01 ROOM — 가구 탭 적용

- **Target:** `방꾸미기 / 01 · 가구 탭` (`1639:5629`). **Reference:** `1안 · 방꾸미기` (`1646:5442`). **Scope:** `FULL`.
- **Preserve:** 탭 전환, 선택 가구, 썸네일 에셋, 드래그/undo/redo/reset, 기존 내비게이션 링크.
- **Remove or Replace:** 기존 화면에서 룸 씬·하단 편집 영역이 분리되어 있지 않다면 구조를 수정. 낡은 가구 카드의 단색 선택 표현은 선택 상태 카드 G-02로 교체.
- **Apply:** G-01 Root 배경, Room background 인스턴스 y132, Bottom Edit Sheet y544(390×325), Undo/Redo 37×37 White74%, Reset White 74×38, 선택 카드 G-02 + #B2DDEA, 미선택 #F2F2F2 Alpha70% 및 오퍼시티 69%.
- **Layout:** 상단 Header/Back, 룸 이미지와 인형/가구 중첩, y494 플로팅 Controls, 아래 편집 시트. 가구 썸네일 실제 선택값 유지.
- **Validation:** 가구 탭 표시·비선택 카드 대비·Room 씬/Bottom Sheet의 분리·가구 드래그/Undo·Back 정상 작동.

### EX-02 FOCUS — 과거 실패를 막는 핵심 적용

- **Target:** `02 · 집중 중` (`1639:4674`) 또는 `03 · 집중 중 · A` (`1639:4966`). **Reference:** `03 · 집중 중 · A` (`1654:10121`). **Scope:** `FULL`.
- **Preserve:** 18:42 같은 실제 집중 시간 값/갱신, 진행 상태, 일시정지/재개, 세트·휴식 시각, 뒤로가기 확인 모달 및 프로토타입 링크.
- **Remove or Replace:** 기존 파스텔 일러스트 공간+아래 중앙 큰 흰색 타이머 카드+가로형 `일시정지` Gradient 버튼이 있다면 **해당 시각 구조를 제거/대체**한다. 버튼 Gradient만 수정하는 작업은 실패.
- **Apply:** `1654:10122` Room image x-32.86 y-188.51 크롭·블러; 상단 `1654:10142` 목표 패널 x31.8 y125 326×66; `1654:10133` G-04 x0 y422 w390 h424; 레이블 17 Bold white x38 y621; 타이머 62 Regular white x32 y642; 보이는 Pause Group x287.75 y638; 하단 진행 Group x33 y736 w324 h37.
- **Do not apply:** 숨김 40% Dim `1654:10123` 자동 활성, 숨김 민트 Pause `1654:10135` 표시, 제작 Step UI를 Focus progress로 대체.
- **Validation:** 상단 Glass 목표/하단 Gradient 분리, 숫자 카드 미포함, 오른쪽 원형 Pause, 실사 룸 가시성, 진행 숫자/세트/휴식/뒤로가기 기능 유지.

### EX-03 MAKING — 인형 모양 선택 단계 적용

- **Target:** `08 · 모양 선택 / 기본 모양` (`1639:6309`). **Reference:** `개선 / 08 · 모양 선택 / 기본 모양` (`1654:10366`). **Scope:** `FULL`.
- **Preserve:** 현재 제작 단계 index, 인형 종류 선택, 프리셋/커스텀 모드 전환, 이전/다음 실제 단계 이동, 원본 Bear/Photo 에셋.
- **Remove or Replace:** 선택 상태 구별이 없는 단일 칩 목록, 제작 단계 표시가 없는 상단 정보, 모든 버튼이 동일 색인 구조.
- **Apply:** Root #F9F9F9 + G-07 α25%; 5-Step Strip x23.8 y128 342×35; Hero Card White Glass x26.75 y187 334.92×383.31; Preset/Custom x20.9 y587; `곰돌이` selected G-02 chip 84.11×32.91; 171px White 이전 + 12px gap + 171px G-03 다음, y734.
- **Validation:** Step 3(`모양`) current, 완료 `✓`, 미완료 `○`, 선택된 칩만 Sky Gradient, 다음 CTA Dark, 기존 상태 변경·이전/다음 프로토타입 유지.

### EX-04 COUCH — 소파 함께 보기 적용

- **Target:** `S-4 · 소파에서 같이 보는 중` (`1646:5715`). **Reference:** `S-4 · 소파에서 같이 보는 중` (`1655:4987`). **Scope:** `FULL`.
- **Preserve:** 선택 인형, 재생 중인 트랙/플레이리스트, Play/Pause/Prev/Next 상태, 동영상 시간, `홈에서 계속 보기` 이동, `그만 보기`.
- **Remove or Replace:** 미디어 플레이어 전체를 단색 카드 또는 검정 CTA 하나로 합친 구조. 흰색 외곽 카드가 Sky Gradient로 잘못 그려진 경우.
- **Apply:** 곰 x103.5 y96.7 190×248, Sofa artwork x31.5 y207.8 336×139; White Card x16.46 y338.8 358×364; G-09 Player x31 y353 329×184; 미디어 control 44×44 + center58.5d; Playlist row y640.8; Dark CTA 343×46 y717.5; exit text y778.
- **Validation:** 캐릭터/소파/카드/플레이어 Z-order 구분, 외곽 White 카드, Player 내부 3-stop Gradient, 영상 진행률/버튼 상태, CTA/보조 종료 문구 분리.

## 22. Visual & Functional QA Checklist

### 22.1 소스 확인

- [ ] 4개 원본 Node ID가 정확한가? (`1646:5442`, `1654:10121`, `1654:10366`, `1655:4987`)
- [ ] `visible=true` Fill과 숨김 Fill을 구별했는가?
- [ ] 복합 Fill이 있을 때 Gradient Opacity/Stop Alpha/Transform/Blend를 구별했는가?
- [ ] 35개 색상·Alpha 조합 중 적용 위치에 맞는 항목만 사용했는가?
- [ ] 보이는 G-01–G-09 사용 시 중간 ColorStop을 누락하지 않았는가?
- [ ] 25개 텍스트 조합의 크기·Weight·LineHeight·LetterSpacing을 의도대로 적용했는가?
- [ ] Gmarket Sans TTF를 임의 대체하지 않았는가?

### 22.2 버튼과 컴포넌트

- [ ] 버튼 역할을 Disabled/Default/CTA/Selected로 구분했는가?
- [ ] Disabled의 Alpha가 실제 근거 있는 값인지 확인했는가? (없으면 `UNVERIFIED`)
- [ ] Figma `State=Disabled` Variant의 명칭 오류를 별도로 처리했는가?
- [ ] 이전/다음 버튼 171×60 / Couch CTA 343×46 / Reset 74×38처럼 크기 차이를 보존했는가?
- [ ] Focus Pause를 원형 Glass로 유지하고 기존 가로 일시정지 CTA로 회귀하지 않았는가?
- [ ] 선택 칩과 일반 칩을 Gradient/White로 구분하고 Stroke·텍스트를 보존했는가?
- [ ] Media progress, Focus Goal, Making Step을 서로 다른 컴포넌트로 유지했는가?

### 22.3 레이아웃 및 화면별 위계

- [ ] Room은 중앙 룸 씬+하단 White Editor Sheet 구조인가?
- [ ] Focus는 실사 배경+상단 목표+하단 Gradient+62px 타이머+원형 Pause인가?
- [ ] Making은 제작 5단계+큰 Hero+선택 칩+서로 다른 이전/다음 위계인가?
- [ ] Couch는 소파 캐릭터+White 외곽 카드+내부 G-09 플레이어+미디어 컨트롤인가?
- [ ] 화면별 배경색/이미지/중첩 Fill을 획일적인 미색 또는 단일 Gradient로 바꾸지 않았는가?
- [ ] 상태바와 홈 인디케이터가 겹치거나 잘리지 않았는가?
- [ ] Scroll/Modal/Sheet 상태의 실제 기능을 보존했는가?
- [ ] 텍스트 잘림, 낮은 대비, 원본에 없는 Progress Bar, 중복 버튼, 불필요한 여백이 없는가?

### 22.4 화면 이름 및 사용자 플로우

- [ ] 대상 ID를 17절 매칭표와 확인했는가?
- [ ] 같은 이름의 중복 프레임을 ID로 구분했는가?
- [ ] FULL / STATE_ADAPT / STYLE_ONLY / REVIEW_REQUIRED에 따라 교체 범위를 다르게 적용했는가?
- [ ] 검토 필요 13개 화면을 함부로 FULL로 교체하지 않았는가?
- [ ] 데이터, 버튼 동작, 모달, 이전/다음, 스크롤 및 프로토타입 연결을 검수했는가?
- [ ] 원본 대표 화면 4개와 원래 디자인 시스템 프레임을 수정하지 않았는가?

### 22.5 최종 통과 조건

- **Visual:** 대표 화면과 대상 화면의 배경 구조·정보 위계·버튼 역할·카드 위치·타이포·진행률이 의도대로 일치해야 함.
- **Functional:** 기존 버튼과 화면 간 이동·선택·스크롤·타이머·동영상 등의 인터랙션이 남아 있어야 함.
- **Traceable:** 수정 전·수정 후 프레임 Node ID, Source Reference Node ID, 적용 Scope, QA 결과가 기록돼야 함.
- **No fake completion:** Color/Gradient만 바뀌고 기존 Focus 흰 카드형 구조가 그대로라면 완료로 보고하지 않음.

## 23. Source References & Unverified Items

### 23.1 Figma 위치

- 파일: https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb
- 디자인 시스템 프레임: https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb?node-id=1675-3945
- 원본 4화면 부모 프레임: https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb?node-id=1646-5327
- 실제 화면 매칭 섹션: Figma `1679:4013` — `10 — Actual Flow Screen-Name Matching`.
- 대표 Room: https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb?node-id=1646-5442
- 대표 Focus: https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb?node-id=1654-10121
- 대표 Making: https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb?node-id=1654-10366
- 대표 Couch: https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb?node-id=1655-4987
- 버튼 ComponentSet: https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb?node-id=1676-4218

### 23.2 정확히 확인되지 않은 속성 / 처리 방법

| 항목 | 상태 | 후속 적용 규칙 |
|---|---|---|
| Disabled 버튼의 확정 Alpha | `UNVERIFIED` | 실제 Disabled 컴포넌트/상태를 추가 확인하기 전 수치 지정 금지 |
| Root 외의 일부 Nested Instance의 최소/최대 크기 | `UNVERIFIED` | 원본 Node의 Inspector/Constraints를 직접 조회할 것 |
| Android, 가로모드 및 태블릿 Responsive Constraints | `UNVERIFIED` | 390×844 원본값을 새 화면에 기계적으로 확대하지 말 것 |
| Gmarket Sans TTF Medium 신규 로컬 Text Style | 등록 불가 확인 | 원본 타이포 사용은 유지, 다른 Font로 자동 대체 금지 |
| 네 대표 화면에 없는 Modal/Input 등의 완전한 Variant | `UNVERIFIED` | 실제 기존 플로우의 해당 컴포넌트 상태를 우선 보존 |
| 모든 67개 화면의 연결된 프로토타입 Interaction 복제 성공 | 이 문서에서 미실행 | 실제 Figma 적용 단계의 Functional QA 필수 |
| REVIEW_REQUIRED 13개 프레임의 대표 레이아웃 | `REVIEW_REQUIRED` | 목적/상위 플로우/인터랙션 확인 후 역할 분류 |
| Room/Focus/MAKING/COUCH에서 Image Fill 바이트 | 문서에 미포함 | Figma 원본/에셋 접근 필요 |

### 23.3 레이어 인벤토리 출처

Figma 디자인 시스템의 `09 — Application & Full Inventory`에는 원본 소스 레이어 총 **241개**(Room 85 / Focus 45 / Making 52 / Couch 59)의 이름·크기·타입·주요 Paint/폰트가 열거되어 있다. 여기에는 `VECTOR`, `LINE`, 이미지 인스턴스의 자식 노드도 포함된다. 이 DESIGN.md는 **기능과 UI 실행에 필요한 주요 레이어와 정확한 속성·ID**를 상세 기록했으며, 전체 241개 중 작은 장식 벡터의 Path 정보까지 Markdown으로 재구현하지는 않는다. 해당 Path는 반드시 Figma 원본 노드를 직접 재사용한다.

### 23.4 작업 완료 보고 형식 (후속 Astra 작업용)

```text
Target Figma Frame: <실제 이름/ID>
Matched Reference: <ROOM|FOCUS|MAKING|COUCH|REVIEW_REQUIRED / ID>
Migration Scope: <FULL|STATE_ADAPT|STYLE_ONLY|REVIEW_REQUIRED>
Structure changed: <배경/레이아웃/컴포넌트의 구체적 교체 목록>
Preserved behavior: <원래 기능/프로토타입 링크 목록>
Source tokens & components used: <ID 목록>
Visual QA: PASS / FAIL (+ 비교 이유)
Functional QA: PASS / FAIL (+ 검증 항목)
Unverified: <미확인 속성/누락된 에셋 목록>
```

---

**최종 원칙:** 4가지 대표 기능의 **디자인 언어·위계·레이아웃 표현**을 다른 플로우에 이식한다. 단순 색상이나 버튼 그라데이션만 바꾸지 않는다. 그러나 실제 화면의 **기능·상태·콘텐츠·인터랙션은 반드시 유지**하고, 확인되지 않은 수치를 추정해 완성한 척하지 않는다.

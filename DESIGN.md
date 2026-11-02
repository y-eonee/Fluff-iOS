---
version: alpha
name: "Fluff · 민트 테마"
description: "갤러리 속 최애 사진으로 솜인형을 만들고, 3D 방에 두고 함께 지내는 iOS 앱의 UI 디자인 시스템"
colors:
  neutral: "#FBF7EF"
  surface: "#FFFDF8"
  on-surface: "#4A352A"
  secondary: "#9B8274"
  border: "#E8DDCB"
  primary: "#8FB8AE"
  on-primary: "#FFFFFF"
  primary-soft: "#E3EEEA"
  disabled: "#CDB8A6"
  error: "#AD4141"
typography:
  logo:
    fontFamily: "NotCliche OTF"
    fontSize: 28px
    fontWeight: 400
    letterSpacing: -0.04em
  timer:
    fontFamily: "Pretendard"
    fontSize: 64px
    fontWeight: 700
    lineHeight: 80px
  section-title:
    fontFamily: "Pretendard"
    fontSize: 17px
    fontWeight: 700
    lineHeight: 26px
  button:
    fontFamily: "Pretendard"
    fontSize: 20px
    fontWeight: 700
    lineHeight: 28px
  body:
    fontFamily: "Pretendard"
    fontSize: 16px
    fontWeight: 400
    lineHeight: 24px
  caption:
    fontFamily: "Pretendard"
    fontSize: 13px
    fontWeight: 500
    lineHeight: 20px
rounded:
  sm: 10px
  md: 14px
  lg: 22px
  full: 30px
spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 24px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.full}"
    height: 60px
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.button}"
    rounded: "{rounded.full}"
    height: 60px
  chip:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.sm}"
    height: 44px
  chip-selected:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.sm}"
    height: 44px
  card-doll:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.md}"
    width: 167px
    height: 128px
  bubble:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.caption}"
    rounded: "{rounded.lg}"
    padding: "{spacing.md}"
    height: 44px
  sheet:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.lg}"
  input-name:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    height: 50px
---

# Fluff · 민트 테마 디자인 시스템

## Overview

Fluff는 22세 전후의 아이돌 팬이 갤러리 속 최애 사진으로 솜인형을 만들고, 자기 방에 두고 함께 지내는 앱이다. UI는 방과 인형이 주인공이 되도록 한 발 물러선다. 따뜻한 아이보리 바탕, 부드러운 민트 행동색, 갈색 글자를 조합해 포근하고 차분한 인상을 만든다.

- 토큰은 YAML front matter의 25개(colors 10 · typography 6 · rounded 4 · spacing 5)가 기준이다. `components`는 이 토큰들의 조합이며 별도 토큰으로 세지 않는다.
- 세부 치수, 실측값, 예외, 이전 색상 참조는 원본 명세 `DESIGN-spec.md`(Figma 토큰 명세 1201:2556의 스냅샷)를 따른다. 이 문서와 원본 명세가 다르면 이 문서의 토큰이 우선한다.
- 디자인 원본: Figma 파일 `y50EtliLp7YMR80gHuJRLb`, 섹션 "UI 통일, 색상 변경 - 민트색 테마"(1179:5995).

## Colors

| 토큰 | 값 | 쓰는 곳 |
| --- | --- | --- |
| {colors.neutral} | #FBF7EF | 일반 화면 바탕 |
| {colors.surface} | #FFFDF8 | 카드·입력·시트·모달·말풍선의 면 |
| {colors.on-surface} | #4A352A | 본문·제목·핵심 숫자·일반 아이콘 |
| {colors.secondary} | #9B8274 | 설명·보조 라벨 |
| {colors.border} | #E8DDCB | 일반 구분선 |
| {colors.primary} | #8FB8AE | 주요 행동 버튼, 선택 테두리 |
| {colors.on-primary} | #FFFFFF | 주요 행동 버튼 위 글자, 어두운 이미지 위 아이콘 |
| {colors.primary-soft} | #E3EEEA | 선택된 칩·카드의 배경 |
| {colors.disabled} | #CDB8A6 | 비활성 행동과 비활성 글자 |
| {colors.error} | #AD4141 | 삭제 행동의 글자·아이콘 |

- 방·인형·가구·소품 이미지 에셋의 색과 재질은 UI 색이 아니다. 이미지에서 색을 뽑아 UI에 쓰지 않는다.
- 알려진 대비 문제(현재값 유지, 보정은 팀 결정 필요): {colors.secondary} on {colors.neutral} 3.37:1, {colors.on-primary} on {colors.primary} 2.18:1로 WCAG AA(4.5:1)에 못 미친다. {colors.on-surface} on {colors.neutral}은 10.72:1로 충분하다.
- 눌림(pressed) 상태 색은 아직 정해지지 않았다. 임의의 색을 만들어 쓰지 않는다.

## Typography

- 화면 타이틀 로고(making fluff, focus together, my room)는 {typography.logo}를 쓴다. 홈의 my room은 같은 서체를 34px로 키운 예외다.
- 그 외 모든 UI 글자는 Pretendard를 쓴다.
- 집중 타이머 숫자는 {typography.timer}, 섹션 제목은 {typography.section-title}, 주요 버튼은 {typography.button}, 입력·본문은 {typography.body}, 말풍선·설명은 {typography.caption}을 쓴다.
- 탭 라벨(12px/18px Bold), 슬라이더 라벨(14px/22px Bold), 보조 버튼(16px/24px Bold)은 컴포넌트 전용 크기로 `DESIGN-spec.md` 04장을 따른다.
- lineHeight가 auto인 로고는 임의의 px로 바꾸지 않는다.

## Layout

- 세로 화면은 390×844px 고정 캔버스다. 가로 화면(844×390px)은 집중·휴식·쓰다듬기 3개뿐이며 세로 UI를 축소해서 만들지 않는다.
- 상단 44px은 상태 표시줄이다. 뒤로가기 헤더는 x20, 폭 350px, 높이 44px이다.
- 버튼·선택지·입력의 기본 정렬선은 좌우 22px 여백, 폭 346px이다. 인형 미리보기와 타이머 패널은 좌우 16px, 폭 358px이다.
- 하단 주요 버튼은 y752에 놓고 아래 32px을 비운다.
- 바텀시트는 top 355px, 높이 489px이며 시트 안 콘텐츠도 x22, 폭 346px에 맞춘다.
- 하단 탭바는 390×96px로 화면 맨 아래에 붙인다.
- 요소 사이 간격은 {spacing.xs}~{spacing.xl} 단계를 쓴다.

## Elevation & Depth

- 그림자는 쓰지 않는다.
- 깊이는 표면의 투명도, 배경 블러, 얇은 테두리로만 만든다.
  - 이미지 위 탭바·말풍선·홈 제목 표면: {colors.surface} 60% + 배경 블러 24px + 흰색 70% 1px 안쪽 테두리
  - 이미지 위 시트·모달·타이머 패널: {colors.surface} 85% + 배경 블러 24px
  - 화면 전체를 덮는 스크림: #4A352A 28%
- 단색 바탕 위의 면에는 블러를 쓰지 않는다.

## Shapes

| 토큰 | 값 | 쓰는 곳 |
| --- | --- | --- |
| {rounded.sm} | 10px | 칩, 탭, 속재료 카드 |
| {rounded.md} | 14px | 인형 카드, 공부 카드 |
| {rounded.lg} | 22px | 원형 아이콘 버튼, 말풍선, 시트 상단, 인형 미리보기 |
| {rounded.full} | 30px | 주요·보조 버튼 |

- 현재 남아 있는 예외: 이름 입력창 7px, 모달·타이머·홈 제목 표면 20px, 방 미리보기 24px, 핸들·홈 인디케이터 2px. 이 예외를 다른 요소로 넓히지 않는다.
- 시트는 위쪽 두 모서리만 둥글게 한다.

## Components

- **주요 버튼(button-primary):** 346×60px, {colors.primary} 바탕, {colors.on-primary} 글자, {rounded.full}. 완성하기·시작하기처럼 화면의 핵심 행동 하나에 쓴다.
- **보조 버튼(button-secondary):** {colors.surface} 바탕, {colors.primary} 1.4px 테두리, {colors.on-surface} 글자. 취소·완료처럼 두 개를 나란히 둘 때는 168×60px 두 개를 10px 간격으로 놓는다.
- **아이콘 버튼:** 44×44px, {rounded.lg}, 아이콘 24px을 가운데에 둔다.
- **칩(chip / chip-selected):** 높이 44px, {rounded.sm}. 선택되면 {colors.primary-soft} 바탕 + {colors.primary} 2px 테두리 + 체크 표시.
- **인형 카드(card-doll):** 167×128px, {rounded.md}, 2열·간격 12px. 선택 규칙은 칩과 같다.
- **말풍선(bubble):** 높이 44px, {rounded.lg}, 좌우 패딩 {spacing.md}, {typography.caption}. 인형이 말하는 안내에 쓴다.
- **바텀시트(sheet):** 390×489px, 위쪽 {rounded.lg}, 핸들 40×4px.
- **이름 입력(input-name):** 346×50px, {typography.body}, 오른쪽에 글자 수 카운터.
- **탭바:** 탭 4개(솜뭉치들 / 내 방 / 친구 / 마이), 탭 하나 80.5×64px, {rounded.sm}.

## Do's and Don'ts

- Do: 주요 행동 버튼은 {colors.primary} 바탕, {colors.on-primary} 글자, {rounded.full} 모서리, 높이 60px로 만든다.
- Do: 한 화면에 주요 행동 버튼(button-primary)은 하나만 둔다.
- Do: 선택 상태는 {colors.primary-soft} 바탕, {colors.primary} 2px 테두리, 체크 표시를 함께 써서 색만으로 구분하지 않는다.
- Do: 본문·제목 글자는 {colors.on-surface}를 쓰고, {colors.secondary}는 설명·보조 라벨에만 쓴다.
- Do: 세로 화면의 버튼·선택지·입력은 좌우 22px 여백, 폭 346px 정렬선에 맞춘다.
- Do: 누를 수 있는 요소의 터치 영역은 44×44px 이상으로 한다.
- Do: 화면 타이틀 로고에만 NotCliche OTF를 쓰고, 나머지 UI 글자는 모두 Pretendard를 쓴다.
- Don't: 그림자를 쓰지 않는다. 깊이는 투명도·배경 블러·테두리로만 표현한다.
- Don't: YAML front matter에 없는 hex 색을 새로 만들지 않는다. 이미지 에셋의 색을 UI 색으로 가져오지 않는다.
- Don't: {colors.error}를 배경 면이나 장식에 쓰지 않는다. 삭제 행동의 글자·아이콘에만 쓴다.
- Don't: 그라데이션 면을 UI에 쓰지 않고, 이모지를 아이콘이나 버튼 대신 쓰지 않는다.
- Don't: 정해지지 않은 눌림·오류 입력 상태의 색을 임의로 만들지 않는다.

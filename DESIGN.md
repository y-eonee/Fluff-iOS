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

## 2026-11-09 사용자 요청 반영

- 하단 탭은 iOS 시스템 TabView 탭바를 사용한다. 위의 커스텀 탭바 치수·표면 규칙보다 우선한다.
- 네비게이션 제목과 화면 헤더의 영문에만 Cloudsofa_namgim-Regular를 사용한다. 한글·숫자는 Pretendard를 사용하며, 본문도 Pretendard를 유지한다.
- 사용자에게 표시하는 대상 명칭은 ‘인형’으로 통일한다.

## 집중하기 A안

- Figma 1431:5312의 A안 기준: 일시정지는 현재 집중을 유지하고, 설정한 집중 시간이 끝나면 휴식으로 자동 전환한다. 휴식 종료는 새 집중 회차를 시작한다.
- 집중 시간 설정은 메인 화면 안에서 스크롤한다. 타이머는 가운데 정렬하고, 일시정지·이어하기·휴식 종료는 하단 주요 버튼으로 제공한다.
- 인형 만들기의 상단 뒤로가기는 이탈 확인, 하단 ‘이전 단계로’는 초안을 유지하는 단계 이동이다.

## 라디오 R01–R03 · 하단 탭바

- Figma 1386:4364의 선형 아이콘과 반투명 표면을 시스템 탭바에 적용한다. 사용자 확인에 따라 ‘친구’를 제외하고 인형들 / 내 방 / 마이 3개를 유지한다. 탭바 치수와 선택 반응은 iOS 시스템을 따른다.
- R01은 소리 6종, 자동 종료 프리셋(15분 / 30분 / 1시간 / 계속), 5분 단위 시간 조절을 한 화면에서 스크롤한다. 라디오 배경 원본 위에 사용자의 3D 인형을 표시한다.
- 재생 화면 숫자는 누적 재생 시간이다. 일시정지 중에는 누적 시간과 자동 종료 카운트다운을 함께 멈춘다.
- R02는 적용 시점부터 남은 시간을 다시 설정한다. R03은 적용 시 소리만 교체하고 재생 상태와 남은 시간을 유지한다. 시트를 닫으면 미적용 선택은 반영하지 않는다.
- R03의 ‘타이머 적용하기’는 실제 동작에 맞춰 ‘소리 적용하기’로 표시한다.

## 소파 S1–S5 · 책상 배경

- 소파를 누르면 유튜브 같이 보기 / 앉아서 쉬기 메뉴를 제공한다. 유튜브 시청에는 깨어 있는 인형을 최대 2명까지 선택한다. 앉아서 쉬기는 별도 화면이나 선택 시트를 열지 않고, 가까이에 있는 깨어 있는 인형이 방 안에서 의자로 걸어가 앉는다. 같은 메뉴의 일어나기로 휴식을 끝낸다.
- couch time의 목록은 연결한 YouTube 계정과 사용자가 추가한 링크로 구성한다. 최근 본 영상은 실제 시청 기록, 같이 보기 좋은 목록은 사용자가 하트를 누른 항목이다.
- 시청 화면과 홈 미니 플레이어는 같은 웹 플레이어를 유지한다. 시청 중에는 선택한 인형을 홈 소파에도 임시로 앉히고, 종료 시 저장된 원래 배치로 되돌린다. YouTube 최소 뷰포트 기준에 맞춰 홈에서도 플레이어 높이는 200px 이상으로 표시한다. 다른 활동·탭이나 앱 비활성화 때는 일시정지한다.
- 책상 미리보기는 시안의 노랑 / 아쿠아 / 로즈 / 세이지 배경 중 하나를 진입 시 무작위로 선택하고, 해당 활동 동안 유지한다.

## 10주차 인형 목록 · 프로필 · 만들기

- Figma 1397:4241 영역의 01–17 화면을 따른다. 시스템 탭바는 이 시안의 밝은 표면과 갈색 아이콘으로 갱신하며 기존 3개 탭을 유지한다. 인형 목록에서 프로필로 이동해 처음 만난 날, 누른 횟수, 가구별 활동 횟수와 상태를 세로로 스크롤한다. 기존 춤추기·AR·방 배치 기능은 기록 아래에 유지한다.
- 사용자 확인에 따라 책상 활동은 지능, 창문·소파 활동은 감수성, 침대 활동은 체력에 1회당 1점을 더한다. 상태만 100점으로 제한하고 활동 횟수는 계속 누적한다. 이전 버전에서 기록하지 않은 활동은 0회부터 시작한다.
- 만들기는 커스텀 모양이 기본 선택이다. 만들기 단계 버튼은 16px Bold, 높이 60px, 반경 26px으로 통일한다. 위의 기존 20px 버튼 규칙보다 우선한다.
- 배치 중 이동 불가 안내는 상단 배너에 표시한다. 이 배너에는 기존 오류색 배경을 사용하며 위의 오류색 사용 제한의 예외다. 침대의 발치에 앉는 기능은 앞선 사용자 요청대로 유지한다.

## 2026-11-10 홈 인형 조작 · 집중 배경

- ASMR은 홈의 독립 버튼으로 진입한다. 침대 메뉴는 재우기·깨우기를 제공한다.
- 홈 인형 탭은 상세 화면을 열지 않는다. 상세는 인형 목록 탭에서만 진입한다. 공유 기능과 상세의 위치 옮기기·방에서 빼기 메뉴는 제거한다.
- 홈에서 인형을 길게 누르면 바로 이동한다. 하단 휴지통에 놓으면 방에서만 빼고 인형과 활동 기록은 목록에 보관한다. 놓기 전 취소는 원래 위치를 유지하고, 놓은 뒤에는 되돌리기를 제공한다. 이동 불가 가구 위에는 가구 이름과 함께 이동할 수 없다는 안내를 표시한다.
- 잠든 인형은 깨운 후 이동한다. 다른 인형은 침대의 발치에 앉을 수 있으며, 잠자리와 이불 영역은 배치에서 제외한다. 잠자는 인형의 높이는 이불 윗면이 아닌 매트리스 기준으로 맞춘다.
- 집중 화면의 배경은 홈에서 진입할 때 캡처한 현재 방이다. 선택·설정·집중·휴식 동안 같은 이미지를 유지하며, 이전 무작위 책상 배경 규칙보다 우선한다. 뒤로가기는 기존 갈색 아이콘과 이미지 위 반투명 표면을 사용한다.

## 2026-11-10 추가 수정 · 홈 도구와 집중 가독성

- 홈의 `my room`은 Figma 1362:4067처럼 흰색 집 아이콘과 Cloudsofa 28pt 글자만 표시하고, 배경·테두리를 제거한다.
- 상단의 인형 만들기·방 꾸미기·ASMR 버튼을 제거한다. 시스템 탭바의 오른쪽 별도 도구 버튼으로 세 가지 플로팅 행동을 열고 닫는다. 기존 세 개의 이동 탭은 유지하며, 도구 버튼은 화면 이동 대신 메뉴를 토글한다.
- 모든 공통 주요·보조 CTA 글자는 인형 탭과 동일하게 Pretendard Bold 16pt를 사용한다. 이전 20pt 규칙보다 우선한다.
- 집중 화면은 기본 공부하기와 유효한 시간이 이미 선택되어 있으면 즉시 시작할 수 있다. 보이지 않는 시간 확인 조건으로 시작을 막지 않는다.
- 집중의 방 이미지 위에 기존 스크림 토큰(갈색 28%)을 적용하고, 인형·타이머·버튼은 딤 처리 위에 표시한다.
- 이불은 발치까지 덮는다. 깨어 있는 인형의 발치 좌석은 이불 윗면이며, 잠든 인형이 있으면 올라간 이불 높이에 맞춘다. 잠자리와 발치의 수평 구분은 유지한다.

## 2026-11-10 홈 도구 · 프로필 편집 보완

- 분리된 공구 아이콘 버튼은 홈에서만 표시한다. 펼쳐지는 세 행동 버튼은 고정 너비나 글자 옆 확장 공간 없이 콘텐츠 너비에 맞춘다.
- 인형 목록 상태는 ‘지금 방에 있어요’로 표시하고, 인형 만들기 CTA 아래 탭바까지 24pt 여백을 둔다. 상세의 춤추기·예절샷 버튼 뒤 공통 흰색 패널은 제거한다.
- 프로필 편집은 시스템 네비게이션 바 대신 뒤로가기와 Pretendard 제목을 사용한다. 하단 CTA는 완료 하나이며, 로그아웃·회원탈퇴는 작은 보조 텍스트 버튼으로 제공한다. 마이 페이지의 로그아웃은 제거한다.
- 집중의 방 배경에는 사용자 추가 요청에 따라 검정 35% 딤과 6pt 블러를 함께 적용한다. 앞선 갈색 28% 규칙보다 우선하며, 인형·타이머·버튼은 흐리거나 어둡게 처리하지 않는다.

## 2026-11-10 소파 배치 · 책상 의자 · 로그인

- 라운지 의자의 사용자 표시 이름은 ‘소파’로 통일한다. 소파는 길게 누른 인형의 배치를 받지 않으며, 기존 유튜브·휴식 활동의 임시 좌석만 유지한다.
- 책상 의자에 놓은 인형은 의자 앞쪽을 바라보고 앉는다. 기본 방에서는 책상을 향해 뒷모습이 보인다. 실제 인형의 크기에 맞춰 좌석에 맞추고 등받이·방석과 겹치지 않게 한다.
- 앱 진입은 시스템 Apple 로그인 버튼을 사용하고 인증 성공 후에만 진행한다. 카카오 버튼은 제거한다. Google 연결은 YouTube 목록 접근용으로 구분한다.
- 스플래시·앱 아이콘은 사용자 승인된 A안(인형 얼굴 중심)을 적용한다. 아이콘은 민트 바탕의 아이보리 봉제 곰 얼굴이며, 스플래시는 아이보리 바탕에 같은 얼굴과 민트 Fluff 로고만 중앙에 배치한다.
- Apple 로그인 직후의 프로필 만들기 제목도 프로필 편집과 동일한 Pretendard Bold 18pt 헤더를 사용한다. 시스템 네비게이션 제목은 숨긴다.

## 2026-11-10 소파 활동 배경

- 유튜브 같이 보기의 소파 배경은 현재 방과 어울리는 아이보리 벽, 민트 소파·바닥, 크림색 러그와 포근한 봉제 재질을 사용한다. 이전 분홍색 소파·주황색 조명 대신 부드러운 낮빛으로 맞춘다.
- 인형은 사용자의 실제 3D 모델로 겹쳐 표시하므로 배경 이미지에 인형을 그려 넣지 않는다. 두 명이 앉는 중앙 좌석과 기존 정면 구도를 유지한다.

## 2026-11-10 가이드 · 집중 시간 · 나가기 보완

- 첫 가이드의 ‘확인했어요’는 시스템 탭바를 포함한 하단 안전 영역 위에 24pt 여백을 두고 표시한다. 가구 위치를 표시하는 전체 화면 오버레이와 버튼 배치를 분리한다.
- 집중 시간은 1분을 최소값으로 유지하고, 이후 5·10·15분처럼 5분 배수로 조절한다(최대 180분). 기존에 저장된 6·11분 등도 다음 증감 조작에서 가까운 방향의 5분 배수로 이동한다. 쉬는 시간은 1–60분 범위에서 1분씩 조절한다.
- 집중 나가기 모달은 Figma 1444:6444에 맞춘다. ‘나가기’는 surface 바탕·secondary 글자·border 테두리, ‘머무르기’는 primary 바탕·흰 글자를 사용한다. 버튼 높이는 44pt, 간격은 12pt이며 CTA 글자는 기존 사용자 요청대로 Pretendard Bold 16pt를 유지한다.

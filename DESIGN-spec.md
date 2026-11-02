---
title: "민트 테마 UI 디자인 시스템"
version: "1.0-observed"
language: "ko-KR"
theme: "mint-ivory-brown"
source_file: "y50EtliLp7YMR80gHuJRLb"
source_page: "880:197"
source_ui_section: "1179:5995"
source_component_catalog: "1194:1890"
source_token_spec: "1201:2556"
source_spec_date: "2026-11-01"
export_date: "2026-11-01"
timezone: "Asia/Seoul"
format: "GitHub-flavored Markdown"
excluded: ["shadow", "elevation"]
---

# 민트 테마 UI 디자인 시스템

이 문서는 **현재 Figma 명세를 옮긴 구현·검토용 스냅샷**이다. 두 원본 프레임의 텍스트를 최신 상태로 읽어 디자인 토큰, 컴포넌트 규격, 실제 사용 사례를 통합했다. 미정인 값을 확정하거나 UI를 새로 통일하는 작업은 포함하지 않는다.

## 문서 출처와 범위

| 구분 | 원본 | 포함 범위 |
| --- | --- | --- |
| UI 화면 | [UI 통일, 색상 변경 - 민트색 테마](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5995) | 18개 앱 화면, 세로·가로 및 상태 화면 |
| 컴포넌트 카탈로그 | [민트 테마 — 용도별 컴포넌트](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A1890) | 216개 원본 인스턴스를 정리한 121개 적용 사례 + 55개 UI 패턴·에셋 |
| 토큰 명세 | [민트 테마 — 디자인 토큰 명세 · Shadow 제외 · MD Ready](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2556) | 13개 구획, 199개 명세 행 |

199개는 문서 규칙·예외·치수 조합까지 포함한 **명세 행 수**이며, 독립적인 디자인 토큰 개수와 같지 않다. 176개 역시 서로 다른 컴포넌트 마스터 수가 아니라 크기·상태·아이콘 구성이 구별되는 적용 사례 및 패턴 수다.

### 읽고 적용하는 순서

1. MIB 역할 토큰과 primitive 별칭을 먼저 확인한다.
2. 해당 화면이 D1 계열인지 WC 계열인지 확인하고 그 규격을 따른다. 계열명은 현재 파일의 구분명이며 과거 테마를 새 기준으로 채택한다는 뜻이 아니다.
3. 컴포넌트 사례에서 실제 상태·사용 화면·원본 및 master를 확인한다.
4. `proposed`, `unresolved`, `legacy`를 기존 확정값과 구분한다. MD 제작만으로 보정이 적용된 것은 아니다.

### 상태·단위 범례

| 상태 | 의미 |
| --- | --- |
| `existing` | 기존 Figma 변수 또는 정의 |
| `observed` | 실제 레이어에서 확인한 현재값 |
| `proposed` | MD용 명명, 대응표, 보정 또는 문서 운영 규칙 |
| `unresolved` | 미정이거나 확인되지 않은 상태·값 |
| `legacy` | 현재 참조가 남아 있는 이전 계열 값 |
| `calculated` | 확인한 색상값으로 계산한 결과 |

상태 열은 원문에 있는 [확인]·[실측]·[제안]·미정 문구를 읽기 쉽게 분류한 편집 정보다. 한 행 안에 실측값과 제안이 함께 있으면 **용도·규칙의 세부 표기**를 우선한다. 토큰명으로 정리된 모든 행이 이미 Figma 변수나 Text Style로 등록되어 있다는 뜻은 아니다.

- 색상: `#RRGGBB`, 불투명도: `0–1` 및 %.
- 치수: px. `width × height`, `r`=radius, `pad`=padding, `gap`=요소 간격.
- 타이포: family, size, weight, line-height, letter-spacing, text-case를 함께 읽는다.
- 그림자 및 elevation 값은 제외한다. 투명도·배경 블러는 별도 속성으로 포함한다.
- 이미지 에셋의 픽셀 색·재질, 사용자 타이머 값, 프로토타입 Boolean은 공통 UI 토큰으로 취급하지 않는다.
- 프레임에 기록된 값을 문서화했으며, 원본 앱 UI와 공용 컴포넌트는 수정하지 않았다.

## 목차

- [01. Color · 역할 토큰](#tokens-01)
- [02. Color · 원시 팔레트](#tokens-02)
- [03. Starter Kit · 이름 대응표](#tokens-03)
- [04. Typography · 전체 사용 규격](#tokens-04)
- [05. Spacing · 간격·내부 패딩](#tokens-05)
- [06. Rounded · 모서리](#tokens-06)
- [07. Border · Icon · Progress](#tokens-07)
- [08. Opacity · Blur · 상태](#tokens-08)
- [09. Component · 치수·조합 명세](#tokens-09)
- [10. Layout · 화면·안전 영역](#tokens-10)
- [11. Exceptions · 이전 색상 참조](#tokens-11)
- [12. 검증 · 미정 항목](#tokens-12)
- [13. DESIGN.md · 전환 계약](#tokens-13)
- [14. 용도별 컴포넌트·패턴 전체 목록](#components)
- [15. 우선 확인할 미정·보정 항목](#open-items)
- [16. 문서 갱신 방법](#maintenance)

<a id="tokens-01"></a>

## 01. Color · 역할 토큰

[Figma 명세 구획](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2577)

[확인] 기존 MIB 변수명을 그대로 보존합니다. 아래 별칭은 동일 컬렉션의 primitive 값을 참조합니다.

| 토큰 / 키 | 현재 값 | 단위 | 용도 · 적용 규칙 | 상태 | 출처 · 원본 ID |
| --- | --- | --- | --- | --- | --- |
| <a id="token-01-1"></a>`bg/screen` | #FBF7EF | HEX · alpha 1 | 일반 화면 바탕 | existing | primitive/ivory/100<br>변수 1170:2347<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2590) |
| <a id="token-01-2"></a>`bg/surface` | #FFFDF8 | HEX · alpha 1 | 카드·입력·시트·모달의 기본색. 투명도는 별도 조합 | existing | primitive/ivory/50<br>변수 1170:2348<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2600) |
| <a id="token-01-3"></a>`bg/sunken` | #F4EDE0 | HEX · alpha 1 | 보조 입력 면·낮은 강조 면 | existing | primitive/ivory/200<br>변수 1170:2349<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2610) |
| <a id="token-01-4"></a>`bg/mint-soft` | #E3EEEA | HEX · alpha 1 | 선택 칩·선택 카드 배경 | existing | primitive/mint/100<br>변수 1170:2350<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2620) |
| <a id="token-01-5"></a>`bg/mint-subtle` | #F2F7F5 | HEX · alpha 1 | 아주 약한 강조 배경 | existing | primitive/mint/50<br>변수 1170:2351<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2630) |
| <a id="token-01-6"></a>`bg/brown-soft` | #F0E6DD | HEX · alpha 1 | 따뜻한 보조 면 | existing | primitive/brown/100<br>변수 1170:2352<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2640) |
| <a id="token-01-7"></a>`action/primary` | #8FB8AE | HEX · alpha 1 | 완성·시작·머무르기 등 주요 행동 | existing | primitive/mint/500<br>변수 1170:2353<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2650) |
| <a id="token-01-8"></a>`action/primary-light` | #C3DAD3 | HEX · alpha 1 | 옅은 민트 조작 표면. 눌림 상태와 다름 | existing | primitive/mint/300<br>변수 1170:2354<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2660) |
| <a id="token-01-9"></a>`action/secondary` | #6E5244 | HEX · alpha 1 | 보조 행동·홈 인디케이터 | existing | primitive/brown/700<br>변수 1170:2355<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2670) |
| <a id="token-01-10"></a>`action/disabled` | #CDB8A6 | HEX · alpha 1 | 비활성 행동용 정의. 비활성 동작은 별도 처리 | existing | primitive/brown/300<br>변수 1170:2356<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2680) |
| <a id="token-01-11"></a>`line/default` | #E8DDCB | HEX · alpha 1 | 일반 구분선 | existing | primitive/ivory/300<br>변수 1170:2357<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2690) |
| <a id="token-01-12"></a>`line/selected` | #8FB8AE | HEX · alpha 1 | 선택 테두리. 일부 기본 입력에도 현재 사용 | existing | primitive/mint/500<br>변수 1170:2358<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2700) |
| <a id="token-01-13"></a>`line/strong` | #6E5244 | HEX · alpha 1 | 강한 구분선 | existing | primitive/brown/700<br>변수 1170:2359<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2710) |
| <a id="token-01-14"></a>`text/primary` | #4A352A | HEX · alpha 1 | 본문·제목·핵심 숫자 | existing | primitive/brown/900<br>변수 1170:2360<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2720) |
| <a id="token-01-15"></a>`text/secondary` | #9B8274 | HEX · alpha 1 | 설명·보조 라벨. 대비 보정 검토 필요 | existing | primitive/brown/500<br>변수 1170:2361<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2730) |
| <a id="token-01-16"></a>`text/disabled` | #CDB8A6 | HEX · alpha 1 | 비활성 글자 | existing | primitive/brown/300<br>변수 1170:2362<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2740) |
| <a id="token-01-17"></a>`text/accent` | #5F8D83 | HEX · alpha 1 | 민트 강조 라벨 | existing | primitive/mint/600<br>변수 1170:2363<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2750) |
| <a id="token-01-18"></a>`text/on-primary` | #FFFFFF | HEX · alpha 1 | 주요 행동 위 글자 | existing | primitive/white<br>변수 1170:2364<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2760) |
| <a id="token-01-19"></a>`icon/default` | #4A352A | HEX · alpha 1 | 일반 조작 아이콘 | existing | primitive/brown/900<br>변수 1170:2365<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2770) |
| <a id="token-01-20"></a>`icon/on-dark` | #FFFFFF | HEX · alpha 1 | 어두운 이미지·표면 위 아이콘 | existing | primitive/white<br>변수 1170:2366<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2780) |

<a id="tokens-02"></a>

## 02. Color · 원시 팔레트

[Figma 명세 구획](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2790)

[확인] 15개 primitive · 각 색상의 alpha는 1입니다. 스와치와 HEX를 함께 읽습니다.

| 토큰 / 키 | 현재 값 | 단위 | 용도 · 적용 규칙 | 상태 | 출처 · 원본 ID |
| --- | --- | --- | --- | --- | --- |
| <a id="token-02-1"></a>`primitive/mint/50` | #F2F7F5 | HEX · alpha 1 | 아주 연한 민트 | existing | MIB 변수 1170:2332<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2803) |
| <a id="token-02-2"></a>`primitive/mint/100` | #E3EEEA | HEX · alpha 1 | 선택 배경 | existing | MIB 변수 1170:2333<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2813) |
| <a id="token-02-3"></a>`primitive/mint/300` | #C3DAD3 | HEX · alpha 1 | 보조 강조 | existing | MIB 변수 1170:2334<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2823) |
| <a id="token-02-4"></a>`primitive/mint/500` | #8FB8AE | HEX · alpha 1 | 주요 행동·선택 선 | existing | MIB 변수 1170:2335<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2833) |
| <a id="token-02-5"></a>`primitive/mint/600` | #5F8D83 | HEX · alpha 1 | 민트 글자 | existing | MIB 변수 1170:2336<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2843) |
| <a id="token-02-6"></a>`primitive/ivory/50` | #FFFDF8 | HEX · alpha 1 | 표면 | existing | MIB 변수 1170:2337<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2853) |
| <a id="token-02-7"></a>`primitive/ivory/100` | #FBF7EF | HEX · alpha 1 | 화면 | existing | MIB 변수 1170:2338<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2863) |
| <a id="token-02-8"></a>`primitive/ivory/200` | #F4EDE0 | HEX · alpha 1 | 보조 면 | existing | MIB 변수 1170:2339<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2873) |
| <a id="token-02-9"></a>`primitive/ivory/300` | #E8DDCB | HEX · alpha 1 | 구분선 | existing | MIB 변수 1170:2340<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2883) |
| <a id="token-02-10"></a>`primitive/brown/100` | #F0E6DD | HEX · alpha 1 | 보조 면 | existing | MIB 변수 1170:2341<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2893) |
| <a id="token-02-11"></a>`primitive/brown/300` | #CDB8A6 | HEX · alpha 1 | 비활성 | existing | MIB 변수 1170:2342<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2903) |
| <a id="token-02-12"></a>`primitive/brown/500` | #9B8274 | HEX · alpha 1 | 보조 글자 | existing | MIB 변수 1170:2343<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2913) |
| <a id="token-02-13"></a>`primitive/brown/700` | #6E5244 | HEX · alpha 1 | 보조 행동 | existing | MIB 변수 1170:2344<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2923) |
| <a id="token-02-14"></a>`primitive/brown/900` | #4A352A | HEX · alpha 1 | 기본 글자 | existing | MIB 변수 1170:2345<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2933) |
| <a id="token-02-15"></a>`primitive/white` | #FFFFFF | HEX · alpha 1 | 흰 글자·아이콘 | existing | MIB 변수 1170:2346<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2943) |

<a id="tokens-03"></a>

## 03. Starter Kit · 이름 대응표

[Figma 명세 구획](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2954)

[명세용 매핑] 첨부 예시의 9개 Color 이름을 현재 토큰에 연결합니다. 변수명을 바꾸거나 새 컬렉션을 만들지 않습니다.

| 토큰 / 키 | 현재 값 | 단위 | 용도 · 적용 규칙 | 상태 | 출처 · 원본 ID |
| --- | --- | --- | --- | --- | --- |
| <a id="token-03-1"></a>`neutral` | #FBF7EF | HEX · alpha 1 | 일반 화면 | proposed · 현재값 대응/제안 | bg/screen<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2967) |
| <a id="token-03-2"></a>`surface` | #FFFDF8 | HEX · alpha 1 | 카드·시트 | proposed · 현재값 대응/제안 | bg/surface<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2977) |
| <a id="token-03-3"></a>`on-surface` | #4A352A | HEX · alpha 1 | 기본 글자 | proposed · 현재값 대응/제안 | text/primary<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2987) |
| <a id="token-03-4"></a>`secondary` | #9B8274 | HEX · alpha 1 | 보조 글자 / 현재 대비 부족 | proposed · 현재값 대응/제안 | text/secondary<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A2997) |
| <a id="token-03-5"></a>`border` | #E8DDCB | HEX · alpha 1 | 일반 선 / 선택선은 line/selected | proposed · 현재값 대응/제안 | line/default<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3007) |
| <a id="token-03-6"></a>`primary` | #8FB8AE | HEX · alpha 1 | 주요 행동 | proposed · 현재값 대응/제안 | action/primary<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3017) |
| <a id="token-03-7"></a>`primary-pressed` | 값 없음 | — | MIB에 정의·적용 확인 안 됨. primary-light로 대체하지 않음 | unresolved | 미정<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3027) |
| <a id="token-03-8"></a>`disabled` | #CDB8A6 | HEX · alpha 1 | 비활성 행동 | proposed · 현재값 대응/제안 | action/disabled<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3036) |
| <a id="token-03-9"></a>`error` | #AD4141 | HEX · alpha 1 | 삭제의 글자·아이콘에 사용. MIB에 전용 오류 변수 없음 | proposed · 현재값 대응/제안 | D1 / Color/error<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3046) |

<a id="tokens-04"></a>

## 04. Typography · 전체 사용 규격

[Figma 명세 구획](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3056)

[실측] 18개 조합. 토큰명은 MD용 제안명이며 새 Text Style을 생성한 것은 아닙니다. 본문 Pretendard, 로고 NotCliche OTF. 글자 크기·행간·굵기·자간을 한 묶음으로 관리합니다.

| 토큰 / 키 | 현재 값 | 단위 | 용도 · 적용 규칙 | 상태 | 출처 · 원본 ID |
| --- | --- | --- | --- | --- | --- |
| <a id="token-04-1"></a>`type/logo/wc` | 24px / 32px<br>400 · Regular | px / px·auto · weight · % | NotCliche OTF · 자간 0%<br>예: my room | observed · 키는 proposed | [실측] [1166:2782](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2782)<br>2개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3069) |
| <a id="token-04-2"></a>`type/tab/wc` | 12px / 18px<br>500 · Medium | px / px·auto · weight · % | Pretendard · 자간 0%<br>예: 솜뭉치들 | observed · 키는 proposed | [실측] [I1166:2791;1166:2911](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2791%3B1166%3A2911)<br>4개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3078) |
| <a id="token-04-3"></a>`type/caption/regular` | 13px / 20px<br>400 · Regular | px / px·auto · weight · % | Pretendard · 자간 0%<br>예: 9:41 | observed · 키는 proposed | [실측] [1166:2797](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2797)<br>4개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3087) |
| <a id="token-04-4"></a>`type/label/wc` | 16px / 24px<br>500 · Medium | px / px·auto · weight · % | Pretendard · 자간 0%<br>예: 인형 모양 | observed · 키는 proposed | [실측] [1166:2823](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2823)<br>2개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3096) |
| <a id="token-04-5"></a>`type/label/option-wc` | 15px / 22px<br>500 · Medium | px / px·auto · weight · % | Pretendard · 자간 0%<br>예: 머리 | observed · 키는 proposed | [실측] [I1166:2826;1166:2929;1166:2904](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2826%3B1166%3A2929%3B1166%3A2904)<br>12개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3105) |
| <a id="token-04-6"></a>`type/caption/medium` | 13px / 20px<br>500 · Medium | px / px·auto · weight · % | Pretendard · 자간 0%<br>예: 속재료를 눌러 촉감을 비교해보세요 | observed · 키는 proposed | [실측] [1179:5816](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5816)<br>74개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3114) |
| <a id="token-04-7"></a>`type/logo/d1` | 28px / auto<br>400 · Regular | px / px·auto · weight · % | NotCliche OTF · 자간 -4%<br>예: making fluff | observed · 키는 proposed | [실측] [1166:1353](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1353)<br>4개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3123) |
| <a id="token-04-8"></a>`type/button/main` | 20px / 28px<br>700 · Bold | px / px·auto · weight · % | Pretendard · 자간 0%<br>예: 완성하기 | observed · 키는 proposed | [실측] [I1166:1354;1166:1822](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1354%3B1166%3A1822)<br>9개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3132) |
| <a id="token-04-9"></a>`type/section/title` | 17px / 26px<br>700 · Bold | px / px·auto · weight · % | Pretendard · 자간 0%<br>예: 인형 모양 | observed · 키는 proposed | [실측] [1166:1360](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1360)<br>12개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3141) |
| <a id="token-04-10"></a>`type/tab/d1` | 12px / 18px<br>700 · Bold | px / px·auto · weight · % | Pretendard · 자간 0%<br>예: 머리 | observed · 키는 proposed | [실측] [I1166:1363;1166:1908](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1363%3B1166%3A1908)<br>10개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3150) |
| <a id="token-04-11"></a>`type/label/strong` | 14px / 22px<br>700 · Bold | px / px·auto · weight · % | Pretendard · 자간 0%<br>예: 높이 | observed · 키는 proposed | [실측] [I1166:1370;1062:1070](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1370%3B1062%3A1070)<br>15개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3159) |
| <a id="token-04-12"></a>`type/body/default` | 16px / 24px<br>400 · Regular | px / px·auto · weight · % | Pretendard · 자간 0%<br>예: 귀염둥이 | observed · 키는 proposed | [실측] [I1166:1426;1166:1858](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1426%3B1166%3A1858)<br>6개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3168) |
| <a id="token-04-13"></a>`type/logo/home` | 34px / auto<br>400 · Regular | px / px·auto · weight · % | NotCliche OTF · 자간 -4%<br>예: my room | observed · 키는 proposed | [실측] [1166:1435](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1435)<br>1개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3177) |
| <a id="token-04-14"></a>`type/button/compact` | 16px / 24px<br>700 · Bold | px / px·auto · weight · % | Pretendard · 자간 0%<br>예: 초기화 | observed · 키는 proposed | [실측] [I1166:1495;1166:1832](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1495%3B1166%3A1832)<br>6개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3186) |
| <a id="token-04-15"></a>`type/heading/number` | 21px / 30px<br>700 · Bold | px / px·auto · weight · % | Pretendard · 자간 0%<br>예: 원목 책상 | observed · 키는 proposed | [실측] [1166:1504](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1504)<br>19개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3195) |
| <a id="token-04-16"></a>`type/logo/focus` | 28px / auto<br>400 · Regular | px / px·auto · weight · % | NotCliche OTF · 자간 -4% · lowercase<br>예: Focus Together | observed · 키는 proposed | [실측] [1166:1529](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1529)<br>2개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3204) |
| <a id="token-04-17"></a>`type/metric/total` | 28px / 38px<br>700 · Bold | px / px·auto · weight · % | Pretendard · 자간 0%<br>예: 1시간 42분 | observed · 키는 proposed | [실측] [1179:5918](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5918)<br>2개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3213) |
| <a id="token-04-18"></a>`type/timer/value` | 64px / 80px<br>700 · Bold | px / px·auto · weight · % | Pretendard · 자간 0%<br>예: 00:18:42 | observed · 키는 proposed | [실측] [I1166:1625;1062:1109](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1625%3B1062%3A1109)<br>8개 텍스트 구간<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3222) |

<a id="tokens-05"></a>

## 05. Spacing · 간격·내부 패딩

[Figma 명세 구획](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3232)

화면 위치로 정해진 바깥 여백은 Layout 표에 별도 명시합니다. 0은 간격 없음입니다. 관측 빈도는 정의가 아닌 사용 현황입니다.

| 토큰 / 키 | 현재 값 | 단위 | 용도 · 적용 규칙 | 상태 | 출처 · 원본 ID |
| --- | --- | --- | --- | --- | --- |
| <a id="token-05-1"></a>`space/0` | 0px | px | 요소 간격 178곳 / 내부 패딩 971면 | observed | [실측] [1166:2781](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2781) UI / Room title<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3245) |
| <a id="token-05-2"></a>`space/2` | 2px | px | 요소 간격 1곳 | observed | [실측] [1166:1583](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1583) Craft information<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3254) |
| <a id="token-05-3"></a>`space/4` | 4px | px | 요소 간격 56곳 / 내부 패딩 20면 | observed | [실측] [1166:2791](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2791) Tab / 솜뭉치들<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3263) |
| <a id="token-05-4"></a>`space/6` | 6px | px | 요소 간격 16곳 / 내부 패딩 16면 | observed | [실측] [1179:5815](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5815) 서비스 가이드<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3272) |
| <a id="token-05-5"></a>`space/7` | 7px | px | 요소 간격 1곳 | observed | [실측] [1166:1554](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1554) This week<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3281) |
| <a id="token-05-6"></a>`space/8` | 8px | px | 요소 간격 20곳 / 내부 패딩 75면 | observed | [실측] [1166:2812](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2812) UI / Step progress · 3 of 4<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3290) |
| <a id="token-05-7"></a>`space/9` | 9px | px | 요소 간격 1곳 | observed | [실측] [1179:5793](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5793) Frame 1<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3299) |
| <a id="token-05-8"></a>`space/10` | 10px | px | 요소 간격 8곳 / 내부 패딩 12면 | observed | [실측] [1166:1369](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1369) UI / Shape adjustments<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3308) |
| <a id="token-05-9"></a>`space/12` | 12px | px | 요소 간격 17곳 / 내부 패딩 96면 | observed | [실측] [1166:2784](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2784) UI / Room tools<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3317) |
| <a id="token-05-10"></a>`space/14` | 14px | px | 요소 간격 1곳 / 내부 패딩 3면 | observed | [실측] [1166:1437](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1437) UI / Room tools<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3326) |
| <a id="token-05-11"></a>`space/16` | 16px | px | 요소 간격 2곳 / 내부 패딩 15면 | observed | [실측] [1166:1590](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1590) Bottom sheet / Focus settings<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3335) |
| <a id="token-05-12"></a>`space/18` | 18px | px | 내부 패딩 4면 | observed | [실측] [1166:1551](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1551) Today / Focus summary<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3344) |
| <a id="token-05-13"></a>`space/22` | 22px | px | 내부 패딩 4면 | observed | [실측] [1166:1657](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1657) Dialog / 집중 화면 나가기<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3353) |
| <a id="token-05-14"></a>`space/24` | 24px | px | 요소 간격 8곳 / 내부 패딩 20면 | observed | [실측] [I1166:1625;1062:1110](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1625%3B1062%3A1110) Stats<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3362) |
| <a id="token-05-15"></a>`space/32` | 32px | px | [예시값·미적용] 첨부 Starter Kit 값. 조사한 앱 UI의 오토레이아웃 gap/padding에서는 확인되지 않음. | proposed · 현재값 대응/제안 | 공통 적용값으로 확정하지 않음<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3371) |
| <a id="token-05-16"></a>`space/xs · sm · md · lg · xl` | 4 · 8 · 12 · 16 · 24px | px | [명명 제안] MD에서 숫자 토큰에 붙일 별칭. 6·10·22px 등 기존 예외를 삭제하지 않음. | proposed · 현재값 대응/제안 | 기존 WC·D1 Space 값과 실제 UI<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3380) |

<a id="tokens-06"></a>

## 06. Rounded · 모서리

[Figma 명세 구획](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3389)

[실측] 기존 형태를 기록합니다. 작은 요소의 큰 radius는 렌더링 시 둥근 원형·알약형으로 보입니다. 계열 간 차이는 임의 보정하지 않았습니다.

| 토큰 / 키 | 현재 값 | 단위 | 용도 · 적용 규칙 | 상태 | 출처 · 원본 ID |
| --- | --- | --- | --- | --- | --- |
| <a id="token-06-1"></a>`radius/0` | 0px | px | 각진 프레임·내부 레이아웃 | observed | [실측] [1166:2772](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2772) 홈 — White &amp; Charcoal<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3402) |
| <a id="token-06-2"></a>`radius/7` | 7px | px | D1 입력창·슬라이더 | observed | [실측] [1166:1370](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1370) D1 / Slider<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3411) |
| <a id="token-06-3"></a>`radius/8` | 8px | px | 시간 조절·보조 정보 | observed | [실측] [1166:1594](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1594) UI / Time stepper<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3420) |
| <a id="token-06-4"></a>`radius/10` | 10px | px | D1 부위·선택 칩·속재료·탭 | observed | [실측] [1166:1363](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1363) D1 / Body-part chip<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3429) |
| <a id="token-06-5"></a>`radius/12` | 12px | px | WC 칩·탭 | observed | [실측] [1166:2791](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2791) Tab / 솜뭉치들<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3438) |
| <a id="token-06-6"></a>`radius/13` | 13px | px | 공부 진행 아이콘 컨테이너 | observed | [실측] [1185:1917](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1185%3A1917) Study icon / study<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3447) |
| <a id="token-06-7"></a>`radius/14` | 14px | px | D1 인형/공부 카드 · WC 주요 버튼 | observed | [실측] [1166:2831](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2831) WC / Button<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3456) |
| <a id="token-06-8"></a>`radius/16` | 16px | px | WC 방 제목·인형 미리보기 | observed | [실측] [1166:2781](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2781) UI / Room title<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3465) |
| <a id="token-06-9"></a>`radius/18` | 18px | px | 제작 미리보기 서비스 가이드 | observed | [실측] [1179:5815](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5815) 서비스 가이드<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3474) |
| <a id="token-06-10"></a>`radius/20` | 20px | px | 모달·타이머·홈 제목 표면 | observed | [실측] [1166:1434](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1434) UI / Room title surface<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3483) |
| <a id="token-06-11"></a>`radius/22` | 22px | px | 원형 조작·말풍선·시트 상단·D1 미리보기 | observed | [실측] [1166:2783](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2783) WC / Icon button<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3492) |
| <a id="token-06-12"></a>`radius/24` | 24px | px | 방 미리보기 | observed | [실측] [1166:1576](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1576) Room preview<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3501) |
| <a id="token-06-13"></a>`radius/30` | 30px | px | D1 주요·보조 버튼 | observed | [실측] [1166:1354](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1354) D1 / Button<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3510) |
| <a id="token-06-14"></a>`radius/sheet-top` | 22 / 22 / 0 / 0px | px | 시계방향 TL · TR · BR · BL. 상단만 둥글게. | observed | [1166:1590](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1590) · [1166:1749](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1749)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3519) |
| <a id="token-06-15"></a>`radius/indicator` | 2px | px | 핸들 40×4 및 홈 인디케이터 134×4. | observed | [1166:1750](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1750) · [1166:1447](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1447)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3528) |
| <a id="token-06-16"></a>`radius/track` | D1 4px / WC 2px | px | D1 8px 트랙·WC 4px 트랙의 곡률. | observed | [I1166:1370;1062:1072](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1370%3B1062%3A1072)<br>[I1166:2828;1052:643](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2828%3B1052%3A643)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3537) |
| <a id="token-06-17"></a>`rounded-sm / md / lg` | 8 / 12 / 16px | px | [예시 별칭] 일부 값만 일치. 실제 UI 전체를 세 값으로 통일한 상태가 아님. | proposed · 현재값 대응/제안 | 첨부 예시와 실제 규격 구분<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3546) |

<a id="tokens-07"></a>

## 07. Border · Icon · Progress

[Figma 명세 구획](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3556)

선 색·굵기·투명도는 분리된 속성입니다. strokes가 빈 배열이면 strokeWeight 값이 있어도 실제 선은 없습니다.

| 토큰 / 키 | 현재 값 | 단위 | 용도 · 적용 규칙 | 상태 | 출처 · 원본 ID |
| --- | --- | --- | --- | --- | --- |
| <a id="token-07-1"></a>`border/glass` | 1px inside | px (복합) | white 70% · 이미지 위 카드/시트/말풍선. 사진 위 일부 조작은 60% 또는 100%. | observed | [1166:1657](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1657) · [1166:1702](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1702) · [1166:1626](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1626)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3569) |
| <a id="token-07-2"></a>`border/control-d1` | 1.4px inside | px (복합) | line/selected. 기본 입력·보조 버튼·비선택 칩에도 사용 중. | observed | [1166:1426](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1426) · [1166:1495](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1495) · [1166:1603](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1603)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3578) |
| <a id="token-07-3"></a>`border/selected` | 2px inside | px (복합) | line/selected + bg/mint-soft + 체크/표식 조합. | observed | [1166:1363](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1363) · [1166:1398](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1398) · [1166:1755](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1755)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3587) |
| <a id="token-07-4"></a>`border/preview-outline` | 1.2px | px (복합) | 기존 손그림 외곽선의 로컬 값. 공통 컨트롤 선으로 확장하지 않음. | observed | [1179:5818](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5818)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3596) |
| <a id="token-07-5"></a>`border/slider-thumb` | D1 2.5px / WC 2px | px (복합) | 슬라이더 손잡이 테두리의 계열 차이. | observed | [I1166:1370;1062:1075](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1370%3B1062%3A1075)<br>[I1166:2828;1052:646](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2828%3B1052%3A646)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3605) |
| <a id="token-07-6"></a>`icon/size` | 24px | px (복합) | 기본 조작 아이콘. 44px 아이콘 버튼 안에 중앙 정렬. | observed | [1166:2783](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2783) · [1166:1626](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1626)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3614) |
| <a id="token-07-7"></a>`icon/check-size` | 16px | px (복합) | 선택 표시에 사용. 버튼 터치 영역과 구분. | observed | [I1166:1498;1166:1851](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1498%3B1166%3A1851)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3623) |
| <a id="token-07-8"></a>`icon/stroke-d1` | 1.8px | px (복합) | D1 선형 아이콘. 축소 아이콘은 비례 축소. | observed | [I1179:5819;1062:1022;1062:942](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1179%3A5819%3B1062%3A1022%3B1062%3A942)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3632) |
| <a id="token-07-9"></a>`icon/stroke-wc` | 2px | px (복합) | WC 선형 아이콘. 16px 체크는 약 1.333px. | observed | [I1166:2783;1166:2895;1052:552](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2783%3B1166%3A2895%3B1052%3A552)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3641) |
| <a id="token-07-10"></a>`icon/stroke-system` | 1.5px | px (복합) | 상태 표시줄 시스템 아이콘. | observed | [1166:2800](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2800)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3650) |
| <a id="token-07-11"></a>`icon/undo-redo` | 20px / 약 1.333px 선 | px (복합) | 44px 조작 프레임 안에 배치. | observed | [1166:1484](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1484) · [1166:1487](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1487)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3659) |
| <a id="token-07-12"></a>`icon/study-container` | 48×48px / 내부 26px | px (복합) | 공부하기·책 읽기·과제하기 카드 아이콘. 진행 표시에서는 44px / 내부 22px. | observed | [1185:1937](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1185%3A1937) · [1185:1917](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1185%3A1917)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3668) |
| <a id="token-07-13"></a>`progress/step` | D1 342×8 / WC 342×4px | px (복합) | 4단계 중 3단계 강조. 단계 간격 8px. | observed | [1166:1355](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1355) · [1166:2812](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2812)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3677) |
| <a id="token-07-14"></a>`progress/slider` | D1 236×8 / WC 238×4px | px (복합) | 조작 행 높이 44px, 손잡이 터치 프레임 44×44px. | observed | [I1166:1370;1062:1071](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1370%3B1062%3A1071)<br>[I1166:2828;1052:642](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2828%3B1052%3A642)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3686) |
| <a id="token-07-15"></a>`progress/goal` | 182×8px / 74% | px (복합) | 가로 화면의 목표 바. fill 폭 134.68px = 182 × 0.74. | observed | [1166:1772](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1772) · [1166:1773](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1773)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3695) |

<a id="tokens-08"></a>

## 08. Opacity · Blur · 상태

[Figma 명세 구획](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3704)

[범위] DROP_SHADOW·INNER_SHADOW 및 elevation 수치는 명세에서 제외합니다. 불투명도와 배경 블러는 별도 UI 속성이므로 포함합니다.

| 토큰 / 키 | 현재 값 | 단위 | 용도 · 적용 규칙 | 상태 | 출처 · 원본 ID |
| --- | --- | --- | --- | --- | --- |
| <a id="token-08-1"></a>`opacity/solid` | 1 (100%) | 0–1 · % | 일반 화면 바탕·주요 버튼·선택 배경. 노드 opacity와 paint opacity를 혼동하지 않음. | observed | [1166:1354](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1354) · [1166:1363](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1363)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3717) |
| <a id="token-08-2"></a>`opacity/control-subtle` | 0.50 (50%) | 0–1 · % | 일부 비선택 칩·스테퍼·소형 아이콘 버튼 표면. | observed | [1166:1603](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1603) · [1166:1594](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1594)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3726) |
| <a id="token-08-3"></a>`opacity/glass` | 0.60 (60%) | 0–1 · % | bg/surface에 적용. 탭바·말풍선·홈 제목 표면. | observed | [1166:1441](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1441) · [1166:1702](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1702)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3735) |
| <a id="token-08-4"></a>`opacity/glass-strong` | 0.85 (85%) | 0–1 · % | bg/surface에 적용. 시트·모달·타이머 패널. | observed | [1166:1590](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1590) · [1166:1657](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1657) · [1166:1624](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1624)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3744) |
| <a id="token-08-5"></a>`opacity/glass-border` | 0.70 (70%) | 0–1 · % | 흰색 1px 테두리. 조작 버튼 일부는 60%/100% 예외. | observed | [1166:1657](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1657) · [1166:1626](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1626) · [1166:1436](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1436)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3753) |
| <a id="token-08-6"></a>`opacity/scrim` | 0.28 (28%) | 0–1 · % | brown/900 색상으로 화면 전체를 덮음. | observed | [1166:1656](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1656)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3762) |
| <a id="token-08-7"></a>`blur/glass` | 24px BACKGROUND_BLUR | px | 이미지 위 표면에서 실제 사용. 단색 면에는 기본 적용하지 않음. | observed | [1166:1657](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1657) · [1166:1702](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1702)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3771) |
| <a id="token-08-8"></a>`state/default` | 표면 + 텍스트 + 기본 선 | — | 기본 입력·보조 버튼: surface / primary text / selected line(현재). | observed | [1166:1426](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1426) · [1166:1495](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1495)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3780) |
| <a id="token-08-9"></a>`state/selected` | 민트 배경 + 2px 선 + 표식 | px (복합) | 색만으로 구분하지 않는 기존 칩·인형 카드 패턴. 공부 카드 및 탭은 별도 차이 있음. | observed | [1166:1363](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1363) · [1166:1755](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1755)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3789) |
| <a id="token-08-10"></a>`state/disabled` | action/disabled + text/disabled | — | [변수 정의] 비활성 전용 화면·터치 차단 동작은 이 명세에서 확인하지 못함. | existing · 동작 미확인 | MIB 1170:2356 · 1170:2362<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3798) |
| <a id="token-08-11"></a>`state/pressed` | 미정 | — | 현재 민트 UI의 눌림 전용 색상·동작을 확인하지 못함. 값 추정 금지. | unresolved | action/primary-light와 동일시하지 않음<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3807) |
| <a id="token-08-12"></a>`state/error` | D1 Color/error #AD4141 | — | 삭제 아이콘·라벨에서 확인. 오류 입력 상태는 별도 확인 필요. | observed | [1166:1517](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1517) · [1166:1518](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1518)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3816) |

<a id="tokens-09"></a>

## 09. Component · 치수·조합 명세

[Figma 명세 구획](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3826)

[실측] width×height 단위 px. r=모서리, pad=내부 패딩, gap=요소 간격. 실제 화면의 규격이며 하나의 단일 규격으로 통일됐다고 단정하지 않습니다.

| 토큰 / 키 | 현재 값 | 단위 | 용도 · 적용 규칙 | 상태 | 출처 · 원본 ID |
| --- | --- | --- | --- | --- | --- |
| <a id="token-09-1"></a>`button/main-d1` | 346×60 · r30 | px · 텍스트 규격 | 주요 CTA / pad12 / 20·28 Bold | observed | [1166:1354](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1354)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3839) |
| <a id="token-09-2"></a>`button/main-wc` | 342×52 · r14 | px · 텍스트 규격 | 주요 CTA / pad16 / 16·24 Medium | observed | [1166:2831](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2831)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3848) |
| <a id="token-09-3"></a>`button/compact-d1` | 높이44 · r30 | px · 텍스트 규격 | 보조 행동 / pad12 / 16·24 Bold. 폭은 콘텐츠별 82·112·146·302·346. | observed | [1166:1495](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1495) · [1166:1505](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1505) · [1166:1663](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1663)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3857) |
| <a id="token-09-4"></a>`button/split-d1` | 168×60 · gap10 | px · 텍스트 규격 | 취소·완료 2열. 전체 346px. | observed | [1166:1519](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1519) · [1166:1520](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1520)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3866) |
| <a id="token-09-5"></a>`button/icon` | 44×44 · r22 | px · 텍스트 규격 | 일반 조작. 이미지 위에서는 글래스/흰 아이콘의 적용 차이 기록. | observed | [1166:1436](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1436) · [1166:1626](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1626)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3875) |
| <a id="token-09-6"></a>`button/stepper-small` | 30×30 · r22 | px · 텍스트 규격 | 현재 +/- 조작 크기. 44×44 터치 확보는 보정 제안이며 미적용. | observed | [1166:1595](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1595) · [1166:1597](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1597)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3884) |
| <a id="token-09-7"></a>`chip/part-d1` | 52.667×56 · r10 | px · 텍스트 규격 | 6개 / gap6 / 아이콘22×24 / 글자12·18 Bold | observed | [1166:1362](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1362) · [1166:1363](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1363)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3893) |
| <a id="token-09-8"></a>`chip/part-wc` | 106×44 · r12 | px · 텍스트 규격 | 3열×2행 / 342×96 선택 묶음 / 행간8 | observed | [1166:2826](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2826)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3902) |
| <a id="token-09-9"></a>`chip/category` | 82×44 · r10 | px · 텍스트 규격 | 4개 카테고리 / gap6 / 선택표식16 | observed | [1166:1497](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1497) · [1166:1498](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1498)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3911) |
| <a id="token-09-10"></a>`chip/preset` | 108.67×44 · r10 | px · 텍스트 규격 | 3개 프리셋 / gap10 | observed | [1166:1601](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1601) · [1166:1603](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1603)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3920) |
| <a id="token-09-11"></a>`card/material` | 80.5×84 · r10 | px · 텍스트 규격 | 4개 / gap8 / pad8 / 내부gap4 | observed | [1166:1397](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1397) · [1166:1398](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1398)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3929) |
| <a id="token-09-12"></a>`card/doll` | 167×128 · r14 | px · 텍스트 규격 | 2열 / 가로12·세로12 / pad8 / 내부gap4 | observed | [1166:1752](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1752) · [1166:1755](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1755)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3938) |
| <a id="token-09-13"></a>`card/study` | 108.67×128 · r14 | px · 텍스트 규격 | 3개 / gap10 / pad8 / 내부gap4 / glass60% | observed | [1185:1929](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1185%3A1929) · [1166:1544](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1544)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3947) |
| <a id="token-09-14"></a>`input/name` | 346×50 · r7 | px · 텍스트 규격 | pad16 / 본문16·24 Regular / 우측 글자수 카운터 | observed | [1166:1426](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1426)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3956) |
| <a id="token-09-15"></a>`slider/row-d1` | 346×44 · r7 | px · 텍스트 규격 | pad12 / gap10 / 라벨14·22 Bold | observed | [1166:1370](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1370)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3965) |
| <a id="token-09-16"></a>`slider/row-wc` | 342×44 · r0 | px · 텍스트 규격 | 투명 행 / gap12 / 라벨15·22 Medium | observed | [1166:2828](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2828)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3974) |
| <a id="token-09-17"></a>`stepper/time` | 346×52 · r8 | px · 텍스트 규격 | pad4 / 중앙21·30 Bold / +/-30px | observed | [1166:1594](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1594)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3983) |
| <a id="token-09-18"></a>`sheet/focus` | 390×489 · top-r22 | px · 텍스트 규격 | 현재 pad24·gap16. 실제 콘텐츠 x22·폭346으로 일부 프레임 패딩과 다름. | observed | [1166:1590](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1590)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A3992) |
| <a id="token-09-19"></a>`sheet/doll` | 390×489 · top-r22 | px · 텍스트 규격 | 현재 일반 프레임 / 콘텐츠 x22·폭346 / 그리드346×268 | observed | [1166:1749](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1749)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4001) |
| <a id="token-09-20"></a>`dialog/exit` | 346×212 · r20 | px · 텍스트 규격 | pad22 / gap16 / 본문13·20 / 버튼2개146×44 | observed | [1166:1657](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1657) · [1166:1661](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1661)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4010) |
| <a id="token-09-21"></a>`panel/timer-portrait` | 358×254 · r20 | px · 텍스트 규격 | x16 / 내부 타이머302×186 / glass85% | observed | [1166:1624](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1624) · [1166:1625](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1625)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4019) |
| <a id="token-09-22"></a>`panel/timer-landscape` | 390×252 · r20 | px · 텍스트 규격 | x22 y112 / 가로 화면 전용 배치 / 글자 축소 없음 | observed | [1166:1767](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1767)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4028) |
| <a id="token-09-23"></a>`tab/item-d1` | 80.5×64 · r10 | px · 텍스트 규격 | pad6 / gap4 / 12·18 Bold / 전체346×64 | observed | [1166:1444](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1444) · [1166:1442](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1442)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4037) |
| <a id="token-09-24"></a>`tab/item-wc` | 85.5×58 · r12 | px · 텍스트 규격 | pad4 / gap4 / 12·18 Medium / 전체342×58 | observed | [1166:2792](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2792) · [1166:2790](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2790)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4046) |
| <a id="token-09-25"></a>`tab/surface` | D1 390×96 / WC 390×100 | px · 텍스트 규격 | glass60% / 전체 화면 하단에 부착 | observed | [1166:1441](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1441) · [1166:2788](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2788)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4055) |
| <a id="token-09-26"></a>`bubble/default` | 246×44 · r22 | px · 텍스트 규격 | 좌우pad12 / 본문13·20 Medium | observed | [1166:1496](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1496)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4064) |
| <a id="token-09-27"></a>`bubble/glass` | 280×44 · r22 | px · 텍스트 규격 | glass60% / 좌우pad12 / 본문13·20 Medium | observed | [1166:1702](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1702)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4073) |
| <a id="token-09-28"></a>`preview/doll-d1` | 358×306 · r22 | px · 텍스트 규격 | 노란 이미지 영역·하늘색 외곽의 현재 예외를 보존한 실측 | observed | [1179:5811](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5811)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4082) |
| <a id="token-09-29"></a>`preview/companion` | 358×350 · r22 | px · 텍스트 규격 | 동반 인형·누적 시간·말풍선 결합. UI와 에셋 레이어 분리. | observed | [1179:5911](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5911)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4091) |

<a id="tokens-10"></a>

## 10. Layout · 화면·안전 영역

[Figma 명세 구획](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4100)

[실측과 적용 규칙 구분] OS별 안전 영역 API 값은 Figma 좌표로 확정할 수 없습니다. 아래 좌표는 현재 시안이며 런타임 inset은 별도로 반영합니다.

| 토큰 / 키 | 현재 값 | 단위 | 용도 · 적용 규칙 | 상태 | 출처 · 원본 ID |
| --- | --- | --- | --- | --- | --- |
| <a id="token-10-1"></a>`viewport/portrait` | 390×844px | px (복합) | 모든 세로 화면 고정 캔버스. 스크롤 필요 시 기능/흐름에 맞춰 별도 구현. | observed | 18개 중 세로15개<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4113) |
| <a id="token-10-2"></a>`viewport/landscape` | 844×390px | px (복합) | 가로 집중·휴식·쓰다듬기 3개. 세로 UI의 축소본으로 구현하지 않음. | observed | [1166:1763](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1763) · [1166:1775](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1775) · [1166:1786](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1786)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4122) |
| <a id="token-10-3"></a>`layout/content-d1` | 좌우22px · 폭346px | px (복합) | D1 버튼·선택·입력 기본 정렬선. | observed | [1166:1354](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1354) · [1166:1426](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1426)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4131) |
| <a id="token-10-4"></a>`layout/content-wc` | 좌우24px · 폭342px | px (복합) | WC 제작 UI·버튼·단계 표시 정렬선. | observed | [1166:2831](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2831) · [1166:2812](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2812)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4140) |
| <a id="token-10-5"></a>`layout/preview` | 좌우16px · 폭358px | px (복합) | D1 인형 미리보기·타이머 패널 정렬선. | observed | [1179:5811](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5811) · [1166:1624](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1624)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4149) |
| <a id="token-10-6"></a>`layout/header` | x20 · 폭350 · 높이44px | px (복합) | D1 뒤로가기 헤더. 타이틀은 별도 레이어이므로 의미상 함께 관리. | observed | [1166:1349](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1349)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4158) |
| <a id="token-10-7"></a>`layout/cta-bottom` | y752px · 하단32/40px | px (복합) | D1 높이60→하단32px / WC 높이52→하단40px. OS inset과 동일하다고 해석하지 않음. | observed | [1166:1354](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1354) · [1166:2831](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2831)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4167) |
| <a id="token-10-8"></a>`layout/sheet` | top355px · 높이489px | px (복합) | 390×844 화면의 하단 부착 시트. | observed | [1166:1590](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1590) · [1166:1749](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1749)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4176) |
| <a id="token-10-9"></a>`layout/status` | 높이44px | px (복합) | 시스템 상태 표시줄. 일부 WC 내부 표시는 폭342px. | observed | [1166:1524](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1524) · [1166:2796](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2796)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4185) |
| <a id="token-10-10"></a>`layout/home-indicator` | 134×4px · r2 | px (복합) | 세로 y831: 아래9px / 가로 y377: 아래9px. 시안 위치이며 OS 안전영역 정의가 아님. | observed | [1166:1447](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1447) · [1166:1774](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1774)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4194) |
| <a id="token-10-11"></a>`layout/sheet-handle` | 40×4px · r2 | px (복합) | 인형 선택 y12 / 집중 설정 y25로 현재 차이 있음. | observed | [1166:1750](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1750) · [1166:1591](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1591)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4203) |
| <a id="token-10-12"></a>`layout/landscape-split` | 정보 x22 / 인형 x482 | — | 정보390×252 @22,112 / 인형310×334 @482,43. | observed | [1166:1767](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1767) · [1184:6009](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1184%3A6009)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4212) |
| <a id="token-10-13"></a>`layout/touch-min` | 44×44px | px (복합) | [보정 제안] 소형30px +/-는 외부 터치 영역 확보 필요. 현재 적용 완료로 간주하지 않음. | proposed · 현재값 대응/제안 | [1166:1595](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1595) · [1166:1597](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1597)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4221) |

<a id="tokens-11"></a>

## 11. Exceptions · 이전 색상 참조

[Figma 명세 구획](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4231)

[확인] 아래 변수 참조가 대상 화면에 남아 있습니다. MIB 공통 팔레트로 자동 승격하지 않습니다. 실제 보이는 하늘색·노란 미리보기·갈색 조작·연두 선택 탭은 대표적인 혼재 사례입니다.

| 토큰 / 키 | 현재 값 | 단위 | 용도 · 적용 규칙 | 상태 | 출처 · 원본 ID |
| --- | --- | --- | --- | --- | --- |
| <a id="token-11-1"></a>`legacy/wc/Color/text-primary` | #27252B | HEX · alpha 1 | 현재 참조가 있는 이전 토큰. MIB 역할로의 교체 여부는 후속 통일 작업에서 결정. | legacy | 1051:1036<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4244) |
| <a id="token-11-2"></a>`legacy/wc/Color/accent-soft` | #F3E7EF | HEX · alpha 1 | 현재 참조가 있는 이전 토큰. MIB 역할로의 교체 여부는 후속 통일 작업에서 결정. | legacy | 1051:1041<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4254) |
| <a id="token-11-3"></a>`legacy/wc/Color/surface` | #FFFFFF | HEX · alpha 1 | 현재 참조가 있는 이전 토큰. MIB 역할로의 교체 여부는 후속 통일 작업에서 결정. | legacy | 1051:1034<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4264) |
| <a id="token-11-4"></a>`legacy/d1/Color/action` | #6B4A3E | HEX · alpha 1 | 현재 참조가 있는 이전 토큰. MIB 역할로의 교체 여부는 후속 통일 작업에서 결정. | legacy | 1060:2938<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4274) |
| <a id="token-11-5"></a>`legacy/d1/Color/onAction` | #FFF6EE | HEX · alpha 1 | 현재 참조가 있는 이전 토큰. MIB 역할로의 교체 여부는 후속 통일 작업에서 결정. | legacy | 1060:2940<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4284) |
| <a id="token-11-6"></a>`legacy/d1/Color/surface` | #FFF9F2 | HEX · alpha 1 | 현재 참조가 있는 이전 토큰. MIB 역할로의 교체 여부는 후속 통일 작업에서 결정. | legacy | 1060:2932<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4294) |
| <a id="token-11-7"></a>`legacy/d1/Color/border` | #8E6A5C | HEX · alpha 1 | 현재 참조가 있는 이전 토큰. MIB 역할로의 교체 여부는 후속 통일 작업에서 결정. | legacy | 1060:2950<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4304) |
| <a id="token-11-8"></a>`legacy/d1/Color/text` | #6B4A3E | HEX · alpha 1 | 현재 참조가 있는 이전 토큰. MIB 역할로의 교체 여부는 후속 통일 작업에서 결정. | legacy | 1060:2934<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4314) |
| <a id="token-11-9"></a>`legacy/base/green/300` | #DCF4E7 | HEX · alpha 1 | 현재 참조가 있는 이전 토큰. MIB 역할로의 교체 여부는 후속 통일 작업에서 결정. | legacy | 1118:429<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4324) |
| <a id="token-11-10"></a>`legacy/d1/Color/error` | #AD4141 | HEX · alpha 1 | 현재 참조가 있는 이전 토큰. 삭제용 의미색으로 보존; MIB error 확장 후보. | legacy | 1060:2956<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4334) |
| <a id="token-11-11"></a>`legacy/d1/Color/sky` | #CFE8F2 | HEX · alpha 1 | 현재 참조가 있는 이전 토큰. MIB 역할로의 교체 여부는 후속 통일 작업에서 결정. | legacy | 1060:2942<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4344) |
| <a id="token-11-12"></a>`legacy/d1/Color/preview` | #FCEBC0 | HEX · alpha 1 | 현재 참조가 있는 이전 토큰. MIB 역할로의 교체 여부는 후속 통일 작업에서 결정. | legacy | 1060:2944<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4354) |
| <a id="token-11-13"></a>`legacy/d1/Color/secondary` | #8E6A5C | HEX · alpha 1 | 현재 참조가 있는 이전 토큰. MIB 역할로의 교체 여부는 후속 통일 작업에서 결정. | legacy | 1060:2936<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4364) |

<a id="tokens-12"></a>

## 12. 검증 · 미정 항목

[Figma 명세 구획](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4374)

색상 대비는 불투명한 단색 쌍의 WCAG 상대 휘도 공식으로 계산했습니다. 일반 작은 글자 4.5:1을 비교 기준으로 사용하며, 사진·글래스 합성 결과는 통과 판정하지 않았습니다.

| 토큰 / 키 | 현재 값 | 단위 | 용도 · 적용 규칙 | 상태 | 출처 · 원본 ID |
| --- | --- | --- | --- | --- | --- |
| <a id="token-12-1"></a>`text/primary / bg/screen` | 10.72:1 | 대비비 | #4A352A / #FBF7EF<br>4.5:1 이상 | calculated | [계산] 실제 확인한 색상값<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4387) |
| <a id="token-12-2"></a>`text/secondary / bg/screen` | 3.37:1 | 대비비 | #9B8274 / #FBF7EF<br>4.5:1 미만 — 현재값 보존, 보정 필요 | calculated | [계산] 실제 확인한 색상값<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4396) |
| <a id="token-12-3"></a>`text/on-primary / action/primary` | 2.18:1 | 대비비 | #FFFFFF / #8FB8AE<br>4.5:1 미만 — 현재값 보존, 보정 필요 | calculated | [계산] 실제 확인한 색상값<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4405) |
| <a id="token-12-4"></a>`text/accent / bg/surface` | 3.67:1 | 대비비 | #5F8D83 / #FFFDF8<br>4.5:1 미만 — 현재값 보존, 보정 필요 | calculated | [계산] 실제 확인한 색상값<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4414) |
| <a id="token-12-5"></a>`text/primary / bg/mint-soft` | 9.64:1 | 대비비 | #4A352A / #E3EEEA<br>4.5:1 이상 | calculated | [계산] 실제 확인한 색상값<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4423) |
| <a id="token-12-6"></a>`D1 error / surface` | 5.72:1 | 대비비 | #AD4141 / #FFFDF8<br>4.5:1 이상 | calculated | [계산] 실제 확인한 색상값<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4432) |
| <a id="token-12-7"></a>`exception/texture` | NOISE 잔존 | — | 제작 화면에 noise 1.2 / density0.35 / alpha0.12 확인. 기존 가이드의 “노이즈 제거”와 불일치. 공통 토큰으로 확산하지 않음. | observed · 예외 | [1166:1337](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1337)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4441) |
| <a id="token-12-8"></a>`exception/logo-font` | NotCliche OTF | — | 원본 사용 확인. 현재 편집 런타임 폰트 목록에는 없음. 이 명세는 이름·값을 기록하고 원본을 변경하지 않음. | observed · 예외 | [1166:1435](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1435) · [1166:1353](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1353)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4450) |
| <a id="token-12-9"></a>`exception/glass-icon` | 50~100% + 갈색 잔존 | px (복합) | 가이드의 “mint500 60%”와 실제 조작이 다름. MIB와 로컬 override를 구분해 유지. | observed · 예외 | [1166:1436](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1436) · [1166:1438](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1438) · [1166:1595](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1595)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4459) |
| <a id="token-12-10"></a>`exception/study-selected` | glass60% + 체크 | — | 현재 공부 선택 카드는 mint100/2px 방식과 다름. 동일 선택 규칙 적용 여부 후속 결정. | observed · 예외 | [1185:1929](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1185%3A1929)<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4468) |
| <a id="token-12-11"></a>`pending/pressed-error` | 미정 / 미확인 | — | 민트 눌림 상태·오류 입력 상태·OS 안전영역·타이머 숫자 고정폭 기능은 이번 실측으로 확정하지 않음. | unresolved | 추정값 생성 금지<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4477) |

<a id="tokens-13"></a>

## 13. DESIGN.md · 전환 계약

[Figma 명세 구획](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4487)

원본 프레임의 MD 전환 계약을 이 파일에 적용했다. 원본에 있던 “지금 MD 파일을 만든 것은 아닙니다”라는 시점 설명은 문서 생성에 맞춰 갱신했다. 값·단위·상태·출처 관련 규칙은 아래에 유지한다.

| 토큰 / 키 | 현재 값 | 단위 | 용도 · 적용 규칙 | 상태 | 출처 · 원본 ID |
| --- | --- | --- | --- | --- | --- |
| <a id="token-13-1"></a>`document/meta` | theme: mint-ivory-brown<br>version: 1.0-observed | — | source_file: y50EtliLp7YMR80gHuJRLb<br>source_section: 1179:5995<br>inspected_at: 2026-11-01 (Asia/Seoul)<br>excluded: shadow, elevation | proposed · 문서 운영 규칙 | 이 프레임의 현재 스냅샷<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4500) |
| <a id="token-13-2"></a>`document/heading` | 01 → 13 순서 | — | 프레임 내 섹션 번호를 Markdown H2로 사용. visual 위치가 아니라 번호순으로 변환. | proposed · 문서 운영 규칙 | row/토큰명 레이어 이름 유지<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4509) |
| <a id="token-13-3"></a>`token/schema` | token &#124; value &#124; unit &#124; usage &#124; status &#124; source | — | color는 #RRGGBB + alpha(0..1). 치수 px, weight 숫자, tracking %, line-height px/auto. | proposed · 문서 운영 규칙 | 각 표의 네 열을 구조화해 확장<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4518) |
| <a id="token-13-4"></a>`token/status` | existing / observed / proposed / unresolved / legacy | — | existing=기존 변수, observed=레이어 실측, proposed=MD 별칭·보정 제안, unresolved=미정, legacy=잔존 이전값. | proposed · 문서 운영 규칙 | 원문 [확인]·[실측]·[제안] 표기 매핑<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4527) |
| <a id="token-13-5"></a>`token/alias` | 별칭 → primitive | — | MIB 이름을 원형으로 보존. 예: action/primary → primitive/mint/500. HEX만 복사해서 연결을 잃지 않음. | proposed · 문서 운영 규칙 | 01 Color / 02 Palette<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4536) |
| <a id="token-13-6"></a>`token/typography` | 복합 값 | — | family·size·weight·lineHeight·letterSpacing·textCase를 함께 출력. auto를 임의 px로 변환하지 않음. | proposed · 문서 운영 규칙 | 04 Typography<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4545) |
| <a id="token-13-7"></a>`token/precision` | 원값과 표기값 분리 | — | 1.399999976은 표기1.4, 52.6669998은 표기52.667. 108.67을 임의108/109로 바꾸지 않음. | proposed · 문서 운영 규칙 | 실측 소수점 처리 규칙<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4554) |
| <a id="token-13-8"></a>`token/variants` | D1 / WC 구분 | — | 두 계열에 서로 다른 값이 있으면 각각 명시. 현재형과 권장형을 같은 확정 토큰으로 합치지 않음. | proposed · 문서 운영 규칙 | 09 Component / 10 Layout<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4563) |
| <a id="token-13-9"></a>`token/exclusions` | 이미지 픽셀·장식 벡터·shadow 제외 | — | 방/인형/소품의 색·재질은 UI 컬러로 추출하지 않음. 상태 Boolean과 사용자의 타이머 수치는 디자인 토큰과 구분. | proposed · 문서 운영 규칙 | 콘텐츠 에셋·프로토타입 별도<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4572) |
| <a id="token-13-10"></a>`token/source-link` | Figma node URL | — | https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=노드ID<br>변수는 컬렉션명 + 변수ID로 추적. | proposed · 문서 운영 규칙 | 세미콜론 포함 중첩 ID는 원문 보존<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4581) |
| <a id="token-13-11"></a>`implementation/rules` | 확정되지 않은 값 생성 금지 | — | MD 변환은 문서화 작업. 별도 승인된 UI 정돈 작업 없이 원본 색상·폰트·기능·흐름을 변경하지 않음. | proposed · 문서 운영 규칙 | 보정 제안은 적용 상태와 분리<br>[명세 행](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1201%3A4590) |

<a id="components"></a>

## 14. 용도별 컴포넌트·패턴 전체 목록

[Figma 카탈로그 전체](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A1890)

기존 인스턴스는 master 연결과 화면별 오버라이드를 보존한 적용 사례다. **UI 패턴**은 아직 일반 프레임인 복제본이며 새 컴포넌트 마스터가 아니다. ‘원본 숨김’은 원본에서 숨겨진 참조 요소로, 기본 화면에 표시할 요소라는 뜻이 아니다. 큰 에셋·딤의 ‘보기 %’는 카탈로그 표시 배율이며 실제 UI 규격을 변경하지 않는다.

카탈로그는 기존 원본의 효과 연결을 보존한다. 이 MD는 shadow/elevation 값을 추출하거나 규정하지 않는다. 같은 컴포넌트의 반복 문구와 사용 화면은 묶어 기록했다. 이미지·벡터 자체를 Markdown으로 변환하지 않고, 편집 가능한 Figma 원본 링크로 연결한다.

| 용도 | 적용 사례·패턴 수 | 관련 명세 |
| --- | --- | --- |
| [01 행동 · 버튼](#components-01) | 40 | [09. Component · 치수·조합 명세](#tokens-09) · [07. Border · Icon · Progress](#tokens-07) · [08. Opacity · Blur · 상태](#tokens-08) · [04. Typography · 전체 사용 규격](#tokens-04) |
| [02 내비게이션](#components-02) | 14 | [09. Component · 치수·조합 명세](#tokens-09) · [10. Layout · 화면·안전 영역](#tokens-10) · [04. Typography · 전체 사용 규격](#tokens-04) |
| [03 선택 · 옵션](#components-03) | 26 | [09. Component · 치수·조합 명세](#tokens-09) · [07. Border · Icon · Progress](#tokens-07) · [08. Opacity · Blur · 상태](#tokens-08) |
| [04 입력 · 값 조절](#components-04) | 4 | [09. Component · 치수·조합 명세](#tokens-09) · [05. Spacing · 간격·내부 패딩](#tokens-05) · [07. Border · Icon · Progress](#tokens-07) |
| [05 시간 · 진행 정보](#components-05) | 14 | [04. Typography · 전체 사용 규격](#tokens-04) · [07. Border · Icon · Progress](#tokens-07) · [09. Component · 치수·조합 명세](#tokens-09) · [10. Layout · 화면·안전 영역](#tokens-10) |
| [06 피드백 · 안내](#components-06) | 8 | [04. Typography · 전체 사용 규격](#tokens-04) · [08. Opacity · Blur · 상태](#tokens-08) · [09. Component · 치수·조합 명세](#tokens-09) |
| [07 오버레이 · 패널](#components-07) | 5 | [06. Rounded · 모서리](#tokens-06) · [08. Opacity · Blur · 상태](#tokens-08) · [09. Component · 치수·조합 명세](#tokens-09) · [10. Layout · 화면·안전 영역](#tokens-10) |
| [08 시스템 UI](#components-08) | 3 | [07. Border · Icon · Progress](#tokens-07) · [10. Layout · 화면·안전 영역](#tokens-10) |
| [09 아이콘](#components-09) | 34 | [07. Border · Icon · Progress](#tokens-07) · [01. Color · 역할 토큰](#tokens-01) |
| [10 콘텐츠 에셋](#components-10) | 23 | [11. Exceptions · 이전 색상 참조](#tokens-11) · [13. DESIGN.md · 전환 계약](#tokens-13) |
| [11 미리보기 · 편집 패턴](#components-11) | 5 | [09. Component · 치수·조합 명세](#tokens-09) · [10. Layout · 화면·안전 영역](#tokens-10) · [11. Exceptions · 이전 색상 참조](#tokens-11) |

<a id="components-01"></a>

### 14.1. 행동 · 버튼

완료·시작·취소·보조 행동 / 뒤로가기·편집·재생 제어. 크기와 아이콘 차이를 유지했습니다.

[Figma 분류 보드](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A1895) · 40개 사례

| 사례 | 구분 | 실제 크기 · 상태 · 문구 | 사용 화면 · 참조 |
| --- | --- | --- | --- |
| [WC / Icon button · bell](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A1899) | 기존 인스턴스 | 44 × 44 px<br>Surface=Surface | 사용: 홈 — White &amp; Charcoal<br>원본: [1166:2783](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2783)<br>참조 1개 · master [1166:2894](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2894) |
| [WC / Icon button · doll](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A1910) | 기존 인스턴스 | 44 × 44 px<br>Surface=Surface | 사용: 홈 — White &amp; Charcoal<br>원본: [1166:2785](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2785)<br>참조 1개 · master [1166:2894](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2894) |
| [WC / Icon button · bed](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A1921) | 기존 인스턴스 | 44 × 44 px<br>Surface=Surface | 사용: 홈 — White &amp; Charcoal<br>원본: [1166:2786](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2786)<br>참조 1개 · master [1166:2894](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2894) |
| [WC / Icon button · book](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A1932) | 기존 인스턴스 | 44 × 44 px<br>Surface=Surface | 사용: 홈 — White &amp; Charcoal<br>원본: [1166:2787](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2787)<br>참조 1개 · master [1166:2894](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2894) |
| [WC / Icon button · back](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A1942) | 기존 인스턴스 | 44 × 44 px<br>Surface=Ghost | 사용: 인형 제작 · 버전 6 — White &amp; Charcoal<br>원본: [1166:2809](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2809)<br>참조 1개 · master [1166:2896](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2896) |
| [WC / Icon button · back](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A1952) | 기존 인스턴스 | 44 × 44 px<br>Surface=Surface | 사용: 인형 제작 · 버전 6 — White &amp; Charcoal<br>원본: [1166:2819](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2819)<br>참조 1개 · master [1166:2894](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2894) |
| [WC / Icon button · next](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A1962) | 기존 인스턴스 | 44 × 44 px<br>Surface=Surface | 사용: 인형 제작 · 버전 6 — White &amp; Charcoal<br>원본: [1166:2820](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2820)<br>참조 1개 · master [1166:2894](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2894) |
| [WC / Button](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A1972) | 기존 인스턴스 | 342 × 52 px<br>State=Primary<br>문구: 완성하기 | 사용: 인형 제작 · 버전 6 — White &amp; Charcoal<br>원본: [1166:2831](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2831)<br>참조 1개 · master [1166:2887](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2887) |
| [D1 / Icon button · back](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A1980) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 인형만들기 1 · 통일안 · 인형만들기 2 · 통일안 · 인형만들기 3 · 통일안<br>원본: [1179:5819](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5819)<br>참조 3개 · master [1062:1021](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A1021) |
| [D1 / Icon button · next](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A1990) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 인형만들기 1 · 통일안 · 인형만들기 2 · 통일안 · 인형만들기 3 · 통일안<br>원본: [1179:5820](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5820)<br>참조 3개 · master [1062:1021](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A1021) |
| [D1 / Button](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2000) | 기존 인스턴스 | 346 × 60 px<br>Size=Main, State=Primary<br>문구: 완성하기 / 집중 시작하기 / 함께 시작하기 | 사용: 인형만들기 1 · 통일안 · 인형만들기 2 · 통일안 · 인형만들기 3 · 통일안 · 01 · 집중 메인 · 통일안 · 02 · 집중 설정 · 통일안 · 00 · 함께 집중할 인형 선택 · 통일안<br>원본: [1166:1354](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1354)<br>참조 7개 · master [1166:1821](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1821) |
| [D1 / Icon button · bell](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2008) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 1안 · 홈 · 통일안<br>원본: [1166:1436](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1436)<br>참조 1개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Icon button · doll](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2018) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 1안 · 홈 · 통일안<br>원본: [1166:1438](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1438)<br>참조 1개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Icon button · bed](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2029) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 1안 · 홈 · 통일안<br>원본: [1166:1439](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1439)<br>참조 1개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Icon button · book](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2039) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 1안 · 홈 · 통일안<br>원본: [1166:1440](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1440)<br>참조 1개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Button](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2049) | 기존 인스턴스 | 82 × 44 px<br>Size=Compact, State=Secondary<br>문구: 초기화 | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1495](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1495)<br>참조 1개 · master [1166:1831](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1831) |
| [D1 / Button](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2057) | 기존 인스턴스 | 112 × 44 px<br>Size=Compact, State=Secondary<br>문구: 선택 해제 | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1505](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1505)<br>참조 1개 · master [1166:1831](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1831) |
| [D1 / Icon button · rotate](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2065) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1508](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1508)<br>참조 1개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Icon button · flip](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2075) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1511](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1511)<br>참조 1개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Icon button · paint](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2085) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1514](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1514)<br>참조 1개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Icon button · trash](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2095) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1517](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1517)<br>참조 1개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Button](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2105) | 기존 인스턴스 | 168 × 60 px<br>Size=Main, State=Secondary<br>문구: 취소 | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1520](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1520)<br>참조 1개 · master [1166:1823](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1823) |
| [D1 / Button](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2113) | 기존 인스턴스 | 168 × 60 px<br>Size=Main, State=Primary<br>문구: 완료 | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1521](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1521)<br>참조 1개 · master [1166:1821](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1821) |
| [D1 / Button](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2121) | 기존 인스턴스 | 346 × 44 px<br>Size=Compact, State=Secondary<br>문구: 집중 시간 설정 | 사용: 01 · 집중 메인 · 통일안<br>원본: [1166:1531](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1531)<br>참조 1개 · master [1166:1831](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1831) |
| [D1 / Icon button · minus](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2129) | 기존 인스턴스 | 30 × 30 px<br>State=Default | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1595](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1595)<br>참조 1개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Icon button · plus](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2139) | 기존 인스턴스 | 30 × 30 px<br>State=Default | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1597](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1597)<br>참조 1개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Icon button · pause](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2149) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 03 · 집중 중 · 통일안 · 화면 모달 · 통일안 · 05 · 쉬는 시간 · 통일안 · 06 · 쓰다듬기 · 통일안 · L03 · 집중 중 / 가로 · 통일안<br>원본: [1166:1626](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1626)<br>참조 5개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Icon button · back](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2159) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 03 · 집중 중 · 통일안 · 화면 모달 · 통일안 · 04 · 일시정지 · 통일안 · 05 · 쉬는 시간 · 통일안<br>원본: [1166:1627](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1627)<br>참조 4개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Icon button · stop](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2169) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 03 · 집중 중 · 통일안 · 화면 모달 · 통일안 · 04 · 일시정지 · 통일안<br>원본: [1166:1633](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1633)<br>참조 3개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Button](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2179) | 기존 인스턴스 | 146 × 44 px<br>Size=Compact, State=Secondary<br>문구: 나가기 | 사용: 화면 모달 · 통일안<br>원본: [1166:1662](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1662)<br>참조 1개 · master [1166:1831](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1831) |
| [D1 / Button](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2187) | 기존 인스턴스 | 146 × 44 px<br>Size=Compact, State=Primary<br>문구: 머무르기 | 사용: 화면 모달 · 통일안<br>원본: [1166:1663](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1663)<br>참조 1개 · master [1166:1829](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1829) |
| [D1 / Icon button · play](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2195) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 04 · 일시정지 · 통일안 · L05 · 쉬는 시간 / 가로 · 통일안 · L06 · 쓰다듬기 / 가로 · 통일안<br>원본: [1166:1678](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1678)<br>참조 3개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Icon button · back](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2205) | 기존 인스턴스 | 44 × 44 px<br>State=Default | 사용: 06 · 쓰다듬기 · 통일안 · L03 · 집중 중 / 가로 · 통일안 · L05 · 쉬는 시간 / 가로 · 통일안 · L06 · 쓰다듬기 / 가로 · 통일안<br>원본: [1166:1720](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1720)<br>참조 4개 · master [1166:1838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1838) |
| [D1 / Button](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2215) | 기존 인스턴스 | 302 × 44 px<br>Size=Compact, State=Secondary<br>문구: 다시 집중하기 | 사용: 06 · 쓰다듬기 · 통일안<br>원본: [1166:1724](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1724)<br>참조 1개 · master [1166:1831](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1831) |
| [D1 / Button](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2223) | 기존 인스턴스 · 원본 숨김 | 346 × 60 px<br>Size=Main, State=Primary | 사용: 00 · 함께 집중할 인형 선택 · 통일안<br>원본: [1166:1762](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1762)<br>참조 1개 · master [1166:1821](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1821) |
| [뒤로가기 / 프레임](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2231) | UI 패턴 · 복제 | 44 × 44 px | 사용: 인형만들기 1 · 통일안<br>원본: [1166:1350](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1350) |
| [되돌리기](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2240) | UI 패턴 · 복제 | 44 × 44 px | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1484](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1484) |
| [다시하기](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2249) | UI 패턴 · 복제 | 44 × 44 px | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1487](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1487) |
| [가구 편집 도구 묶음](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2258) | UI 패턴 · 복제 | 346 × 72 px | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1506](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1506) |
| [취소 · 완료 묶음](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2289) | UI 패턴 · 복제 | 346 × 60 px | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1519](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1519) |

<a id="components-02"></a>

### 14.2. 내비게이션

화면 제목, 헤더, 하단 탭과 탭바. 선택·비선택 및 WC·D1 적용 사례를 함께 봅니다.

[Figma 분류 보드](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2300) · 14개 사례

| 사례 | 구분 | 실제 크기 · 상태 · 문구 | 사용 화면 · 참조 |
| --- | --- | --- | --- |
| [WC / Tab item · cloud](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2304) | 기존 인스턴스 | 86 × 58 px<br>State=Default<br>문구: 솜뭉치들 | 사용: 홈 — White &amp; Charcoal<br>원본: [1166:2791](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2791)<br>참조 1개 · master [1166:2909](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2909) |
| [WC / Tab item · home](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2315) | 기존 인스턴스 | 86 × 58 px<br>State=Selected<br>문구: 내방 | 사용: 홈 — White &amp; Charcoal<br>원본: [1166:2792](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2792)<br>참조 1개 · master [1166:2912](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2912) |
| [WC / Tab item · users](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2327) | 기존 인스턴스 | 86 × 58 px<br>State=Default<br>문구: 친구 | 사용: 홈 — White &amp; Charcoal<br>원본: [1166:2793](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2793)<br>참조 1개 · master [1166:2909](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2909) |
| [WC / Tab item · user](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2339) | 기존 인스턴스 | 86 × 58 px<br>State=Default<br>문구: 마이 | 사용: 홈 — White &amp; Charcoal<br>원본: [1166:2794](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2794)<br>참조 1개 · master [1166:2909](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2909) |
| [D1 / Tab · cloud](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2351) | 기존 인스턴스 | 81 × 64 px<br>State=Default<br>문구: 솜뭉치들 | 사용: 1안 · 홈 · 통일안<br>원본: [1166:1443](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1443)<br>참조 1개 · master [1166:1872](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1872) |
| [D1 / Tab · home](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2362) | 기존 인스턴스 | 81 × 64 px<br>State=Selected<br>문구: 내 방 | 사용: 1안 · 홈 · 통일안<br>원본: [1166:1444](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1444)<br>참조 1개 · master [1166:1875](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1875) |
| [D1 / Tab · users](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2374) | 기존 인스턴스 | 81 × 64 px<br>State=Default<br>문구: 친구 | 사용: 1안 · 홈 · 통일안<br>원본: [1166:1445](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1445)<br>참조 1개 · master [1166:1872](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1872) |
| [D1 / Tab · user](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2386) | 기존 인스턴스 | 81 × 64 px<br>State=Default<br>문구: 마이 | 사용: 1안 · 홈 · 통일안<br>원본: [1166:1446](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1446)<br>참조 1개 · master [1166:1872](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1872) |
| [방 제목 / D1](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2398) | UI 패턴 · 복제 | 201 × 60 px | 사용: 1안 · 홈 · 통일안<br>원본: [1166:1434](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1434) |
| [방 제목 / WC](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2410) | UI 패턴 · 복제 | 118 × 48 px | 사용: 홈 — White &amp; Charcoal<br>원본: [1166:2781](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2781) |
| [화면 헤더 / D1](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2418) | UI 패턴 · 복제 | 350 × 44 px | 사용: 인형만들기 1 · 통일안<br>원본: [1166:1349](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1349), [1166:1353](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1353) |
| [화면 헤더 / WC](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2430) | UI 패턴 · 복제 | 342 × 44 px | 사용: 인형 제작 · 버전 6 — White &amp; Charcoal<br>원본: [1166:2808](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2808) |
| [하단 탭바 / D1](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2443) | UI 패턴 · 복제 | 390 × 96 px | 사용: 1안 · 홈 · 통일안<br>원본: [1166:1441](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1441), [1166:1442](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1442) |
| [하단 탭바 / WC](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2475) | UI 패턴 · 복제 | 390 × 100 px | 사용: 홈 — White &amp; Charcoal<br>원본: [1166:2788](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2788), [1166:2790](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2790) |

<a id="components-03"></a>

### 14.3. 선택 · 옵션

인형 부위·속재료·가구 카테고리·공부 종류·시간 프리셋·동반 인형 선택.

[Figma 분류 보드](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2507) · 26개 사례

| 사례 | 구분 | 실제 크기 · 상태 · 문구 | 사용 화면 · 참조 |
| --- | --- | --- | --- |
| [WC / Body-part selection · check](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2511) | 기존 인스턴스 | 342 × 96 px<br>Selected=머리<br>문구: 머리 / 몸통 / 왼팔 / 오른팔 / 왼다리 / 오른다리 | 사용: 인형 제작 · 버전 6 — White &amp; Charcoal<br>원본: [1166:2826](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2826)<br>참조 1개 · master [1166:2926](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2926) |
| [WC / Part chip · check](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2546) | 기존 인스턴스 | 106 × 44 px<br>State=Selected<br>문구: 머리 | 사용: 인형 제작 · 버전 6 — White &amp; Charcoal<br>원본: [I1166:2826;1166:2929](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2826%3B1166%3A2929)<br>참조 1개 · master [1166:2902](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2902) |
| [WC / Part chip](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2557) | 기존 인스턴스 | 106 × 44 px<br>State=Default<br>문구: 몸통 / 왼팔 / 오른팔 / 왼다리 / 오른다리 | 사용: 인형 제작 · 버전 6 — White &amp; Charcoal<br>원본: [I1166:2826;1166:2931](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2826%3B1166%3A2931)<br>참조 5개 · master [1166:2899](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2899) |
| [D1 / Body-part chip](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2566) | 기존 인스턴스 | 53 × 56 px<br>Part=머리, State=Selected<br>문구: 머리 | 사용: 인형만들기 1 · 통일안<br>원본: [1166:1363](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1363)<br>참조 1개 · master [1166:1900](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1900) |
| [D1 / Body-part chip](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2581) | 기존 인스턴스 | 53 × 56 px<br>Part=몸통, State=Default<br>문구: 몸통 | 사용: 인형만들기 1 · 통일안<br>원본: [1166:1364](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1364)<br>참조 1개 · master [1166:1909](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1909) |
| [D1 / Body-part chip](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2596) | 기존 인스턴스 | 53 × 56 px<br>Part=왼팔, State=Default<br>문구: 왼팔 | 사용: 인형만들기 1 · 통일안<br>원본: [1166:1365](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1365)<br>참조 1개 · master [1166:1927](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1927) |
| [D1 / Body-part chip](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2611) | 기존 인스턴스 | 53 × 56 px<br>Part=오른팔, State=Default<br>문구: 오른팔 | 사용: 인형만들기 1 · 통일안<br>원본: [1166:1366](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1366)<br>참조 1개 · master [1166:1945](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1945) |
| [D1 / Body-part chip](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2626) | 기존 인스턴스 | 53 × 56 px<br>Part=왼다리, State=Default<br>문구: 왼다리 | 사용: 인형만들기 1 · 통일안<br>원본: [1166:1367](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1367)<br>참조 1개 · master [1166:1963](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1963) |
| [D1 / Body-part chip](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2641) | 기존 인스턴스 | 53 × 56 px<br>Part=오른다리, State=Default<br>문구: 오른다리 | 사용: 인형만들기 1 · 통일안<br>원본: [1166:1368](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1368)<br>참조 1개 · master [1166:1981](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1981) |
| [D1 / Material card](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2656) | 기존 인스턴스 | 81 × 84 px<br>Material=폭신 솜, State=Selected<br>문구: 폭신 솜 | 사용: 인형만들기 2 · 통일안<br>원본: [1166:1398](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1398)<br>참조 1개 · master [1166:2024](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2024) |
| [D1 / Material card](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2669) | 기존 인스턴스 | 81 × 84 px<br>Material=몽글 비즈, State=Default<br>문구: 몽글 비즈 | 사용: 인형만들기 2 · 통일안<br>원본: [1166:1399](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1399)<br>참조 1개 · master [1166:2031](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2031) |
| [D1 / Material card](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2685) | 기존 인스턴스 | 81 × 84 px<br>Material=쫀득 젤리, State=Default<br>문구: 쫀득 젤리 | 사용: 인형만들기 2 · 통일안<br>원본: [1166:1400](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1400)<br>참조 1개 · master [1166:2051](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2051) |
| [D1 / Material card](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2703) | 기존 인스턴스 | 81 × 84 px<br>Material=말랑 폼, State=Default<br>문구: 말랑 폼 | 사용: 인형만들기 2 · 통일안<br>원본: [1166:1401](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1401)<br>참조 1개 · master [1166:2075](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2075) |
| [D1 / Choice chip · check](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2719) | 기존 인스턴스 | 82 × 44 px<br>State=Selected<br>문구: 가구 | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1498](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1498)<br>참조 1개 · master [1166:1850](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1850) |
| [D1 / Choice chip](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2730) | 기존 인스턴스 | 82 × 44 px<br>State=Default<br>문구: 벽지 / 바닥재 / 소품 | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1499](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1499)<br>참조 3개 · master [1166:1847](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1847) |
| [D1 / Choice chip · check](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2739) | 기존 인스턴스 | 109 × 44 px<br>State=Selected<br>문구: 25 / 5 | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1602](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1602)<br>참조 1개 · master [1166:1850](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1850) |
| [D1 / Choice chip](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2750) | 기존 인스턴스 | 109 × 44 px<br>State=Default<br>문구: 50 / 10 / 직접 설정 | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1603](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1603)<br>참조 2개 · master [1166:1847](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1847) |
| [D1 / Doll card](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2759) | 기존 인스턴스 | 167 × 128 px<br>Doll=Cotton, State=Default<br>문구: 포근이 | 사용: 00 · 함께 집중할 인형 선택 · 통일안<br>원본: [1166:1754](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1754)<br>참조 3개 · master [1166:2000](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2000) |
| [D1 / Doll card · check](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2769) | 기존 인스턴스 | 167 × 128 px<br>Doll=Cat, State=Selected<br>문구: 귀염둥이 | 사용: 00 · 함께 집중할 인형 선택 · 통일안<br>원본: [1166:1755](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1755)<br>참조 1개 · master [1166:2012](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2012) |
| [부위 선택 묶음](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2781) | UI 패턴 · 복제 | 346 × 56 px | 사용: 인형만들기 1 · 통일안<br>원본: [1166:1362](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1362) |
| [속재료 선택 묶음](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2842) | UI 패턴 · 복제 | 346 × 84 px | 사용: 인형만들기 2 · 통일안<br>원본: [1166:1397](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1397) |
| [가구 카테고리](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2888) | UI 패턴 · 복제 | 346 × 44 px | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1497](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1497) |
| [시간 프리셋](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2909) | UI 패턴 · 복제 | 346 × 44 px | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1601](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1601) |
| [공부하기 카드](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2927) | UI 패턴 · 복제 | 109 × 128 px | 사용: 01 · 집중 메인 · 통일안<br>원본: [1185:1929](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1185%3A1929) |
| [책 읽기 카드](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2943) | UI 패턴 · 복제 | 109 × 128 px | 사용: 01 · 집중 메인 · 통일안<br>원본: [1185:1941](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1185%3A1941) |
| [과제하기 카드](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2957) | UI 패턴 · 복제 | 109 × 128 px | 사용: 01 · 집중 메인 · 통일안<br>원본: [1185:1951](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1185%3A1951) |

<a id="components-04"></a>

### 14.4. 입력 · 값 조절

인형 이름 입력, 높이·너비·위치 슬라이더, 집중 시간 증감.

[Figma 분류 보드](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2975) · 4개 사례

| 사례 | 구분 | 실제 크기 · 상태 · 문구 | 사용 화면 · 참조 |
| --- | --- | --- | --- |
| [WC / Slider row](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2979) | 기존 인스턴스 | 342 × 44 px<br>문구: 높이 / 50 / 너비 / 위치 | 사용: 인형 제작 · 버전 6 — White &amp; Charcoal<br>원본: [1166:2828](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2828)<br>참조 3개 · master [1052:640](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1052%3A640) |
| [D1 / Slider](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A2993) | 기존 인스턴스 | 346 × 44 px<br>문구: 높이 / 50 / 너비 / 위치 | 사용: 인형만들기 1 · 통일안<br>원본: [1166:1370](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1370)<br>참조 3개 · master [1062:1069](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A1069) |
| [D1 / Input](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3007) | 기존 인스턴스 | 346 × 50 px<br>State=Default<br>문구: 귀염둥이 / 4/10 | 사용: 인형만들기 3 · 통일안<br>원본: [1166:1426](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1426)<br>참조 1개 · master [1166:1857](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1857) |
| [집중 시간 스테퍼](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3016) | UI 패턴 · 복제 | 346 × 52 px | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1594](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1594) |

<a id="components-05"></a>

### 14.5. 시간 · 진행 정보

제작 단계, 누적 시간, 주간 기록, 공부 상태, 집중·일시정지·휴식 타이머.

[Figma 분류 보드](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3032) · 14개 사례

| 사례 | 구분 | 실제 크기 · 상태 · 문구 | 사용 화면 · 참조 |
| --- | --- | --- | --- |
| [D1 / Timer content](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3036) | 기존 인스턴스 | 302 × 186 px<br>문구: 현재 집중 시간 / 00:18:42 / 총 함께한 시간 / 02:00:42 / 휴식까지 / 06:18 / 집중 일시정지 / 쉬는 시간 / 05:00 / 02:07:00 / 오늘 총 시간 / 05:00:32 / 시작까지 | 사용: 03 · 집중 중 · 통일안 · 화면 모달 · 통일안 · 04 · 일시정지 · 통일안 · 05 · 쉬는 시간 · 통일안 · 06 · 쓰다듬기 · 통일안 · L03 · 집중 중 / 가로 · 통일안 · L05 · 쉬는 시간 / 가로 · 통일안 · L06 · 쓰다듬기 / 가로 · 통일안<br>원본: [1166:1625](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1625)<br>참조 8개 · master [1062:1107](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A1107) |
| [제작 단계 / D1](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3052) | UI 패턴 · 복제 | 342 × 8 px | 사용: 인형만들기 1 · 통일안<br>원본: [1166:1355](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1355) |
| [제작 단계 / WC](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3063) | UI 패턴 · 복제 | 342 × 4 px | 사용: 인형 제작 · 버전 6 — White &amp; Charcoal<br>원본: [1166:2812](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2812) |
| [누적 시간](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3074) | UI 패턴 · 복제 | 314 × 62 px | 사용: 01 · 집중 메인 · 통일안<br>원본: [1179:5916](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5916) |
| [일간 집중 요약 · 주간 기록](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3083) | UI 패턴 · 복제 | 342 × 167 px | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1551](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1551) |
| [선택한 공부 요약](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3114) | UI 패턴 · 복제 | 342 × 66 px | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1581](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1581) |
| [공부 진행 상태](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3129) | UI 패턴 · 복제 | 346 × 60 px | 사용: 03 · 집중 중 · 통일안<br>원본: [1166:1628](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1628) |
| [휴식 시간 요약](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3148) | UI 패턴 · 복제 | 346 × 44 px | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1599](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1599) |
| [타이머 패널 / 집중](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3156) | UI 패턴 · 복제 | 358 × 254 px | 사용: 03 · 집중 중 · 통일안<br>원본: [1166:1624](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1624) |
| [타이머 패널 / 일시정지](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3173) | UI 패턴 · 복제 | 358 × 254 px | 사용: 04 · 일시정지 · 통일안<br>원본: [1166:1676](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1676) |
| [타이머 패널 / 휴식](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3190) | UI 패턴 · 복제 | 358 × 254 px | 사용: 05 · 쉬는 시간 · 통일안<br>원본: [1166:1698](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1698) |
| [가로 타이머 / 집중](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3205) | UI 패턴 · 복제 | 390 × 252 px | 사용: L03 · 집중 중 / 가로 · 통일안<br>원본: [1166:1767](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1767) |
| [가로 타이머 / 휴식](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3222) | UI 패턴 · 복제 | 390 × 252 px | 사용: L05 · 쉬는 시간 / 가로 · 통일안<br>원본: [1166:1780](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1780) |
| [목표 진행 바 / 74%](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3239) | UI 패턴 · 복제 | 182 × 8 px | 사용: L03 · 집중 중 / 가로 · 통일안<br>원본: [1166:1772](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1772), [1166:1773](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1773) |

<a id="components-06"></a>

### 14.6. 피드백 · 안내

캐릭터 말풍선, 미리보기 도움말, 집중·휴식 상태 라벨.

[Figma 분류 보드](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3248) · 8개 사례

| 사례 | 구분 | 실제 크기 · 상태 · 문구 | 사용 화면 · 참조 |
| --- | --- | --- | --- |
| [D1 / Bubble](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3252) | 기존 인스턴스 | 246 × 44 px<br>문구: 한 손가락으로 끌어서 옮겨봐! | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1496](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1496)<br>참조 1개 · master [1062:1067](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A1067) |
| [D1 / Bubble](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3260) | 기존 인스턴스 | 242 × 34 px<br>문구: 우리 열심히 해보자! | 사용: 01 · 집중 메인 · 통일안<br>원본: [1179:5919](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5919)<br>참조 1개 · master [1062:1067](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A1067) |
| [Feedback / Speech bubble](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3268) | 기존 인스턴스 | 228 × 45 px<br>문구: 오늘도 너랑 함께할래. | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1579](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1579)<br>참조 1개 · master [979:1751](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=979%3A1751) |
| [D1 / Bubble](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3276) | 기존 인스턴스 | 280 × 44 px<br>문구: 우리 조금만 쉬자! 놀아줘! / 헤헤, 네 손은 정말 따뜻해 ♡ / 놀아줘! 쓰다듬어 줄래? | 사용: 05 · 쉬는 시간 · 통일안 · 06 · 쓰다듬기 · 통일안 · L05 · 쉬는 시간 / 가로 · 통일안 · L06 · 쓰다듬기 / 가로 · 통일안<br>원본: [1166:1702](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1702)<br>참조 4개 · master [1062:1067](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A1067) |
| [미리보기 도움말](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3284) | UI 패턴 · 복제 | 280 × 34 px | 사용: 인형만들기 1 · 통일안<br>원본: [1179:5815](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5815) |
| [휴식 상태 라벨](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3292) | UI 패턴 · 복제 | 160 × 32 px | 사용: 05 · 쉬는 시간 · 통일안<br>원본: [1166:1703](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1703) |
| [가로 집중 상태 라벨](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3300) | UI 패턴 · 복제 | 182 × 36 px | 사용: L03 · 집중 중 / 가로 · 통일안<br>원본: [1166:1770](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1770) |
| [가로 휴식 상태 라벨](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3308) | UI 패턴 · 복제 | 182 × 36 px | 사용: L05 · 쉬는 시간 / 가로 · 통일안<br>원본: [1166:1783](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1783) |

<a id="components-07"></a>

### 14.7. 오버레이 · 패널

설정·인형 선택 바텀시트, 종료 확인 모달, 가구 편집 패널, 딤.

[Figma 분류 보드](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3316) · 5개 사례

| 사례 | 구분 | 실제 크기 · 상태 · 문구 | 사용 화면 · 참조 |
| --- | --- | --- | --- |
| [집중 시간 설정 시트](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3320) | UI 패턴 · 복제 | 390 × 489 px | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1590](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1590) |
| [인형 선택 시트](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3357) | UI 패턴 · 복제 | 390 × 489 px | 사용: 00 · 함께 집중할 인형 선택 · 통일안<br>원본: [1166:1749](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1749) |
| [집중 종료 확인 모달](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3390) | UI 패턴 · 복제 | 346 × 212 px | 사용: 화면 모달 · 통일안<br>원본: [1166:1657](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1657) |
| [선택 가구 도구 패널](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3404) | UI 패턴 · 복제 | 390 × 288 px | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1502](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1502) |
| [딤 오버레이](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3440) | UI 패턴 · 복제 | 390 × 844 px · 보기 28% | 사용: 화면 모달 · 통일안<br>원본: [1166:1656](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1656) |

<a id="components-08"></a>

### 14.8. 시스템 UI

상태 표시줄과 홈 인디케이터. 앱 콘텐츠와 분리해 관리합니다.

[Figma 분류 보드](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3447) · 3개 사례

| 사례 | 구분 | 실제 크기 · 상태 · 문구 | 사용 화면 · 참조 |
| --- | --- | --- | --- |
| [D1 / Status bar](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3451) | 기존 인스턴스 | 390 × 44 px<br>문구: 9:41 | 사용: 01 · 집중 메인 · 통일안 · 02 · 집중 설정 · 통일안 · 03 · 집중 중 · 통일안 · 화면 모달 · 통일안 · 04 · 일시정지 · 통일안 · 05 · 쉬는 시간 · 통일안 · 06 · 쓰다듬기 · 통일안 · 00 · 함께 집중할 인형 선택 · 통일안<br>원본: [1166:1524](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1524)<br>참조 8개 · master [1070:1434](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1070%3A1434) |
| [상태 표시줄 / WC](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3466) | UI 패턴 · 복제 | 342 × 44 px | 사용: 홈 — White &amp; Charcoal<br>원본: [1166:2796](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2796) |
| [홈 인디케이터](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3481) | UI 패턴 · 복제 | 134 × 4 px | 사용: 1안 · 홈 · 통일안<br>원본: [1166:1447](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1447) |

<a id="components-09"></a>

### 14.9. 아이콘

화면에서 실제 사용 중인 조작·내비게이션·공부 아이콘. 선형 UI 아이콘을 별도 조회합니다.

[Figma 분류 보드](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3488) · 34개 사례

| 사례 | 구분 | 실제 크기 · 상태 · 문구 | 사용 화면 · 참조 |
| --- | --- | --- | --- |
| [WC / Icon / bell](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3492) | 기존 인스턴스 | 24 × 24 px | 사용: 홈 — White &amp; Charcoal<br>원본: [I1166:2783;1166:2895](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2783%3B1166%3A2895)<br>참조 1개 · master [1052:550](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1052%3A550) |
| [WC / Icon / doll](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3502) | 기존 인스턴스 | 24 × 24 px | 사용: 홈 — White &amp; Charcoal<br>원본: [I1166:2785;1166:2895](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2785%3B1166%3A2895)<br>참조 1개 · master [1052:554](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1052%3A554) |
| [WC / Icon / bed](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3512) | 기존 인스턴스 | 24 × 24 px | 사용: 홈 — White &amp; Charcoal<br>원본: [I1166:2786;1166:2895](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2786%3B1166%3A2895)<br>참조 1개 · master [1052:558](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1052%3A558) |
| [WC / Icon / book](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3522) | 기존 인스턴스 | 24 × 24 px | 사용: 홈 — White &amp; Charcoal<br>원본: [I1166:2787;1166:2895](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2787%3B1166%3A2895)<br>참조 1개 · master [1052:562](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1052%3A562) |
| [WC / Icon / cloud](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3531) | 기존 인스턴스 | 24 × 24 px | 사용: 홈 — White &amp; Charcoal<br>원본: [I1166:2791;1166:2910](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2791%3B1166%3A2910)<br>참조 1개 · master [1052:565](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1052%3A565) |
| [WC / Icon / home](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3540) | 기존 인스턴스 | 24 × 24 px | 사용: 홈 — White &amp; Charcoal<br>원본: [I1166:2792;1166:2913](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2792%3B1166%3A2913)<br>참조 1개 · master [1052:546](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1052%3A546) |
| [WC / Icon / users](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3550) | 기존 인스턴스 | 24 × 24 px | 사용: 홈 — White &amp; Charcoal<br>원본: [I1166:2793;1166:2910](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2793%3B1166%3A2910)<br>참조 1개 · master [1052:568](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1052%3A568) |
| [WC / Icon / user](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3560) | 기존 인스턴스 | 24 × 24 px | 사용: 홈 — White &amp; Charcoal<br>원본: [I1166:2794;1166:2910](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2794%3B1166%3A2910)<br>참조 1개 · master [1052:572](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1052%3A572) |
| [WC / Icon / back](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3570) | 기존 인스턴스 | 24 × 24 px | 사용: 인형 제작 · 버전 6 — White &amp; Charcoal<br>원본: [I1166:2809;1166:2897](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2809%3B1166%3A2897)<br>참조 2개 · master [1052:537](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1052%3A537) |
| [WC / Icon / next](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3579) | 기존 인스턴스 | 24 × 24 px | 사용: 인형 제작 · 버전 6 — White &amp; Charcoal<br>원본: [I1166:2820;1166:2895](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2820%3B1166%3A2895)<br>참조 1개 · master [1052:540](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1052%3A540) |
| [WC / Icon / check](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3588) | 기존 인스턴스 | 16 × 16 px | 사용: 인형 제작 · 버전 6 — White &amp; Charcoal<br>원본: [I1166:2826;1166:2929;1166:2903](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A2826%3B1166%3A2929%3B1166%3A2903)<br>참조 1개 · master [1052:543](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1052%3A543) |
| [D1 / Icon / back](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3597) | 기존 인스턴스 | 24 × 24 px | 사용: 인형만들기 1 · 통일안 · 인형만들기 2 · 통일안 · 인형만들기 3 · 통일안 · 03 · 집중 중 · 통일안 · 화면 모달 · 통일안 · 04 · 일시정지 · 통일안 · 05 · 쉬는 시간 · 통일안 · 06 · 쓰다듬기 · 통일안 · L03 · 집중 중 / 가로 · 통일안 · L05 · 쉬는 시간 / 가로 · 통일안 · L06 · 쓰다듬기 / 가로 · 통일안<br>원본: [I1179:5819;1062:1022](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1179%3A5819%3B1062%3A1022)<br>참조 11개 · master [1062:940](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A940) |
| [D1 / Icon / next](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3606) | 기존 인스턴스 | 24 × 24 px | 사용: 인형만들기 1 · 통일안 · 인형만들기 2 · 통일안 · 인형만들기 3 · 통일안<br>원본: [I1179:5820;1062:1022](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1179%3A5820%3B1062%3A1022)<br>참조 3개 · master [1062:943](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A943) |
| [D1 / Icon / bell](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3615) | 기존 인스턴스 | 24 × 24 px | 사용: 1안 · 홈 · 통일안<br>원본: [I1166:1436;1166:1839](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1436%3B1166%3A1839)<br>참조 1개 · master [1062:964](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A964) |
| [D1 / Icon / doll](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3624) | 기존 인스턴스 | 24 × 24 px | 사용: 1안 · 홈 · 통일안<br>원본: [I1166:1438;1166:1839](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1438%3B1166%3A1839)<br>참조 1개 · master [1062:971](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A971) |
| [D1 / Icon / bed](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3634) | 기존 인스턴스 | 24 × 24 px | 사용: 1안 · 홈 · 통일안<br>원본: [I1166:1439;1166:1839](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1439%3B1166%3A1839)<br>참조 1개 · master [1062:975](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A975) |
| [D1 / Icon / book](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3643) | 기존 인스턴스 | 24 × 24 px | 사용: 1안 · 홈 · 통일안<br>원본: [I1166:1440;1166:1839](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1440%3B1166%3A1839)<br>참조 1개 · master [1062:978](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A978) |
| [D1 / Icon / cloud](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3652) | 기존 인스턴스 | 24 × 24 px | 사용: 1안 · 홈 · 통일안<br>원본: [I1166:1443;1166:1873](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1443%3B1166%3A1873)<br>참조 1개 · master [1062:981](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A981) |
| [D1 / Icon / home](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3661) | 기존 인스턴스 | 24 × 24 px | 사용: 1안 · 홈 · 통일안<br>원본: [I1166:1444;1166:1876](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1444%3B1166%3A1876)<br>참조 1개 · master [1062:967](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A967) |
| [D1 / Icon / users](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3671) | 기존 인스턴스 | 24 × 24 px | 사용: 1안 · 홈 · 통일안<br>원본: [I1166:1445;1166:1873](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1445%3B1166%3A1873)<br>참조 1개 · master [1062:984](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A984) |
| [D1 / Icon / user](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3681) | 기존 인스턴스 | 24 × 24 px | 사용: 1안 · 홈 · 통일안<br>원본: [I1166:1446;1166:1873](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1446%3B1166%3A1873)<br>참조 1개 · master [1062:988](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A988) |
| [D1 / Icon / check](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3691) | 기존 인스턴스 | 16 × 16 px | 사용: 1안 · 방꾸미기 · 통일안 · 01 · 집중 메인 · 통일안 · 02 · 집중 설정 · 통일안 · 00 · 함께 집중할 인형 선택 · 통일안<br>원본: [I1166:1498;1166:1851](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1498%3B1166%3A1851)<br>참조 6개 · master [1062:946](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A946) |
| [D1 / Icon / rotate](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3700) | 기존 인스턴스 | 24 × 24 px | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [I1166:1508;1166:1839](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1508%3B1166%3A1839)<br>참조 1개 · master [1062:995](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A995) |
| [D1 / Icon / flip](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3709) | 기존 인스턴스 | 24 × 24 px | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [I1166:1511;1166:1839](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1511%3B1166%3A1839)<br>참조 1개 · master [1062:998](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A998) |
| [D1 / Icon / paint](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3718) | 기존 인스턴스 | 24 × 24 px | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [I1166:1514;1166:1839](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1514%3B1166%3A1839)<br>참조 1개 · master [1062:1001](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A1001) |
| [D1 / Icon / trash](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3727) | 기존 인스턴스 | 24 × 24 px | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [I1166:1517;1166:1839](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1517%3B1166%3A1839)<br>참조 1개 · master [1062:992](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A992) |
| [D1 / Icon / minus](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3736) | 기존 인스턴스 | 24 × 24 px | 사용: 02 · 집중 설정 · 통일안<br>원본: [I1166:1595;1166:1839](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1595%3B1166%3A1839)<br>참조 1개 · master [1062:961](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A961) |
| [D1 / Icon / plus](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3745) | 기존 인스턴스 | 24 × 24 px | 사용: 02 · 집중 설정 · 통일안<br>원본: [I1166:1597;1166:1839](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1597%3B1166%3A1839)<br>참조 1개 · master [1062:958](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A958) |
| [D1 / Icon / pause](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3754) | 기존 인스턴스 | 24 × 24 px | 사용: 03 · 집중 중 · 통일안 · 화면 모달 · 통일안 · 05 · 쉬는 시간 · 통일안 · 06 · 쓰다듬기 · 통일안 · L03 · 집중 중 / 가로 · 통일안<br>원본: [I1166:1626;1166:1839](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1626%3B1166%3A1839)<br>참조 5개 · master [1062:949](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A949) |
| [D1 / Icon / stop](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3763) | 기존 인스턴스 | 24 × 24 px | 사용: 03 · 집중 중 · 통일안 · 화면 모달 · 통일안 · 04 · 일시정지 · 통일안<br>원본: [I1166:1633;1166:1839](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1633%3B1166%3A1839)<br>참조 3개 · master [1062:955](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A955) |
| [D1 / Icon / play](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3772) | 기존 인스턴스 | 24 × 24 px | 사용: 04 · 일시정지 · 통일안 · L05 · 쉬는 시간 / 가로 · 통일안 · L06 · 쓰다듬기 / 가로 · 통일안<br>원본: [I1166:1678;1166:1839](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=I1166%3A1678%3B1166%3A1839)<br>참조 3개 · master [1062:952](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1062%3A952) |
| [공부하기 아이콘](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3781) | UI 패턴 · 복제 | 48 × 48 px | 사용: 01 · 집중 메인 · 통일안<br>원본: [1185:1937](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1185%3A1937) |
| [책 읽기 아이콘](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3791) | UI 패턴 · 복제 | 48 × 48 px | 사용: 01 · 집중 메인 · 통일안<br>원본: [1185:1947](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1185%3A1947) |
| [과제하기 아이콘](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3801) | UI 패턴 · 복제 | 48 × 48 px | 사용: 01 · 집중 메인 · 통일안<br>원본: [1185:1957](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1185%3A1957) |

<a id="components-10"></a>

### 14.10. 콘텐츠 에셋

방·인형·가구·소품. UI 스타일 컴포넌트와 구분하며 숨김 상태의 참조 에셋도 포함합니다.

[Figma 분류 보드](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3815) · 23개 사례

| 사례 | 구분 | 실제 크기 · 상태 · 문구 | 사용 화면 · 참조 |
| --- | --- | --- | --- |
| [Room scene / Cotton bedroom](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3819) | 기존 인스턴스 | 390 × 390 px · 보기 62% | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1471](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1471)<br>참조 1개 · master [984:4471](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=984%3A4471) |
| [Cotton / 솜뭉치/State6](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3827) | 기존 인스턴스 | 65 × 72 px | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1478](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1478)<br>참조 1개 · master [1005:141](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1005%3A141) |
| [Room object / Cotton chair](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3835) | 기존 인스턴스 | 113 × 113 px<br>Color=Pink, Facing=A | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1480](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1480)<br>참조 1개 · master [984:4477](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=984%3A4477) |
| [Room object / Cotton chair](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3843) | 기존 인스턴스 · 원본 숨김 | 113 × 113 px<br>Color=Pink, Facing=B | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1481](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1481)<br>참조 1개 · master [984:4479](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=984%3A4479) |
| [Room object / Cotton chair](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3851) | 기존 인스턴스 · 원본 숨김 | 113 × 113 px<br>Color=Lavender, Facing=A | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1482](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1482)<br>참조 1개 · master [984:4481](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=984%3A4481) |
| [Room object / Cotton chair](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3859) | 기존 인스턴스 · 원본 숨김 | 113 × 113 px<br>Color=Lavender, Facing=B | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1483](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1483)<br>참조 1개 · master [984:4483](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=984%3A4483) |
| [Cotton / 솜뭉치](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3867) | 기존 인스턴스 | 190 × 200 px<br>State=Idle | 사용: 01 · 집중 메인 · 통일안<br>원본: [1179:5920](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5920)<br>참조 1개 · master [1029:1113](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1029%3A1113) |
| [Cotton / Room interior](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3875) | 기존 인스턴스 | 342 × 312 px · 보기 77% | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1577](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1577)<br>참조 1개 · master [999:838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=999%3A838) |
| [Cotton / 솜뭉치](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3883) | 기존 인스턴스 | 220 × 232 px<br>State=Idle | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1578](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1578)<br>참조 1개 · master [1029:1113](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1029%3A1113) |
| [Cotton / Flower cushion](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3891) | 기존 인스턴스 · 원본 숨김 | 42 × 36 px | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1582](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1582)<br>참조 1개 · master [999:851](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=999%3A851) |
| [Cotton / Room interior](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3899) | 기존 인스턴스 | 390 × 844 px · 보기 28% | 사용: 03 · 집중 중 · 통일안 · 화면 모달 · 통일안 · 04 · 일시정지 · 통일안 · 05 · 쉬는 시간 · 통일안 · 06 · 쓰다듬기 · 통일안<br>원본: [1166:1613](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1613)<br>참조 5개 · master [999:838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=999%3A838) |
| [Cotton / 솜뭉치](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3907) | 기존 인스턴스 | 310 × 334 px · 보기 72%<br>State=Working A | 사용: 03 · 집중 중 · 통일안 · 화면 모달 · 통일안 · 04 · 일시정지 · 통일안 · L03 · 집중 중 / 가로 · 통일안<br>원본: [1166:1614](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1614)<br>참조 4개 · master [1029:1107](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1029%3A1107) |
| [Cotton / Flower cushion](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3915) | 기존 인스턴스 | 52 × 44 px | 사용: 03 · 집중 중 · 통일안 · 화면 모달 · 통일안 · 04 · 일시정지 · 통일안 · 05 · 쉬는 시간 · 통일안 · 06 · 쓰다듬기 · 통일안<br>원본: [1166:1620](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1620)<br>참조 5개 · master [999:851](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=999%3A851) |
| [Cotton / Flower cushion](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3923) | 기존 인스턴스 · 원본 숨김 | 40 × 35 px | 사용: 03 · 집중 중 · 통일안 · 화면 모달 · 통일안 · 04 · 일시정지 · 통일안<br>원본: [1166:1629](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1629)<br>참조 3개 · master [999:851](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=999%3A851) |
| [Cotton / 솜뭉치](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3931) | 기존 인스턴스 | 260 × 274 px · 보기 88%<br>State=Idle | 사용: 05 · 쉬는 시간 · 통일안<br>원본: [1166:1688](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1688)<br>참조 1개 · master [1029:1113](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1029%3A1113) |
| [Cotton / 솜뭉치](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3939) | 기존 인스턴스 | 260 × 274 px · 보기 88%<br>State=Happy | 사용: 06 · 쓰다듬기 · 통일안<br>원본: [1166:1707](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1707)<br>참조 1개 · master [1029:1115](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1029%3A1115) |
| [Cotton / Room interior](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3947) | 기존 인스턴스 | 844 × 390 px · 보기 46% | 사용: L03 · 집중 중 / 가로 · 통일안 · L05 · 쉬는 시간 / 가로 · 통일안 · L06 · 쓰다듬기 / 가로 · 통일안<br>원본: [1166:1764](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1764)<br>참조 3개 · master [999:838](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=999%3A838) |
| [Cotton / 솜뭉치](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3955) | 기존 인스턴스 | 250 × 264 px · 보기 91%<br>State=Idle | 사용: L05 · 쉬는 시간 / 가로 · 통일안<br>원본: [1166:1777](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1777)<br>참조 1개 · master [1029:1113](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1029%3A1113) |
| [Cotton / 솜뭉치](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3963) | 기존 인스턴스 | 250 × 264 px · 보기 91%<br>State=Happy | 사용: L06 · 쓰다듬기 / 가로 · 통일안<br>원본: [1166:1788](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1788)<br>참조 1개 · master [1029:1115](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1029%3A1115) |
| [홈 방 배경](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3971) | UI 패턴 · 복제 | 477 × 844 px · 보기 28% | 사용: 1안 · 홈 · 통일안<br>원본: [1166:1428](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1428) |
| [홈 인형 이미지](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3978) | UI 패턴 · 복제 | 111 × 151 px | 사용: 1안 · 홈 · 통일안<br>원본: [1166:1429](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1429) |
| [제작 인형 이미지](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3989) | UI 패턴 · 복제 | 163 × 241 px · 보기 100% | 사용: 인형만들기 1 · 통일안<br>원본: [1166:1348](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1348) |
| [작업대 · 소품 묶음](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A3996) | UI 패턴 · 복제 · 원본 숨김 | 306 × 105 px | 사용: 03 · 집중 중 · 통일안<br>원본: [1166:1615](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1615) |

<a id="components-11"></a>

### 14.11. 미리보기 · 편집 패턴

이미지와 조작 UI가 결합된 전체 문맥. 이미지와 UI 레이어를 그대로 분리한 복제본입니다.

[Figma 분류 보드](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A4008) · 5개 사례

| 사례 | 구분 | 실제 크기 · 상태 · 문구 | 사용 화면 · 참조 |
| --- | --- | --- | --- |
| [인형 제작 미리보기 / D1](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A4012) | UI 패턴 · 복제 | 358 × 306 px | 사용: 인형만들기 1 · 통일안<br>원본: [1179:5811](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5811), [1166:1348](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1348) |
| [인형 제작 미리보기 / WC](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A4036) | UI 패턴 · 복제 | 342 × 224 px | 사용: 인형 제작 · 버전 6 — White &amp; Charcoal<br>원본: [1166:2817](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A2817) |
| [집중 메인 동반자 미리보기](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A4052) | UI 패턴 · 복제 | 358 × 350 px | 사용: 01 · 집중 메인 · 통일안<br>원본: [1179:5911](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1179%3A5911) |
| [방 배치 편집 영역](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A4070) | UI 패턴 · 복제 | 390 × 520 px | 사용: 1안 · 방꾸미기 · 통일안<br>원본: [1166:1470](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1470) |
| [공부방 미리보기](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1194%3A4093) | UI 패턴 · 복제 | 342 × 312 px | 사용: 02 · 집중 설정 · 통일안<br>원본: [1166:1576](https://www.figma.com/design/y50EtliLp7YMR80gHuJRLb/?node-id=1166%3A1576) |

<a id="open-items"></a>

## 15. 우선 확인할 미정·보정 항목

다음은 **문서화된 현재의 차이와 확인 과제**다. 이 문서로 인해 UI에 자동 반영되거나 확정된 권장값으로 바뀐 것은 아니다.

| 항목 | 현재 확인 내용 | 적용 시 처리 |
| --- | --- | --- |
| 보조 글자 대비 | `text/secondary / bg/screen` 3.37:1 | 일반 작은 글자 기준 4.5:1 미만. 새 값은 별도 결정 |
| 주요 버튼 글자 대비 | 흰 글자 / 민트 주요 버튼 2.18:1 | 현재 색상 유지 상태. 통과했다고 간주하지 않음 |
| 민트 글자 대비 | `text/accent / bg/surface` 3.67:1 | 작은 글자 사용 위치 검토 |
| 눌림 상태 | MIB `primary-pressed` 미정 | `action/primary-light`를 임의로 눌림색으로 대체하지 않음 |
| 오류 상태 | D1 삭제 의미색은 확인; MIB 전용 오류 변수·오류 입력 상태 미확인 | 오류 입력 상태를 이미 설계된 것으로 간주하지 않음 |
| 터치 영역 | 시간 +/- 조작 30×30px | 44×44px 외부 터치 영역 확보는 미적용 보정 제안 |
| 규격 혼재 | D1 / WC의 버튼·간격·곡률·타이포 차이 | 어느 계열을 적용하는지 명시; 임의 평균값 생성 금지 |
| 이전 색상 | 하늘색·노란 미리보기, 갈색 조작, 별도 연두 탭 | legacy를 MIB 공통 토큰으로 자동 승격하지 않음 |
| 글래스 | 가이드와 실제 opacity/색상 차이 | 사진 합성 결과의 대비는 별도 확인 필요 |
| 로고 서체 | NotCliche OTF가 실제 사용되나 명세 작성 런타임에서 미제공 | 원본 폰트를 임의로 대체하지 않음 |
| 안전영역·숫자 고정폭 | Figma 좌표와 OS inset, 고정폭 숫자 기능은 별개 | 런타임 구현 단계에서 확인 |

상세값·근거는 [12. 검증·미정 항목](#tokens-12)을 따른다. 대비값은 원본 명세의 계산 결과이며, 이번 MD 변환에서 사진·투명 표면까지 새로 검증한 결과가 아니다.

<a id="maintenance"></a>

## 16. 문서 갱신 방법

1. 위 두 원본 프레임의 최신 내용을 다시 읽는다. 원본 앱 화면과 문서 프레임이 서로 달라졌다면 둘의 차이를 먼저 명시한다.
2. `source_spec_date`, `export_date`, 버전을 갱신하고 변경한 토큰 및 컴포넌트 사례를 기록한다.
3. MIB 변수명, primitive 별칭, D1/WC 구분, 원본 ID를 보존한다. 임의의 신규 값을 현재값 표에 섞지 않는다.
4. 확정된 보정만 `proposed/unresolved`에서 `existing/observed`로 변경한다. 문서상 상태 변경과 실제 Figma 반영 여부를 함께 확인한다.
5. 섹션별 행 수와 컴포넌트 분류별 사례 수를 대조한다. 삭제·병합한 경우 이유를 변경 이력에 남긴다.
6. Shadow/elevation 제외 범위를 유지한다. 추후 포함 요청이 있을 때 별도 범위 변경으로 기록한다.

### 변경 이력

| 버전 | 날짜 | 내용 |
| --- | --- | --- |
| 1.0-observed | 2026-11-01 | Figma 토큰 명세 199개 행과 카탈로그 176개 사례를 최초 통합. 상태·단위 열과 문서 내 탐색 및 Figma 원본 링크 추가. 원본 UI 수정 없음 |

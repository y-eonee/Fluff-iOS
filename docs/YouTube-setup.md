# YouTube 계정 연결 설정

현재 링크 재생과 플레이리스트 링크 추가는 별도 API 키 없이 동작합니다. 계정의 플레이리스트를 불러오는 기능에는 프로젝트 소유자가 발급한 iOS OAuth 클라이언트 ID가 필요합니다.

2026-11-10 사용자가 전달한 클라이언트 ID `656625582532-j8l9lqtc79aeq3s0nd1vqdk6gh4qfsvm.apps.googleusercontent.com`과 대응하는 URL 스킴을 `Configuration/Info.plist`에 연결했습니다. 실제 계정의 동의 및 플레이리스트 불러오기는 기기에서 확인해야 합니다.

같은 날 ‘Google 인증 절차를 완료하지 않음’ 오류를 확인했습니다. 콘솔의 게시 상태가 테스트 중이고 테스트 사용자가 0명이어서, 사용자가 지정한 본인 계정 1명을 테스트 사용자로 등록했습니다. 앱 재설치 없이 로그인 창을 닫고 해당 계정으로 다시 연결합니다. 테스트 사용자 등록은 공개 배포용 OAuth 검증 완료와는 별개입니다.

1. [Google Cloud 콘솔](https://console.cloud.google.com/)에 로그인하고 Fluff용 프로젝트를 생성하거나 선택합니다.
2. **API 및 서비스 → 라이브러리**에서 **YouTube Data API v3**를 찾아 사용 설정합니다.
3. **Google Auth Platform**에서 브랜딩(앱 이름 Fluff, 지원 이메일, 연락처)과 대상(외부)을 설정합니다. 테스트 상태에서는 본인의 Google 계정을 테스트 사용자로 추가합니다. 데이터 액세스에는 `https://www.googleapis.com/auth/youtube.readonly`를 추가합니다. 콘솔에 예전 메뉴가 보이면 **API 및 서비스 → OAuth 동의 화면**에서 설정합니다.
4. **클라이언트 → 클라이언트 만들기**(또는 **사용자 인증 정보 → OAuth 클라이언트 ID**)에서 유형 **iOS**, 번들 ID **`com.nayeon.Malrang`**, 팀 ID **`CG37U6CMKP`**를 입력합니다. App Store ID는 배포용 ID가 생기면 실제 값을 입력합니다.
5. 생성된 **클라이언트 ID**(`…apps.googleusercontent.com`)를 복사합니다. 이 값만 전달하면 프로젝트에 연결할 수 있습니다. 비밀번호나 클라이언트 시크릿은 필요하지 않습니다.

## 프로젝트에 입력하기

직접 입력할 경우 아래 두 값을 변경한 뒤 앱을 다시 빌드합니다.

1. `Configuration/Info.plist`의 `GIDClientID`에 발급한 `123-abc.apps.googleusercontent.com` 형식의 ID를 넣습니다.
2. 같은 파일의 `CFBundleURLTypes → CFBundleURLSchemes`를 역순 ID인 `com.googleusercontent.apps.123-abc`로 바꿉니다.
3. 실제 기기에서 소파 → 유튜브 같이 보기 → 인형 선택 → 계정 연결을 진행하고, YouTube 읽기 권한을 허용합니다.

요청하는 범위는 `https://www.googleapis.com/auth/youtube.readonly`입니다. 실제 배포 전에는 Google의 OAuth 검증 요구사항을 확인하고 필요한 검증을 완료해야 합니다. OAuth 클라이언트 **시크릿은 iOS 앱에 넣지 않습니다**. 로그인 토큰은 Google Sign-In SDK가 관리하며 앱의 UserDefaults에 저장하지 않습니다.

## 확인할 동작

- 로그인 취소 및 읽기 권한 거절 후 재시도
- 플레이리스트 없음, 여러 페이지에 걸친 목록, 만료된 토큰 갱신
- 계정 카드 ‘변경’ → 다시 불러오기 / 연결 해제 후 다른 계정 연결
- 영상과 플레이리스트 링크, 비공개·삭제·임베드 제한 영상의 안내
- 시청 화면 → 홈 미니 플레이어 전환 시 재생 위치 유지
- 탭 변경, 다른 활동, 앱 비활성화 시 일시정지

Google 로그인은 목록을 가져오기 위한 권한입니다. WKWebView의 YouTube 재생 세션에 Google OAuth 토큰을 주입하지 않습니다. 비공개·연령 제한 등 임베드할 수 없는 영상은 YouTube에서 열 수 있도록 안내합니다.

참고: [Google Sign-In iOS 설정](https://developers.google.com/identity/sign-in/ios/start-integrating), [API 접근](https://developers.google.com/identity/sign-in/ios/api-access), [YouTube 플레이리스트 API](https://developers.google.com/youtube/data/docs/playlists/list), [YouTube 임베드 플레이어](https://developers.google.com/youtube/iframe_api_reference).

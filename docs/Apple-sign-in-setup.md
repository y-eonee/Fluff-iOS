# Apple 로그인 연결 상태와 설정

앱에는 시스템 Apple 로그인 버튼, 성공·취소·실패 처리, Keychain의 사용자 식별자 보관, 앱 활성화 시 권한 확인, 권한 철회 시 로그아웃이 연결되어 있습니다. 인형과 방은 이 기기의 SwiftData에 저장되며 서버 계정이나 기기 간 동기화를 생성하지 않습니다. 기존 개발 버전의 방은 보존하고 첫 Apple 인증 시 연결합니다. 다른 Apple 계정으로 기존 방을 열 수는 없습니다.

## 실제 기기 서명 설정

2026-11-10: 개발자 계정 로그인과 최신 Program License Agreement 동의 후 자동 서명 발급이 성공했습니다. 갱신된 `com.nayeon.Malrang` 프로파일의 `com.apple.developer.applesignin = [Default]`를 확인했고, Metal 포함 기기 빌드를 iPhone에 설치했습니다. 새 환경에서 설정할 때는 다음 순서를 따릅니다.

같은 날 사용자가 실제 iPhone에서 Apple 인증 후 프로필 만들기로 정상 이동하는 것을 확인했습니다.

1. Xcode → Settings → Accounts에서 이 앱의 Apple Developer 계정으로 로그인합니다.
2. [Apple Developer의 Identifiers](https://developer.apple.com/account/resources/identifiers/list)에서 `com.nayeon.Malrang`을 선택하고 **Sign In with Apple** 기능을 활성화합니다. 팀은 현재 프로젝트의 `CG37U6CMKP`와 일치해야 합니다.
3. Xcode → Malrang 타깃 → Signing & Capabilities에서 팀을 확인하고 Automatically manage signing을 켭니다. 프로젝트의 Sign In with Apple 기능과 `Malrang.entitlements`는 추가되어 있습니다.
4. iPhone을 대상으로 다시 빌드합니다. 갱신된 프로파일에 `com.apple.developer.applesignin`이 포함되어야 합니다.
5. 실제 Apple 계정으로 로그인 성공, 취소, 로그아웃 후 재로그인, Apple 설정에서 연결 해제 후 재진입을 확인합니다. 사용자 인증은 기기 소유자가 직접 진행합니다.

## 배포 전에 필요한 서버 작업

현재 프로젝트에는 인증 서버가 없습니다. 서버 계정을 제공하려면 서버에서 Apple identity token의 서명·issuer·audience·nonce를 검증하고 authorization code를 교환해야 합니다. Apple 개인 키나 client secret을 앱에 넣으면 안 됩니다.

현재 회원탈퇴는 기기 안의 인형·방·프로필·YouTube 시청 목록과 로컬 로그인 정보를 삭제합니다. Apple의 연결 권한 자체는 해제하지 않으며 확인 창에도 이를 안내합니다. **App Store 배포 전에는 서버의 Apple 토큰 폐기(`/auth/revoke`)와 계정 삭제를 연결해야 합니다.** Apple 계정 연결은 [Apple 계정 관리](https://account.apple.com/)에서도 해제할 수 있습니다.

참고: [Apple의 계정 삭제·토큰 폐기 안내](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple), [Apple 로그인 구현](https://developer.apple.com/documentation/authenticationservices/implementing-user-authentication-with-sign-in-with-apple).

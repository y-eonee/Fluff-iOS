import AuthenticationServices
import SwiftUI

/// Apple 인증이 성공한 뒤에만 홈으로 이동한다.
struct OnboardingView: View {
    let onStart: () -> Void
    @State private var account = AppleAccount()
    @State private var showsPrivacy = false
    @AppStorage("showAppleDisconnectHelp") private var showAppleDisconnectHelp = false
    @Environment(\.openURL) private var openURL
    @Environment(\.startupPresentationFinished) private var startupPresentationFinished

    var body: some View {
        ZStack(alignment: .bottom) {
            BrandSplashView()
            VStack(spacing: Spacing.s) {
                if startupPresentationFinished {
                    SignInWithAppleButton(.continue) { request in
                        account.prepare(request)
                    } onCompletion: { result in
                        if account.complete(result) { onStart() }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 48)
                    .clipShape(Capsule())
                    .accessibilityIdentifier("apple-sign-in")
                    if AppleAccount.canContinueWithoutSignIn {
                        Button("로그인 없이 시작하기", action: onStart)
                            .pretendard(.medium, 14).frame(minHeight: 44)
                    }
                    Button("개인정보처리방침") { showsPrivacy = true }
                        .pretendard(.regular, 13).frame(minHeight: 44)
                }
                if let message = account.message {
                    Text(message).pretendard(.regular, 13)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("apple-sign-in-error")
                }
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, Spacing.l)
            .padding(.bottom, Spacing.l)
        }
        .foregroundStyle(Color.mib.text.primary)
        .alert("기기의 계정 정보가 삭제됐어요", isPresented: $showAppleDisconnectHelp) {
            Button("Apple 연결 해제 안내") { openURL(URL(string: "https://support.apple.com/102571")!) }
            Button("확인", role: .cancel) {}
        } message: {
            Text("Apple 계정의 로그인 연결은 설정 → Apple 계정 → Apple로 로그인에서 fluff를 선택해 해제할 수 있어요. Google 연결은 Google 계정의 연결 관리에서도 해제할 수 있어요.")
        }
        .sheet(isPresented: $showsPrivacy) {
            NavigationStack { PrivacyPolicyView().toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("닫기") { showsPrivacy = false } }
            } }
        }
    }
}

#Preview("로그인") {
    OnboardingView {}
}

#Preview("큰 글씨") {
    OnboardingView {}.environment(\.dynamicTypeSize, .accessibility3)
}

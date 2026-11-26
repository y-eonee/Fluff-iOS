import AuthenticationServices
import SwiftUI

/// Apple 인증이 성공한 뒤에만 홈으로 이동한다.
struct OnboardingView: View {
    let onStart: () -> Void
    @State private var account = AppleAccount()
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
                    .frame(height: D1.buttonHeight)
                    .clipShape(Capsule())
                    .accessibilityIdentifier("apple-sign-in")
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
    }
}

#Preview("로그인") {
    OnboardingView {}
}

#Preview("큰 글씨") {
    OnboardingView {}.environment(\.dynamicTypeSize, .accessibility3)
}

import AuthenticationServices
import SwiftUI

/// Apple 인증이 성공한 뒤에만 홈으로 이동한다.
struct OnboardingView: View {
    let onStart: () -> Void
    @State private var account = AppleAccount()

    var body: some View {
        VStack(spacing: Spacing.l) {
            GeometryReader { geometry in
                let width = min(geometry.size.width * 0.82, geometry.size.height * 0.62, 360)
                FluffLogo()
                    .frame(width: width)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            VStack(spacing: Spacing.s) {
                SignInWithAppleButton(.continue) { request in
                    account.prepare(request)
                } onCompletion: { result in
                    if account.complete(result) { onStart() }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: D1.buttonHeight)
                .clipShape(Capsule())
                .accessibilityIdentifier("apple-sign-in")
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
        .background(Color.mib.bg.screen.ignoresSafeArea())
    }
}

#Preview("로그인") {
    OnboardingView {}
}

#Preview("큰 글씨") {
    OnboardingView {}.environment(\.dynamicTypeSize, .accessibility3)
}

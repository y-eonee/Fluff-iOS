import SwiftUI

/// 간편 가입. 실제 Apple/카카오 로그인은 서버가 정해진 뒤 연결한다.
struct OnboardingView: View {
    let onStart: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 650 || typeSize.isAccessibilitySize
            let logoWidth = min(geometry.size.width - Spacing.xl, geometry.size.height * (compact ? 0.42 : 0.6), 420)
            ZStack {
                Group {
                    if !typeSize.isAccessibilitySize {
                        Image("splash_star").resizable().scaledToFit()
                            .frame(width: compact ? 40 : 56).rotationEffect(.degrees(-15))
                            .position(x: geometry.size.width * 0.16, y: geometry.size.height * 0.14)
                        Image("splash_flower").resizable().scaledToFit()
                            .frame(width: compact ? 36 : 48).rotationEffect(.degrees(10))
                            .position(x: geometry.size.width * 0.84, y: geometry.size.height * 0.12)
                        Image("splash_cloud").resizable().scaledToFit()
                            .frame(width: compact ? 64 : 92).rotationEffect(.degrees(-6))
                            .position(x: geometry.size.width * 0.18, y: geometry.size.height * 0.65)
                        Image("splash_bear").resizable().scaledToFit()
                            .frame(width: compact ? 56 : 80).rotationEffect(.degrees(12))
                            .position(x: geometry.size.width * 0.83, y: geometry.size.height * 0.67)
                    }
                }
                .accessibilityHidden(true)

                VStack(spacing: compact ? Spacing.m : Spacing.l) {
                    Spacer(minLength: Spacing.m)
                    FluffLogo().frame(width: logoWidth)
                    VStack(spacing: Spacing.xs) {
                        Text("갤러리 속 무엇이든 인형으로!")
                        Text("나만의 작은 아지트, Fluff")
                    }
                    .font(.custom("Pretendard-SemiBold", size: 16, relativeTo: .body))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: Spacing.l)

                    VStack(spacing: Spacing.s) {
                        Button(action: onStart) {
                            Label("Apple로 시작하기", systemImage: "apple.logo")
                        }
                        .buttonStyle(LoginButtonStyle())
                        Button(action: onStart) {
                            Label("카카오로 시작하기", systemImage: "message.fill")
                        }
                        .buttonStyle(LoginButtonStyle(isPrimary: false))
                    }
                }
                .frame(maxWidth: 420)
                .padding(compact ? Spacing.m : Spacing.l)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundStyle(Color.a.brown)
        .background { FluffBackdrop() }
    }
}

private struct LoginButtonStyle: ButtonStyle {
    var isPrimary = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Pretendard-SemiBold", size: 17, relativeTo: .headline))
            .foregroundStyle(Color.a.brown)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.m)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background {
                RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                    .fill(isPrimary ? Color.a.pinkLight : Color.a.yellowLight)
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

#Preview("로그인") {
    OnboardingView {}
}

#Preview("큰 글씨") {
    OnboardingView {}.environment(\.dynamicTypeSize, .accessibility3)
}

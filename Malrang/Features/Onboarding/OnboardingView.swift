import SwiftUI

/// 간편 가입. 실제 Apple/카카오 로그인은 서버가 정해진 뒤 연결한다.
struct OnboardingView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: Spacing.l) {
            Spacer()
            DollArtwork(shape: .bear, cutout: Image(systemName: "heart.fill"))
                .frame(width: 180)
            VStack(spacing: Spacing.xs) {
                Text("말랑")
                    .font(.largeTitle.bold())
                Text("갤러리 속 최애로 나만의 인형을 만들어요")
                    .font(.body)
                    .foregroundStyle(Color.app.inkSecondary)
            }
            Spacer()
            VStack(spacing: Spacing.s) {
                Button(action: onStart) {
                    Label("Apple로 시작하기", systemImage: "apple.logo")
                }
                .buttonStyle(.primary)
                Button(action: onStart) {
                    Label("카카오로 시작하기", systemImage: "message.fill")
                }
                .buttonStyle(.secondary)
            }
        }
        .foregroundStyle(Color.app.ink)
        .padding(Spacing.m)
        .background(Color.app.background)
    }
}

#Preview {
    OnboardingView {}
}

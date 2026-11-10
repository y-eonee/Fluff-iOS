import SwiftUI

/// 승인된 A안: 아이보리 바탕 위의 봉제 인형 얼굴과 민트 Fluff 로고.
struct SplashView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width * 0.82, geometry.size.height * 0.62, 360)
            ZStack {
                Color.mib.bg.screen
                FluffLogo().frame(width: width)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fluff, 나만의 작은 아지트")
    }
}

/// 스플래시와 로그인에서 승인된 동일한 브랜드 이미지를 사용한다.
struct FluffLogo: View {
    var body: some View {
        Image("fluff_splash_lockup")
            .resizable()
            .scaledToFit()
            .accessibilityLabel("Fluff")
            .accessibilityIdentifier("fluff-brand-mark")
    }
}

#Preview("세로") { SplashView() }
#Preview("가로", traits: .landscapeLeft) { SplashView() }

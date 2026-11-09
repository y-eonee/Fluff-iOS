import SwiftUI

/// 승인된 A안: 아이보리 바탕 위의 봉제 인형 얼굴과 민트 Fluff 로고.
struct SplashView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width * 0.82, geometry.size.height * 0.62, 360)
            ZStack {
                Color.mib.bg.screen
                Image("fluff_splash_lockup")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fluff, 나만의 작은 아지트")
    }
}

struct FluffBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, geometry.size.height * 0.75, 540)
            ZStack(alignment: .top) {
                Color("splash_paper")
                Image("splash_grid").resizable(resizingMode: .tile)
                Image("splash_curtain")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: width * 0.23, alignment: .bottom)
                    .clipped()
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct FluffLogo: View {
    var body: some View {
        ZStack {
            Image("splash_orbit").resizable().scaledToFit()
            Image("splash_logo").resizable().scaledToFit()
                .scaleEffect(0.88 / 0.92)
        }
        .aspectRatio(1022.369 / 521.637, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fluff")
    }
}

#Preview("세로") { SplashView() }
#Preview("가로", traits: .landscapeLeft) { SplashView() }

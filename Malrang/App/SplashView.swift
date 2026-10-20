import SwiftUI

/// 피그마 표지의 봉제 로고와 패치를 세로 화면에 맞춘 공통 시작 화면.
struct SplashView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, geometry.size.height * 0.75, 540)
            ZStack {
                FluffBackdrop()

                VStack(spacing: Spacing.l) {
                    FluffLogo().frame(width: width * 0.92)
                    VStack(spacing: Spacing.xs) {
                        Text("갤러리 속 무엇이든 인형으로!")
                        Text("나만의 작은 아지트, Fluff")
                    }
                    .font(.custom("Pretendard-SemiBold", size: 16, relativeTo: .body))
                    .foregroundStyle(Color.a.brown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.m)
                }

                Image("splash_star")
                    .resizable().scaledToFit()
                    .frame(width: width * 0.16)
                    .position(x: geometry.size.width * 0.16, y: geometry.size.height * 0.29)
                Image("splash_flower")
                    .resizable().scaledToFit()
                    .frame(width: width * 0.14)
                    .position(x: geometry.size.width * 0.84, y: geometry.size.height * 0.27)
                Image("splash_cloud")
                    .resizable().scaledToFit()
                    .frame(width: width * 0.26)
                    .position(x: geometry.size.width * 0.19, y: geometry.size.height * 0.75)
                Image("splash_bear")
                    .resizable().scaledToFit()
                    .frame(width: width * 0.23)
                    .position(x: geometry.size.width * 0.82, y: geometry.size.height * 0.78)
            }
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

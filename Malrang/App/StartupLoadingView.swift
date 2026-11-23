import SwiftUI

/// Default loading for signed-out startup and isolated design previews.
struct StartupLoadingView: View {
    var onFinished: () -> Void = {}
    @State private var entrance = RoomEntrance(.home)
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: entrance.finished)) { _ in
            if !entrance.finished { RoomLoadingView(entrance: entrance) }
        }
        .task {
            entrance.prepareScene(); entrance.present()
            while !entrance.finished && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
                entrance.finishIfNeeded()
            }
            if entrance.finished { onFinished() }
        }
    }
}

/// 로그인 화면의 브랜드 이미지. 시작 로딩과는 별도로 유지한다.
struct FluffLogo: View {
    var body: some View {
        Image("fluff_splash_lockup")
            .resizable()
            .scaledToFit()
            .accessibilityLabel("Fluff")
            .accessibilityIdentifier("fluff-brand-mark")
    }
}

#Preview("세로") { StartupLoadingView() }
#Preview("가로", traits: .landscapeLeft) { StartupLoadingView() }

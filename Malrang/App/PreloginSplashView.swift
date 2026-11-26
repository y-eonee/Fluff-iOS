import SwiftUI

/// Figma 2028:9192: the five original 1927:38 variants share one 8.4s clock.
/// The final veil reveals Apple sign-in instead of the design's sample room.
struct PreloginSplashView: View {
    var previewTime: Double? = nil
    var onFinished: () -> Void = {}
    @State private var elapsed: Double = 0
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let timeline = RoomLoadingTimeline.prelogin
    private let assets = ["mongle", "round", "soft", "fluffy", "pressed"]
    private let iconNodes = ["2031:4", "2031:12", "2031:20", "2031:28", "2031:36"]
    private let shadowNodes = ["2031:3", "2031:11", "2031:19", "2031:27", "2031:35"]

    private var time: Double { reduceMotion ? 0 : previewTime ?? elapsed }
    private var duration: Double { reduceMotion ? 0.35 : timeline.duration }

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 390, geometry.size.height / 844)
            ZStack {
                RepresentativeGradientFill(definition: RoomLoadingView.veil)
                    .opacity(value("2028:9194", "opacity", fallback: 1))
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 4) {
                        ForEach(assets.indices, id: \.self) { index in
                            character(index)
                        }
                    }
                    .frame(width: 316, height: 72, alignment: .topLeading)
                    .scaleEffect(value("2028:9195", "--scale-transform", fallback: 1))
                    .opacity(value("2028:9195", "opacity", fallback: 1))
                    .offset(x: 37, y: 370)

                    Image("splash_jump_wordmark").resizable().scaledToFit()
                        .frame(width: 63, height: 39)
                        .opacity(value("2028:9194", "opacity", fallback: 1))
                        .offset(x: 164, y: 453)
                }
                .frame(width: 390, height: 844, alignment: .topLeading)
                .scaleEffect(scale)
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("fluff 시작 중")
        .accessibilityIdentifier("prelogin-splash")
        .task(id: scenePhase) {
            guard previewTime == nil, scenePhase == .active else { return }
            // Cancellation pauses the shared clock in the background. Re-entry
            // resumes from elapsed rather than skipping unfinished jumps.
            var previous = ProcessInfo.processInfo.systemUptime
            while elapsed < duration {
                do { try await Task.sleep(for: .milliseconds(16)) }
                catch { return }
                guard !Task.isCancelled else { return }
                let now = ProcessInfo.processInfo.systemUptime
                elapsed = min(duration, elapsed + now - previous)
                previous = now
            }
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }

    private func character(_ index: Int) -> some View {
        let icon = iconNodes[index], shadow = shadowNodes[index]
        return ZStack(alignment: .topLeading) {
            Ellipse().fill(Color.rep4.c07)
                .frame(width: 36, height: 5)
                .scaleEffect(x: value(shadow, "--scaleX-transform", fallback: 1), y: 1)
                .opacity(value(shadow, "opacity", fallback: 1))
                .offset(x: 12, y: 60)
            Image("splash_jump_" + assets[index]).resizable().scaledToFit()
                .frame(width: 60, height: 60)
                .scaleEffect(x: value(icon, "--scaleX-transform", fallback: 1),
                             y: value(icon, "--scaleY-transform", fallback: 1))
                .offset(y: value(icon, "--translateY-transform"))
        }
        .frame(width: 60, height: 72, alignment: .topLeading)
    }

    private func value(_ node: String, _ property: String, fallback: Double = 0) -> Double {
        timeline.value(node, property, at: time, fallback: fallback)
    }
}

#Preview { PreloginSplashView(previewTime: 0.35) }

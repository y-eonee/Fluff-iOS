import SwiftUI

/// 완성 화면 뒤에서 풍선이 계속 떠오르고 폭죽이 연달아 터지는 연출.
/// 움직임 줄이기가 켜져 있으면 가만히 있는 풍선만 보인다.
struct Celebration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let colors = [Color.app.accent, Color.app.pastelSky, Color.app.pastelYellow, Color.app.pastelMint]
    private let burstInterval = 1.4
    private let sparksPerBurst = 12

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let time: Double = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                drawBalloons(&context, size: size, time: time)
                if !reduceMotion {
                    drawFireworks(&context, size: size, time: time)
                }
            } symbols: {
                ForEach(colors.indices, id: \.self) { index in
                    Image(systemName: "balloon.fill")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundStyle(colors[index])
                        .tag("balloon\(index)")
                    Image(systemName: "sparkle")
                        .font(.title2)
                        .foregroundStyle(colors[index])
                        .tag("spark\(index)")
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawBalloons(_ context: inout GraphicsContext, size: CGSize, time: Double) {
        for index in 0..<6 {
            let period = 5.0 + Double(index) * 0.7
            let progress = reduceMotion ? 0.35 + Double(index) * 0.1 : ((time + Double(index) * 0.9).truncatingRemainder(dividingBy: period)) / period
            let x = size.width * (0.08 + 0.17 * Double(index)) + sin(progress * .pi * 3 + Double(index)) * 14
            let y = size.height * (1.1 - 1.3 * progress)
            if let balloon = context.resolveSymbol(id: "balloon\(index % colors.count)") {
                context.draw(balloon, at: CGPoint(x: x, y: y))
            }
        }
    }

    /// 폭죽은 두 줄기가 엇갈려 터진다. 터질 때마다 위치와 색이 바뀐다.
    private func drawFireworks(_ context: inout GraphicsContext, size: CGSize, time: Double) {
        for stream in 0..<2 {
            let shifted = time + Double(stream) * burstInterval / 2
            let burst = Int(shifted / burstInterval)
            let progress = shifted.truncatingRemainder(dividingBy: burstInterval) / burstInterval
            let seed = Double(burst * 2 + stream)
            let center = CGPoint(x: size.width * (0.2 + 0.6 * fract(sin(seed * 12.9898) * 43758.5453)),
                                 y: size.height * (0.12 + 0.35 * fract(sin(seed * 78.233) * 12345.6789)))
            let eased = 1 - pow(1 - progress, 3)
            for spark in 0..<sparksPerBurst {
                let angle = Double(spark) / Double(sparksPerBurst) * 2 * .pi + seed
                let distance = 90 * eased
                guard let image = context.resolveSymbol(id: "spark\((burst + spark) % colors.count)") else { continue }
                var layer = context
                layer.opacity = 1 - progress
                layer.draw(image, at: CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance + 30 * progress * progress))
            }
        }
    }

    private func fract(_ value: Double) -> Double {
        value - value.rounded(.down)
    }
}

#Preview {
    Celebration()
        .background(Color.app.background)
}

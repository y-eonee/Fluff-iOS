import AudioToolbox
import SwiftUI

/// 말랑이 체험 화면
struct SquishyView: View {
    let doll: DollState
    /// 누를 때마다 불린다. 멀티 룸에서 다른 사람에게 알릴 때 쓴다.
    var onTouch: () -> Void = {}

    var body: some View {
        VStack(spacing: Spacing.l) {
            Text("\(doll.filling.label.josa("이", "가")) 들어 있어요")
                .font(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
            Spacer()
            SquishyDoll(doll: doll, onTouch: onTouch)
            Spacer()
            Text("꾹 누르면 조물조물, 문지르면 쓰담쓰담")
                .font(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity)
        .background(Color.app.background)
        .navigationTitle("만지기")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 만질 수 있는 인형. 꾹 누르면 조물조물, 문지르면 쓰담쓰담. 속재료마다 눌림·튕김·햅틱·소리가 다르다.
/// 처음에는 화살표가 위에서 가리켜서 만져 보게 한다. 춤을 적용한 인형은 춤추면서 눌린다.
struct SquishyDoll: View {
    let doll: DollState
    var onTouch: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("hapticOn") private var hapticOn = true
    @AppStorage("soundOn") private var soundOn = true
    @State private var press: CGFloat = 0
    @State private var stroke: CGSize = .zero
    @State private var isTouching = false
    @State private var hasTouched = false
    @State private var lastStrokePoint: CGPoint?
    @State private var pressCount = 0
    @State private var strokeCount = 0
    @State private var releaseCount = 0

    var body: some View {
        VStack(spacing: Spacing.xs) {
            hint
            dollImage
                .scaleEffect(x: 1 + press * 0.15, y: 1 - press * 0.25, anchor: .bottom)
                .rotationEffect(.degrees(stroke.width * (reduceMotion ? 0.02 : 0.08)), anchor: .bottom)
                .padding(.horizontal, Spacing.l)
                .contentShape(Rectangle())
                .gesture(touch)
                .accessibilityLabel(doll.name)
                .accessibilityAddTraits(.allowsDirectInteraction)
        }
        .sensoryFeedback(trigger: pressCount) { _, _ in hapticOn ? .impact(flexibility: .soft, intensity: 0.6) : nil }
        .sensoryFeedback(trigger: strokeCount) { _, _ in hapticOn ? .impact(weight: .light, intensity: 0.5) : nil }
        .sensoryFeedback(trigger: releaseCount) { _, _ in hapticOn ? .impact(flexibility: .soft, intensity: 0.6) : nil }
    }

    /// 춤을 적용한 인형은 만지는 동안에도 계속 춤춘다.
    @ViewBuilder
    private var dollImage: some View {
        let image = UIImage(data: doll.imageData) ?? UIImage()
        if let dance = doll.dance {
            DancingDoll(image: image, move: dance)
        } else {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
    }

    private var hint: some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: "arrow.down")
                .font(.title.bold())
                .symbolEffect(.bounce, options: .repeating, isActive: !reduceMotion && !hasTouched)
            Text("만져 보세요")
                .font(.footnote.bold())
        }
        .foregroundStyle(Color.app.ink)
        .opacity(hasTouched ? 0 : 1)
        .accessibilityHidden(true)
    }

    private var touch: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isTouching {
                    isTouching = true
                    lastStrokePoint = value.location
                    pressCount += 1
                    onTouch()
                    if soundOn { AudioServicesPlaySystemSound(doll.filling.systemSoundID) }
                    withAnimation(.spring(duration: 0.12)) { press = 1 }
                    withAnimation(.spring) { hasTouched = true }
                }
                stroke = CGSize(width: max(-150, min(150, value.translation.width)), height: 0)
                if let last = lastStrokePoint, hypot(value.location.x - last.x, value.location.y - last.y) > 40 {
                    lastStrokePoint = value.location
                    strokeCount += 1
                    withAnimation(.spring(duration: 0.2)) { press = 0.4 }
                }
            }
            .onEnded { _ in
                isTouching = false
                releaseCount += 1
                if soundOn { AudioServicesPlaySystemSound(doll.filling.systemSoundID) }
                withAnimation(.spring(duration: 0.5, bounce: reduceMotion ? 0 : 0.3)) {
                    press = 0
                    stroke = .zero
                }
            }
    }
}

#Preview {
    NavigationStack {
        SquishyView(doll: Doll.sample.state)
    }
}

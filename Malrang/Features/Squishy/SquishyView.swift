import AudioToolbox
import SwiftUI

/// 말랑이 체험. 꾹 누르면 조물조물, 문지르면 쓰담쓰담. 속재료마다 눌림·튕김·햅틱·소리가 다르다.
struct SquishyView: View {
    let doll: DollState
    /// 누를 때마다 불린다. 멀티 룸에서 다른 사람에게 알릴 때 쓴다.
    var onTouch: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var press: CGFloat = 0
    @State private var stroke: CGSize = .zero
    @State private var isTouching = false
    @State private var lastStrokePoint: CGPoint?
    @State private var pressCount = 0
    @State private var strokeCount = 0
    @State private var releaseCount = 0

    var body: some View {
        VStack(spacing: Spacing.l) {
            Text("\(doll.filling.label.josa("이", "가")) 들어 있어요")
                .font(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
            Spacer()
            Image(uiImage: UIImage(data: doll.imageData) ?? UIImage())
                .resizable()
                .scaledToFit()
                .scaleEffect(x: 1 + press * doll.filling.pressDepth * 0.6, y: 1 - press * doll.filling.pressDepth, anchor: .bottom)
                .rotationEffect(.degrees(stroke.width * (reduceMotion ? 0.02 : 0.08)), anchor: .bottom)
                .padding(Spacing.l)
                .contentShape(Rectangle())
                .gesture(touch)
                .accessibilityLabel(doll.name)
                .accessibilityAddTraits(.allowsDirectInteraction)
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
        .sensoryFeedback(doll.filling.haptic, trigger: pressCount)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: strokeCount)
        .sensoryFeedback(doll.filling.haptic, trigger: releaseCount)
    }

    private var touch: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isTouching {
                    isTouching = true
                    lastStrokePoint = value.location
                    pressCount += 1
                    onTouch()
                    AudioServicesPlaySystemSound(doll.filling.systemSoundID)
                    withAnimation(.spring(duration: 0.12)) { press = 1 }
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
                AudioServicesPlaySystemSound(doll.filling.systemSoundID)
                withAnimation(.spring(duration: 0.5, bounce: reduceMotion ? 0 : doll.filling.bounce)) {
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

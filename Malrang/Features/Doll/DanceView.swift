import SwiftUI

/// 고른 모션을 미리 보여주는 인형.
/// 프리셋은 방과 같은 3D 부위 모션을, 누끼 사진은 전신 리듬을 표시한다.
struct DancingDoll: View {
    let image: UIImage
    let move: DanceMove
    var preset: PresetConfiguration? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var exerciseStart = Date()

    var body: some View {
        if let preset, MorningExerciseMotion.Clip(move: move) != nil {
            PresetDollView(configuration: preset, fitsModel: true, fitMargin: 1.42,
                           animating: false, dance: reduceMotion ? nil : move)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(move.label)
        } else if let clip = MorningExerciseMotion.Clip(move: move) {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
                let time = reduceMotion ? 0 : context.date.timeIntervalSince(exerciseStart)
                let pose = clip.pose(at: time)
                Image(uiImage: image)
                    .resizable().scaledToFit()
                    .rotationEffect(.radians(Double(pose.body.z)), anchor: .bottom)
                    .rotation3DEffect(.radians(Double(pose.body.x + pose.bend)), axis: (1, 0, 0), anchor: .bottom)
                    .rotation3DEffect(.radians(Double(pose.body.y)), axis: (0, 1, 0))
                    .offset(x: CGFloat(pose.travel) * 240, y: -CGFloat(pose.lift) * 240)
            }
            .onAppear { exerciseStart = Date() }
            .onChange(of: move) { _, _ in exerciseStart = Date() }
        } else {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .phaseAnimator([false, true]) { content, phase in
                    dance(content, phase: phase)
                } animation: { _ in
                    .easeInOut(duration: move == .spin ? 0.8 : 0.4)
                }
                .id(move)
        }
    }

    private func dance(_ content: PlaceholderContentView<some View>, phase: Bool) -> some View {
        let amount = reduceMotion ? 0.3 : 1.0
        return content
            .offset(y: phase ? offset * amount : 0)
            .rotationEffect(.degrees(move == .sway ? (phase ? 12 : -12) * amount : 0), anchor: .bottom)
            .rotation3DEffect(.degrees(move == .spin ? (phase ? 160 : -160) * amount : 0), axis: (0, 1, 0))
            .rotation3DEffect(.degrees(move == .nod && phase ? 20 * amount : 0), axis: (1, 0, 0), anchor: .bottom)
            .scaleEffect(x: move == .squish ? (phase ? 1.1 : 0.92) : 1, y: move == .squish ? (phase ? 0.9 : 1.08) : 1, anchor: .bottom)
    }

    private var offset: Double {
        switch move {
        case .bounce: -16
        case .jump: -50
        default: 0
        }
    }
}

/// 인형 화면 아래에서 올라오는 모션 고르기. 고르면 위의 인형이 바로 그 모션으로 움직인다.
/// 적용하면 방에서도 계속 춤춘다.
struct DancePanel: View {
    let doll: Doll
    @Binding var selected: DanceMove?
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: Spacing.m) {
            DanceChoiceContent(selection: selected, onSelect: { selected = $0 }, onClose: onClose)
            if doll.dance != nil {
                Button("춤 멈추기") {
                    doll.dance = nil
                    onClose()
                }
                .appFont(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
                .frame(minHeight: 44)
            }
            HStack(spacing: Spacing.s) {
                Button("취소",action:onClose).buttonStyle(.secondary)
                Button("완료") {
                    guard let selected else { return }
                    doll.dance = selected
                    onClose()
                }.buttonStyle(.primary).disabled(selected == nil)
            }
        }
        .environment(\.updatedFlowDesign, true)
        .padding(Spacing.m)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: Radius.large, topTrailingRadius: Radius.large, style: .continuous)
                .fill(Color.white)
                .ignoresSafeArea(edges: .bottom)
        }
        .shadow(color: Color.app.ink.opacity(0.08), radius: 12, y: -4)

    }
}

#Preview {
    VStack {
        DancingDoll(image: Doll.sample.image, move: .morningExercise)
        DancePanel(doll: .sample, selected: .constant(.morningExercise)) {}
    }
    .background { AppBackground() }
}

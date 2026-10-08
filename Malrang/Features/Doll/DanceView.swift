import SwiftUI

/// 고른 모션을 미리 보여주는 인형.
/// 지금은 2D 움직임으로 흉내 내고, 인형 3D 모델과 모션이 준비되면 교체한다.
struct DancingDoll: View {
    let image: UIImage
    let move: DanceMove
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
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
    @Binding var selected: DanceMove
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: Spacing.m) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 3), spacing: Spacing.xs) {
                ForEach(DanceMove.allCases, id: \.self) { move in
                    Button {
                        selected = move
                    } label: {
                        VStack(spacing: Spacing.xxs) {
                            Image(systemName: selected == move ? "checkmark" : move.symbol)
                                .font(.title3)
                            Text(move.label)
                                .font(.footnote)
                        }
                        .foregroundStyle(Color.app.ink)
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .background(selected == move ? Color.app.accent : Color.app.background,
                                    in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                            .stroke(selected == move ? Color.app.ink : Color.app.ink.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected == move ? .isSelected : [])
                }
            }
            if doll.dance != nil {
                Button("춤 멈추기") {
                    doll.dance = nil
                    onClose()
                }
                .font(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
                .frame(minHeight: 44)
            }
            CancelConfirmButtons(onCancel: onClose) {
                doll.dance = selected
                onClose()
            }
        }
        .padding(Spacing.m)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: Radius.large, topTrailingRadius: Radius.large, style: .continuous)
                .fill(Color.app.surface)
                .ignoresSafeArea(edges: .bottom)
        }
        .shadow(color: Color.app.ink.opacity(0.08), radius: 12, y: -4)
    }
}

#Preview {
    VStack {
        DancingDoll(image: Doll.sample.image, move: .squish)
        DancePanel(doll: .sample, selected: .constant(.squish)) {}
    }
    .background(Color.app.background)
}

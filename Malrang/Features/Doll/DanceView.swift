import SwiftUI

/// 모션을 골라 미리 보고, 적용하면 방에서도 계속 춤춘다.
/// 지금은 2D 움직임으로 흉내 내고, 인형 3D 모델과 모션이 준비되면 교체한다.
struct DanceView: View {
    let doll: Doll
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selected: DanceMove

    init(doll: Doll) {
        self.doll = doll
        _selected = State(initialValue: doll.dance ?? .bounce)
    }

    var body: some View {
        VStack(spacing: Spacing.l) {
            Image(uiImage: doll.image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 280)
                .phaseAnimator([false, true]) { content, phase in
                    dance(content, phase: phase)
                } animation: { _ in
                    .easeInOut(duration: selected == .spin ? 0.8 : 0.4)
                }
                .id(selected)
                .frame(maxHeight: .infinity)
                .accessibilityLabel("\(doll.name), \(selected.label) 춤")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s), count: 3), spacing: Spacing.s) {
                ForEach(DanceMove.allCases, id: \.self) { move in
                    Button {
                        selected = move
                    } label: {
                        VStack(spacing: Spacing.xxs) {
                            Image(systemName: move.symbol)
                                .font(.title3)
                            Text(move.label)
                                .font(.footnote)
                        }
                        .foregroundStyle(Color.app.ink)
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .background(selected == move ? Color.app.accent : Color.app.surface,
                                    in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                            .stroke(selected == move ? Color.app.ink : Color.app.ink.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected == move ? .isSelected : [])
                }
            }
            HStack(spacing: Spacing.s) {
                if doll.dance != nil {
                    Button("춤 멈추기") {
                        doll.dance = nil
                        dismiss()
                    }
                    .buttonStyle(.secondary)
                }
                Button("적용하기") {
                    doll.dance = selected
                    dismiss()
                }
                .buttonStyle(.primary)
            }
        }
        .padding(Spacing.m)
        .background(Color.app.background)
        .navigationTitle("춤추기")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dance(_ content: PlaceholderContentView<some View>, phase: Bool) -> some View {
        let amount = reduceMotion ? 0.3 : 1.0
        return content
            .offset(y: phase ? offset(for: selected) * amount : 0)
            .rotationEffect(.degrees(selected == .sway ? (phase ? 12 : -12) * amount : 0), anchor: .bottom)
            .rotation3DEffect(.degrees(selected == .spin ? (phase ? 160 : -160) * amount : 0), axis: (0, 1, 0))
            .rotation3DEffect(.degrees(selected == .nod && phase ? 20 * amount : 0), axis: (1, 0, 0), anchor: .bottom)
    }

    private func offset(for move: DanceMove) -> Double {
        switch move {
        case .bounce: -16
        case .jump: -50
        default: 0
        }
    }
}

#Preview {
    NavigationStack {
        DanceView(doll: .sample)
    }
}

import SwiftUI

/// 인형 모양(프리셋)과 속재료, 이름을 고른다.
struct DollCustomizeStep: View {
    @Bindable var draft: DollDraft
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                preview
                section("인형 모양") {
                    HStack(spacing: Spacing.xs) {
                        ForEach(DollShape.allCases, id: \.self) { shape in
                            Chip(title: shape.label, isSelected: draft.shape == shape) { draft.shape = shape }
                        }
                    }
                }
                section("속재료", note: "만졌을 때 느낌이 달라져요") {
                    HStack(spacing: Spacing.xs) {
                        ForEach(Filling.allCases, id: \.self) { filling in
                            Chip(title: filling.label, isSelected: draft.filling == filling, isCompact: true) { draft.filling = filling }
                        }
                    }
                }
                section("인형 이름") {
                    TextField("", text: $draft.name, prompt: Text("귀염둥이").foregroundStyle(Color.app.inkSecondary.opacity(0.5)))
                        .font(.body)
                        .padding(Spacing.s)
                        .frame(minHeight: 44)
                        .background(Color.app.surface, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).stroke(Color.app.ink.opacity(0.15)))
                }
            }
            .padding(Spacing.m)
        }
        .safeAreaInset(edge: .bottom) {
            Button("완성하기", action: onNext)
                .buttonStyle(.primary)
                .padding(Spacing.m)
        }
        .navigationTitle("인형 만들기")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var preview: some View {
        HStack {
            Button("이전 모양", systemImage: "chevron.left") { cycleShape(by: -1) }
            DollArtwork(shape: draft.shape, cutout: Image(uiImage: draft.finalCutout ?? UIImage()), filling: draft.filling)
                .frame(maxWidth: .infinity, maxHeight: 260)
                .animation(.spring, value: draft.shape)
            Button("다음 모양", systemImage: "chevron.right") { cycleShape(by: 1) }
        }
        .labelStyle(.iconOnly)
        .font(.title2)
        .foregroundStyle(Color.app.ink)
        .padding(Spacing.m)
        .cardStyle()
    }

    private func section(_ title: String, note: String? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if let note {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(Color.app.inkSecondary)
                }
            }
            content()
        }
        .foregroundStyle(Color.app.ink)
    }

    private func cycleShape(by step: Int) {
        let shapes = DollShape.allCases
        let index = shapes.firstIndex(of: draft.shape) ?? 0
        draft.shape = shapes[(index + step + shapes.count) % shapes.count]
    }
}

#Preview {
    let draft = DollDraft()
    draft.cutout = UIImage(systemName: "cat.fill")
    return NavigationStack {
        DollCustomizeStep(draft: draft) {}
    }
}

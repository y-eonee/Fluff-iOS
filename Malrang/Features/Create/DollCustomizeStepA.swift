import SwiftUI

/// 시안 A(피그마 1안) 솜뭉치 만들기: 인형 모양, 속재료, 이름을 고른다.
struct DollCustomizeStepA: View {
    @Bindable var draft: DollDraft
    let onNext: () -> Void
    @AppStorage("soundOn") private var soundOn = true
    @Environment(\.dismiss) private var dismiss
    private let maxLength = 10

    private let fillingAssets: [Filling: String] = [
        .fluffy: "a_fill_fluffy", .beads: "a_fill_beads", .jelly: "a_fill_jelly", .foam: "a_fill_foam",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                steps
                preview
                Text("인형 모양").pretendard(.bold, 17, tracking: -0.51)
                HStack(spacing: Spacing.xs) {
                    ForEach(DollShape.allCases, id: \.self) { shape in
                        optionCard(isSelected: draft.shape == shape) {
                            draft.shape = shape
                        } label: {
                            Text(shape.label)
                                .pretendard(.bold, 15, tracking: -0.45)
                                .frame(minHeight: 44)
                        }
                    }
                }
                Text("속재료").pretendard(.bold, 17, tracking: -0.51)
                HStack(spacing: Spacing.xs) {
                    ForEach(Filling.allCases, id: \.self) { filling in
                        optionCard(isSelected: draft.filling == filling) {
                            draft.filling = filling
                            if soundOn { filling.playSound() }
                        } label: {
                            VStack(spacing: Spacing.xxs) {
                                Image(fillingAssets[filling] ?? "")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 37, height: 37)
                                Text(filling.label)
                                    .pretendard(.bold, 13, tracking: -0.39)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(minHeight: 72)
                        }
                    }
                }
                Text("인형 이름").pretendard(.bold, 17, tracking: -0.51)
                nameField
            }
            .foregroundStyle(Color.a.brown)
            .padding(.horizontal, Spacing.l)
            .padding(.top, Spacing.xs)
        }
        .scrollIndicators(.hidden)
        .background(GridPaper())
        .safeAreaInset(edge: .bottom) {
            Button(action: onNext) {
                Text("완성하기")
                    .pretendard(.bold, 20, tracking: -0.6)
                    .foregroundStyle(Color.a.cream)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color.a.brown, in: Capsule())
                    .overlay(Capsule().stroke(Color.a.line, lineWidth: 1.2))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Spacing.l)
            .padding(.bottom, Spacing.xs)
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image("a_back").resizable().frame(width: 26, height: 26)
                }
                .accessibilityLabel("뒤로")
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .principal) {
                Text("making fluff")
                    .notCliche(28, relativeTo: .title)
                    .tracking(-1.12)
                    .foregroundStyle(Color.a.brown)
            }
        }
    }

    private var steps: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0..<4, id: \.self) { index in
                if index < 3 {
                    Capsule().fill(Color.a.brown)
                } else {
                    Capsule().stroke(Color.a.brown, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                }
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.a.yellow)
            Image("a_starburst")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: .infinity, alignment: .top)
            DollArtwork(shape: draft.shape, cutout: Image(uiImage: draft.finalCutout ?? UIImage()))
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.m)
                .padding(.bottom, 56)
                .animation(.spring, value: draft.shape)
            Label {
                Text("속재료를 눌러 촉감을 비교해보세요")
                    .pretendard(.medium, 13, tracking: -0.26)
            } icon: {
                Image("a_sparkle").resizable().frame(width: 14, height: 14)
            }
            .foregroundStyle(Color.a.cream)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xs)
            .background(Color.a.brown, in: Capsule())
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, Spacing.xs)
            RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.a.line, lineWidth: 1)
        }
        .padding(Spacing.xs)
        .frame(height: 306)
        .sketchBox(fill: Color.a.blue, radius: 22)
    }

    private var nameField: some View {
        HStack {
            TextField("", text: $draft.name, prompt: Text("귀염둥이").foregroundStyle(Color.a.soft.opacity(0.6)))
                .pretendard(.medium, 16, tracking: -0.32)
                .onChange(of: draft.name) {
                    if draft.name.count > maxLength { draft.name = String(draft.name.prefix(maxLength)) }
                }
            Text("\(draft.name.count)/\(maxLength)")
                .pretendard(.regular, 12, tracking: -0.24)
                .foregroundStyle(Color.a.soft)
        }
        .padding(.horizontal, Spacing.m)
        .frame(minHeight: 50)
        .background {
            Image("a_lines").resizable().scaledToFill()
        }
        .sketchBox(fill: .white, radius: 8, line: 1)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func optionCard(isSelected: Bool, action: @escaping () -> Void, @ViewBuilder label: () -> some View) -> some View {
        Button(action: action) {
            label()
                .frame(maxWidth: .infinity)
                .sketchBox(fill: isSelected ? Color.a.blue : Color.a.card, radius: 8, line: isSelected ? 1.4 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    let draft = DollDraft()
    draft.cutout = UIImage(systemName: "cat.fill")
    return NavigationStack {
        DollCustomizeStepA(draft: draft) {}
    }
}

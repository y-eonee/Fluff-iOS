import SwiftUI

struct DollCustomizeStepB: View {
    @Bindable var draft: DollDraft
    let onNext: () -> Void
    @State private var pinchStart: CGFloat = 1
    @GestureState private var isPinching = false
    @Environment(\.dismiss) private var dismiss
    @AppStorage("soundOn") private var soundOn = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack(spacing: Spacing.xs) {
                    ForEach(0..<4) { index in Capsule().fill(index < 3 ? Color.b.ink : Color.b.line).frame(height: 6) }
                }.padding(.horizontal, Spacing.xs).accessibilityLabel("4단계 중 3단계")
                preview
                    .simultaneousGesture(MagnifyGesture().updating($isPinching) { _, state, _ in state = true }.onChanged { value in
                        guard draft.showsPhoto else { return }
                        draft.faceScale = min(2, max(0.6, pinchStart * value.magnification))
                    }.onEnded { _ in pinchStart = draft.faceScale })
                if draft.shape != .pillow {
                    Toggle("사진 얼굴 표시", isOn: $draft.showsFace)
                        .pretendard(.semiBold, 15)
                        .tint(Color.b.orange)
                        .disabled(draft.finalCutout == nil)
                    if !draft.showsPhoto {
                        Text("사진 얼굴 없이 프리셋 그대로 완성해요")
                            .pretendard(.regular, 12).foregroundStyle(Color.b.soft)
                    }
                }
                if draft.showsPhoto {
                    FaceSizeControl(scale: $draft.faceScale)
                        .onChange(of: draft.faceScale) { if !isPinching { pinchStart = draft.faceScale } }
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("인형 모양").pretendard(.bold, 13)
                    HStack(spacing: Spacing.xxs) {
                        ForEach(DollShape.allCases, id: \.self) { shape in
                            Button { draft.shape = shape } label: {
                                Text(shape == .bear ? "곰" : shape == .star ? "별" : shape.label)
                                    .pretendard(draft.shape == shape ? .bold : .medium, 13)
                                    .foregroundStyle(draft.shape == shape ? .white : Color.b.soft)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background {
                                        if draft.shape == shape { RoundedRectangle(cornerRadius: 11).fill(BStyle.orange) }
                                    }
                            }.accessibilityAddTraits(draft.shape == shape ? .isSelected : [])
                                .disabled(shape == .pillow && draft.finalCutout == nil)
                        }
                    }
                    .padding(Spacing.xxs)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white))
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("속재료").pretendard(.bold, 13)
                    HStack(spacing: Spacing.xs) {
                        ForEach(Filling.allCases, id: \.self) { filling in
                            Button {
                                draft.filling = filling
                                if soundOn { filling.playSound() }
                            } label: {
                                VStack(spacing: Spacing.xxs) {
                                    fillingImage(filling).frame(height: 48)
                                    Text(filling.bLabel).pretendard(draft.filling == filling ? .bold : .medium, 12).lineLimit(1).minimumScaleFactor(0.7)
                                }
                                .foregroundStyle(draft.filling == filling ? .white : Color.b.soft)
                                .frame(maxWidth: .infinity, minHeight: 92)
                                .background {
                                    if draft.filling == filling {
                                        RoundedRectangle(cornerRadius: 14).fill(BStyle.orange)
                                            .overlay(Image("b_screen1_imgEllipse2088").resizable().scaledToFill().blendMode(.softLight))
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                }
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white))
                            }.accessibilityAddTraits(draft.filling == filling ? .isSelected : [])
                        }
                    }
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("인형 이름").pretendard(.bold, 13)
                    HStack {
                        TextField("귀염둥이", text: $draft.name).pretendard(.semiBold, 16)
                        Text("\(draft.name.count)/10").pretendard(.regular, 12).foregroundStyle(Color.b.soft)
                    }
                    .padding(.horizontal, Spacing.xs).frame(minHeight: 46)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white))
                    .onChange(of: draft.name) { if draft.name.count > 10 { draft.name = String(draft.name.prefix(10)) } }
                }
            }
            .padding(.horizontal, Spacing.m).padding(.top, Spacing.xs).padding(.bottom, Spacing.m)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(Color.b.ink)
        .background(BBackground())
        .safeAreaInset(edge: .bottom) {
            Button(action: onNext) {
                Text("완성하기").pretendard(.bold, 16).foregroundStyle(Color.b.brown)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(BButtonSurface())
            }.padding(.horizontal, Spacing.m).padding(.bottom, Spacing.xs)
        }
        .buttonStyle(BGlossButtonStyle())
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image("b_screen1_imgI").resizable().frame(width: 20, height: 20)
                        .frame(width: 44, height: 44).background(.white, in: Circle())
                        .overlay(Circle().stroke(Color.b.line))
                }.buttonStyle(BGlossButtonStyle(radius: 22)).accessibilityLabel("뒤로")
            }.sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .principal) {
                Text("making fluff").origin(BStyle.title, relativeTo: .title).foregroundStyle(Color.b.brown)
            }
            ToolbarItem(placement: .topBarTrailing) { Text("3/4").pretendard(.regular, 13).foregroundStyle(Color.b.soft) }
                .sharedBackgroundVisibility(.hidden)
        }
    }

    private var preview: some View {
        ZStack(alignment: .bottom) {
                DollArtwork(shape: draft.shape, cutout: Image(uiImage: draft.finalCutout ?? UIImage()), showsPhoto: draft.showsPhoto, faceScale: draft.faceScale)
                    .padding(.horizontal, 62).padding(.bottom, 48).padding(.top, Spacing.l)
            Text("속재료를 눌러 촉감을 비교해보세요").pretendard(.regular, 13).foregroundStyle(Color.b.soft).padding(.bottom, Spacing.l)
        }
        .frame(height: BStyle.previewHeight).frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.b.line))
        .overlay(alignment: .topTrailing) {
            Button { soundOn.toggle() } label: {
                Group {
                    if soundOn { Image("b_screen1_imgVector").resizable().scaledToFit().frame(width: 18, height: 18) }
                    else { Image(systemName: "speaker.slash") }
                }
                    .foregroundStyle(Color.b.brown).frame(width: 40, height: 40)
                    .background(Color.b.inactive.opacity(0.5), in: Circle())
            }.padding(Spacing.s).accessibilityLabel(soundOn ? "소리 끄기" : "소리 켜기")
        }
        .animation(.spring, value: draft.shape)
    }

    @ViewBuilder private func fillingImage(_ filling: Filling) -> some View {
        switch filling {
        case .fluffy:
            ZStack {
                Image("b_screen1_imgEllipse2089").resizable().scaledToFit().frame(width: 26, height: 26).offset(y: -8)
                Image("b_fill_fluffy_base").resizable().scaledToFit().frame(width: 49, height: 29).offset(y: 4)
            }
        case .beads: Image("b_screen1_img").resizable().scaledToFit().padding(Spacing.xxs)
        case .jelly: Image("b_screen1_imgVector27987").resizable().scaledToFit().rotationEffect(.degrees(34.79)).scaleEffect(1.5).padding(Spacing.xxs).clipped()
        case .foam: Image("b_screen1_imgEllipse2092").resizable().scaledToFit().rotationEffect(.degrees(180)).padding(Spacing.xxs)
        }
    }
}

extension Filling {
    var bLabel: String {
        switch self { case .fluffy: "폭신 솜"; case .beads: "몽글 비즈"; case .jelly: "쫀득 젤리"; case .foam: "말랑 폼" }
    }
}

#Preview {
    NavigationStack { DollCustomizeStepB(draft: DollDraft(), onNext: {}) }
}

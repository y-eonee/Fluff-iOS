import SwiftUI

struct DollCustomizeStepA: View {
    @Bindable var draft: DollDraft
    var onPrevious: (() -> Void)? = nil
    let onNext: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0
    @State private var selectedPart = DollPart.head
    @State private var editingFace = false
    @FocusState private var nameFocused: Bool
    private var canEditFace: Bool { draft.shape != .pillow && draft.usesPresetPhoto }
    private var nameIsEmpty: Bool { draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var configuration: PresetConfiguration {
        var value = draft.preset; value.shape = draft.shape
        value.isPhotoSuit = false
        value.face = draft.usesPresetPhoto ? draft.presetPhotoData : nil
        value.faceScale = Float(draft.faceScale)
        value.faceOffsetX = draft.faceOffsetX; value.faceOffsetY = draft.faceOffsetY
        return value
    }
    var body: some View {
        GeometryReader { geometry in
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Keep the name field clear of the footer with taller native keyboards.
                preview(height: page == 3 ? min(208, max(128, geometry.size.height - 278)) : (page == 2 ? 280 : (page == 1 ? 341.128 : 383.308)))
                Group {
                    if page == 0 {
                        if draft.shape == .pillow {
                            Text("이전 단계에서 편집한 사진 크기가 그대로 적용돼요").pretendard(.regular, 14)
                        } else {
                            VStack(alignment: .leading, spacing: 13) {
                                Text("모양 조절").pretendard(.bold, 17, tracking: -0.85).frame(height: 26)
                                if canEditFace {
                                    HStack(spacing: 10) {
                                        D1Choice(title: "인형 모양", selected: !editingFace, fillsWidth: true, height: 40, fontSize: 13) { editingFace = false }
                                        D1Choice(title: "얼굴 사진", selected: editingFace, fillsWidth: true, height: 40, fontSize: 13) { editingFace = true }
                                    }
                                }
                                PresetPhotoControls(draft: draft, editsPhoto: canEditFace && editingFace)
                                    .padding(.top, 2.5)
                            }.padding(.top, 6)
                        }
                    }
                    else if page == 1 { partEditor }
                    else if page == 2 { DollFillingStep(selection: $draft.filling) }
                    else { nameEditor }
                }.padding(.leading, page == 0 ? 11.08 : 6).padding(.trailing, page == 0 ? 10.92 : 6)
            }.padding(.horizontal, 16).padding(.top, page == 1 ? 4 : 8).padding(.bottom, 16)
        }.scrollIndicators(.hidden).foregroundStyle(Color.a.brown)
            .safeAreaInset(edge: .top, spacing: 0) { CreationProgress(step: page >= 2 || editingFace ? 3 : 2, partEditor: page == 1, skipsShape: draft.shape == .pillow) }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                Button("이전") {
                    if page > (draft.shape == .pillow ? 2 : 0) { page -= 1 }
                    else if let onPrevious { onPrevious() }
                    else { dismiss() }
                }.buttonStyle(CreationSecondaryButton())
                Button(page < 3 ? "다음" : "완성하기") {
                    if page < 3 {
                        withAnimation(.easeInOut(duration: 0.2)) { page += 1 } }
                    else {
                        guard !nameIsEmpty else { return }
                        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        draft.preset = configuration; onNext()
                    }
                }.buttonStyle(CreationPrimaryButton()).disabled(page == 3 && nameIsEmpty)
                }.padding(.horizontal, page == 1 ? 22 : 18).padding(.bottom, 16)
            }
            .onAppear {
                if draft.shape == .pillow { page = 2 }
                else if canEditFace { editingFace = true }
            }
            .onChange(of: page) { _, value in nameFocused = value == 3 }
            #if DEBUG
            .onAppear { if ProcessInfo.processInfo.arguments.contains("--design-preview=create-name") || ProcessInfo.processInfo.arguments.contains("--design-preview=create-name-empty") { page = 3 }
                if ProcessInfo.processInfo.arguments.contains("--design-preview=create-parts") { page = 1 }
                if ProcessInfo.processInfo.arguments.contains("--design-preview=create-filling") || ProcessInfo.processInfo.arguments.contains("--design-preview=create-filling-custom") { page = 2 }
                if ProcessInfo.processInfo.arguments.contains("--preview-face-tab") { editingFace = true } }
            #endif
            .navigationBarBackButtonHidden().navigationBarTitleDisplayMode(.inline)
            .flowPageTitle("인형 만들기")
        }.background {
            if page == 1 { FlowDesign.makingCanvas.ignoresSafeArea() }
            else { AppBackground() }
        }.environment(\.updatedFlowDesign, true)
    }
    private var previewGuide: String {
        switch page {
        case 1: "조절할 인형 부위를 선택해 주세요"
        case 2: "속재료를 눌러 소리를 비교해 보세요"
        case 3: "인형에게 이름을 지어주세요"
        default: draft.shape == .pillow ? "편집한 사진으로 만들어요" : "끌어서 얼굴 이동 · 두 손가락으로 확대"
        }
    }

    private func preview(height: CGFloat) -> some View {
        RepresentativeHero(showsGlow: page != 1, compactGlow: page == 3, flowGlow: "flow_adjust_glow") {
            Group {
                if draft.shape == .pillow { CustomPhotoPreview(draft: draft) }
                else {
                    PresetDollView(configuration: configuration, cameraDistance: 0.90, cameraTarget: 0.19, fitsModel: true, fitMargin: page == 3 ? 0.86 : 1.06,
                                   onPart: { selectedPart = $0 }, onSnapshot: { draft.snapshot = $0 })
                        .renderedOnlyWhileVisible(background: .clear)
                        .offset(y: page == 0 ? -8 : 0)
                }
            }.modifier(PhotoPlacementGesture(draft: draft, isPreset: draft.shape != .pillow,
                                               enabled: page == 0 && canEditFace))
                .padding(.horizontal, page == 3 ? 40 : 20).padding(.vertical, 12)
        }.frame(height: height)
            .padding(.leading, page == 0 ? 10.92 : (page == 1 ? 10.37 : 12.17))
            .padding(.trailing, page == 0 ? 12.16 : (page == 1 ? 12.71 : 11.83))
            .overlay(alignment: .bottom) {
                if page == 0 && canEditFace {
                    Text(previewGuide).pretendard(.regular, 14, tracking: -0.7).foregroundStyle(Color.rep4.c01)
                        .frame(width: 280, height: 34)
                        .background { RepresentativeGradientFill(definition: RepresentativeGradients.focusGoal).clipShape(RoundedRectangle(cornerRadius: 15)) }.padding(.bottom, 15.5)
                }
            }
    }

    private var partEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("인형 모양").pretendard(.regular, 14, tracking: -0.7)
                Spacer()
                Text("미리보기에서 눌러도 선택돼요").pretendard(.regular, 14, tracking: -0.7).foregroundStyle(Color.a.soft)
            }
            if draft.shape == .pillow { EmptyView() }
            else {
                HStack(spacing: 6) {
                    ForEach(DollPart.allCases.filter { $0 != .ears }) { part in
                        Button { selectedPart = part } label: {
                            VStack(spacing: 2) {
                                Image("flow_part_\(part.rawValue)").renderingMode(.original).resizable().foregroundStyle(Color.rep4.c21).scaledToFit().frame(width: 22, height: 24)
                                Text(part.label).pretendard(.regular, 12, tracking: -0.6).lineLimit(1).minimumScaleFactor(0.8)
                            }.frame(maxWidth: .infinity).frame(height: 56)
                                .modifier(RepresentativeSelectionSurface(selected: selectedPart == part, radius: 10))
                        }.buttonStyle(.plain).accessibilityAddTraits(selectedPart == part ? .isSelected : [])
                    }
                }
                VStack(spacing: 6.5) {
                    partSlider("높이", key: \.length, range: 0.6...1.4)
                    partSlider("너비", key: \.width, range: 0.6...1.4)
                }.padding(.top, 8)
            }
        }
    }
    private var nameEditor: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack { Text("이름 짓기").pretendard(.bold, 17, tracking: -0.85); Spacer(); Text("\(draft.name.count)/10").pretendard(.regular, 12) }
            TextField("인형 이름을 입력해 주세요", text: $draft.name)
                .pretendard(.regular, 14, tracking: -0.7)
                .autocorrectionDisabled()
                .onChange(of: draft.name) { draft.name = String(draft.name.prefix(10)) }
                .submitLabel(.done).focused($nameFocused)
                .padding(.horizontal, 12).frame(height: 44)
                .creationOutline(fill: Color.a.card, radius: 10)

        }
    }
    private func partSlider(_ label: String, key: WritableKeyPath<PresetConfiguration.Part, Float>, range: ClosedRange<Float>) -> some View {
        HStack {
            Text(label).pretendard(.medium, 12).frame(width: 30, alignment: .leading)
            CreationSlider(value: Binding(get: { draft.preset.part(selectedPart)[keyPath: key] }, set: { value in
                var part = draft.preset.part(selectedPart); part[keyPath: key] = value; draft.preset.parts[selectedPart.rawValue] = part
            }), range: range, label: "\(selectedPart.label) \(label)", neutralValue: 1, neutralPosition: 0.625).frame(height: 44)
            Text("\(Int((configuration.part(selectedPart)[keyPath: key] * 100).rounded()))").pretendard(.medium, 12).monospacedDigit().frame(width: 26).foregroundStyle(CreationStyle.value)
        }.padding(.leading, 4).padding(.trailing, 17).frame(height: 44)
    }

}

#Preview { NavigationStack { DollCustomizeStepA(draft: DollDraft()) {} } }

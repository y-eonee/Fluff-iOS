import SwiftUI

struct DollCustomizeStepA: View {
    @Bindable var draft: DollDraft
    var onPrevious: (() -> Void)? = nil
    let onNext: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("soundOn") private var soundOn = true
    @State private var page = 0
    @State private var showDetails = false
    @State private var selectedPart = DollPart.head
    @State private var editingFace = false
    @FocusState private var nameFocused: Bool
    private var canEditFace: Bool { draft.shape != .pillow && draft.usesPresetPhoto }
    private var nameIsEmpty: Bool { draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private let fillingAssets: [Filling: String] = [.fluffy: "a_fill_fluffy", .beads: "a_fill_beads", .jelly: "a_fill_jelly", .foam: "a_fill_foam"]
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
                preview(height: page == 2 ? min(208, max(128, geometry.size.height - 278)) : (page == 1 ? 341.128 : 383.308))
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
                                if canEditFace && editingFace {
                                    PresetPhotoControls(draft: draft).padding(.top, 2.5)
                                } else {
                                    PresetPhotoControls(draft: draft).padding(.top, 2.5)
                                }
                            }.padding(.top, 6)
                        }
                    }
                    else if page == 1 { partEditor }
                    else { nameEditor }
                }.padding(.leading, page == 0 ? 11.08 : 6).padding(.trailing, page == 0 ? 10.92 : 6)
            }.padding(.horizontal, 16).padding(.top, page == 1 ? 4 : 8).padding(.bottom, 16)
        }.scrollIndicators(.hidden).foregroundStyle(Color.a.brown)
            .safeAreaInset(edge: .top, spacing: 0) { CreationProgress(step: 3, partEditor: page == 1).offset(y: page == 1 ? 0 : 8.76) }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                if page != 1 { Button("이전 단계") {
                    if page > 0 { page -= 1 }
                    else if let onPrevious { onPrevious() }
                    else { dismiss() }
                }.buttonStyle(CreationSecondaryButton()) }
                Button(page == 0 ? "다음 단계" : "완성하기") {
                    if page < 2 {
                        withAnimation(.easeInOut(duration: 0.2)) { page += 1 } }
                    else {
                        guard !nameIsEmpty else { return }
                        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        draft.preset = configuration; onNext()
                    }
                }.buttonStyle(CreationPrimaryButton()).disabled(page == 2 && nameIsEmpty)
                }.padding(.horizontal, page == 1 ? 22 : 18).padding(.bottom, 16)
            }
            .onChange(of: page) { _, value in nameFocused = value == 2 }
            #if DEBUG
            .onAppear { if ProcessInfo.processInfo.arguments.contains("--design-preview=create-name") || ProcessInfo.processInfo.arguments.contains("--design-preview=create-name-empty") { page = 2 }
                if ProcessInfo.processInfo.arguments.contains("--design-preview=create-parts") { page = 1 }
                if ProcessInfo.processInfo.arguments.contains("--preview-face-tab") { editingFace = true } }
            #endif
            .navigationBarBackButtonHidden().navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { Text("making fluff").notCliche(25.397, relativeTo: .title).tracking(-1.778).foregroundStyle(Color.a.brown).offset(y: 2) }
            }
            .sheet(isPresented: $showDetails) {
                NavigationStack {
                    ScrollView { VStack(alignment: .leading, spacing: 16) { detailEditor; fillingEditor }.padding(24) }
                        .background(Color.a.paper).foregroundStyle(Color.a.brown)
                        .cozyPageTitle("인형 세부 조절").navigationBarTitleDisplayMode(.inline)
                        .toolbar { Button("완료") { showDetails = false } }
                }.presentationDetents([.medium, .large])
            }
        }.background { AppBackground() }
    }
    private var previewGuide: String {
        switch page {
        case 1: "속재료를 눌러 촉감을 비교해보세요"
        case 2: "인형에게 이름을 지어주세요"
        default: draft.shape == .pillow ? "편집한 사진으로 만들어요" : (canEditFace && editingFace ? "끌어서 얼굴 이동 · 두 손가락으로 크기 조절" : "조절할 인형 부위를 선택해주세요")
        }
    }

    private func preview(height: CGFloat) -> some View {
        RepresentativeHero(showsGlow: page != 1, compactGlow: page == 2) {
            Group {
                if draft.shape == .pillow { CustomPhotoPreview(draft: draft) }
                else {
                    PresetDollView(configuration: configuration, cameraDistance: 0.90, cameraTarget: 0.19, fitsModel: true, fitMargin: page == 2 ? 0.86 : 1.06,
                                   onPart: { selectedPart = $0 }, onSnapshot: { draft.snapshot = $0 })
                        .renderedOnlyWhileVisible(background: .clear)
                        .offset(y: page == 0 ? -8 : 0)
                }
            }.modifier(PhotoPlacementGesture(draft: draft, isPreset: draft.shape != .pillow,
                                               enabled: page == 0 && canEditFace && editingFace))
                .padding(.horizontal, page == 2 ? 40 : 20).padding(.vertical, 12)
        }.frame(height: height)
            .padding(.leading, page == 0 ? 10.92 : (page == 1 ? 10.37 : 12.17))
            .padding(.trailing, page == 0 ? 12.16 : (page == 1 ? 12.71 : 11.83))
            .contextMenu { Button("색상·귀·속재료 조절") { showDetails = true } }
            .accessibilityAction(named: "인형 세부 설정") { showDetails = true }
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
                                Image("ui_part_\(part.rawValue)").renderingMode(.original).resizable().foregroundStyle(Color.rep4.c21).scaledToFit().frame(width: 22, height: 24)
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
    private var fillingEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("속재료").pretendard(.bold, 17)
            HStack(spacing: 10) {
                ForEach(Filling.allCases, id: \.self) { filling in
                    Button { draft.filling = filling; if soundOn { filling.playSound() } } label: {
                        VStack(spacing: 6) {
                            Image(fillingAssets[filling]!).resizable().scaledToFit().frame(width: 37, height: 32)
                            Text(fillingLabel(filling)).pretendard(.bold, 13).lineLimit(1).minimumScaleFactor(0.8)
                        }.frame(maxWidth: .infinity).frame(height: 72)
                            .creationOutline(fill: draft.filling == filling ? CreationStyle.blue.opacity(0.65) : Color.a.card, radius: 8)
                    }.buttonStyle(.plain).accessibilityAddTraits(draft.filling == filling ? .isSelected : [])
                }
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
    @ViewBuilder private var detailEditor: some View {
        Picker("부위", selection: $selectedPart) { ForEach(DollPart.allCases) { Text($0.label).tag($0) } }
        partSlider("위치", key: \.offset, range: -1...1)
        partSlider("크기", key: \.size, range: 0.7...1.3)
        partSlider("높이", key: \.length, range: 0.6...1.4)
        partSlider("너비", key: \.width, range: 0.6...1.4)
        ColorPicker("색상", selection: Binding(get: { Color(uiColor: Palette.uiColor(configuration.part(selectedPart).color ?? "#FFF3D6")) }, set: { setColor(Palette.hex($0)) }), supportsOpacity: false)
        Button("전체 부위 초기화") { draft.preset.parts = [:]; draft.snapshot = nil }
    }
    private func partSlider(_ label: String, key: WritableKeyPath<PresetConfiguration.Part, Float>, range: ClosedRange<Float>) -> some View {
        HStack {
            Text(label).pretendard(.medium, 12).frame(width: 30, alignment: .leading)
            CreationSlider(value: Binding(get: { draft.preset.part(selectedPart)[keyPath: key] }, set: { value in
                var part = draft.preset.part(selectedPart); part[keyPath: key] = value; draft.preset.parts[selectedPart.rawValue] = part
            }), range: range, label: "\(selectedPart.label) \(label)", neutralValue: 1, neutralPosition: 0.625).frame(height: 30)
            Text("\(Int((configuration.part(selectedPart)[keyPath: key] * 100).rounded()))").pretendard(.medium, 12).monospacedDigit().frame(width: 26).foregroundStyle(CreationStyle.value)
        }.padding(.leading, 4).padding(.trailing, 17).frame(height: 34)
    }
    private func setColor(_ hex: String) { var part = draft.preset.part(selectedPart); part.color = hex; draft.preset.parts[selectedPart.rawValue] = part }
    private func fillingLabel(_ filling: Filling) -> String {
        switch filling { case .fluffy: "폭신 솜"; case .beads: "몽글 비즈"; case .jelly: "쫀득 젤리"; case .foam: "말랑 폼" }
    }
}

#Preview { NavigationStack { DollCustomizeStepA(draft: DollDraft()) {} } }

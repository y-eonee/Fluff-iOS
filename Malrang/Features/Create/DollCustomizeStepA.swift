import SwiftUI

struct DollCustomizeStepA: View {
    @Bindable var draft: DollDraft
    let onNext: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("soundOn") private var soundOn = true
    @State private var editingParts = false
    @State private var choosingShape = false
    @State private var selectedPart = DollPart.head
    private let fillingAssets: [Filling: String] = [.fluffy: "a_fill_fluffy", .beads: "a_fill_beads", .jelly: "a_fill_jelly", .foam: "a_fill_foam"]
    private var configuration: PresetConfiguration {
        var value = draft.preset; value.shape = draft.shape
        value.isPhotoSuit = false
        value.face = draft.usesPresetPhoto ? (draft.finalCutout?.pngData() ?? draft.photo?.pngData()) : nil
        value.faceScale = Float(draft.faceScale)
        value.faceOffsetX = draft.faceOffsetX; value.faceOffsetY = draft.faceOffsetY
        return value
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack(spacing: Spacing.xs) {
                    ForEach(0..<5) { i in
                        Capsule().fill(i < (editingParts ? 4 : 3) ? Color.a.brown : .clear)
                            .overlay(Capsule().stroke(Color.a.brown, style: StrokeStyle(lineWidth: 1, dash: i < (editingParts ? 4 : 3) ? [] : [3, 2])))
                    }
                }.frame(height: 8).accessibilityHidden(true)
                preview
                if editingParts { partEditor }
                else {
                    Text("인형 모양").font(.headline)
                    if choosingShape {
                        HStack(spacing: Spacing.xs) {
                            ForEach(DollShape.presets, id: \.self) { shape in
                                Button {
                                    draft.shape = shape; draft.snapshot = nil
                                    editingParts = true
                                } label: {
                                    VStack(spacing: Spacing.xxs) {
                                        CottonArtwork(shape: shape).frame(height: 44)
                                        Text(shape.label).font(.subheadline.bold())
                                    }.frame(maxWidth: .infinity).padding(Spacing.xs)
                                        .creationOutline(fill: draft.shape == shape ? CreationStyle.blue : Color.a.card, radius: 8)
                                }.buttonStyle(.plain)
                            }
                        }
                    } else {
                        HStack(spacing: Spacing.xs) {
                            Button("커스텀") {
                                if draft.shape == .pillow { draft.shape = .cat }
                                choosingShape = true
                            }.padding(Spacing.s).creationOutline(fill: draft.shape != .pillow ? CreationStyle.blue : Color.a.card, radius: 8)
                            Button("자유") { draft.shape = .pillow; draft.snapshot = nil }
                                .padding(Spacing.s).creationOutline(fill: draft.shape == .pillow ? CreationStyle.blue : Color.a.card, radius: 8)
                        }.buttonStyle(.plain).font(.subheadline.bold())
                        if draft.shape == .pillow { FaceSizeControl(scale: $draft.faceScale) }
                    }
                    Text("속재료").font(.headline)
                    HStack(spacing: Spacing.xs) {
                        ForEach(Filling.allCases, id: \.self) { filling in
                            Button { draft.filling = filling; if soundOn { filling.playSound() } } label: {
                                VStack(spacing: Spacing.xxs) {
                                    Image(fillingAssets[filling]!).resizable().scaledToFit().frame(width: 37, height: 37)
                                    Text(fillingLabel(filling)).font(.caption.bold()).lineLimit(1)
                                }.frame(maxWidth: .infinity, minHeight: 72)
                                    .creationOutline(fill: draft.filling == filling ? CreationStyle.blue : Color.a.card, radius: 8)
                            }.buttonStyle(.plain).accessibilityAddTraits(draft.filling == filling ? .isSelected : [])
                        }
                    }
                    Text("인형 이름").font(.headline)
                    HStack {
                        TextField("귀염둥이", text: $draft.name).onChange(of: draft.name) { draft.name = String(draft.name.prefix(10)) }
                        Text("\(draft.name.count)/10").font(.caption).foregroundStyle(Color.a.soft)
                    }.padding(Spacing.s).frame(minHeight: 50).creationOutline(fill: .white, radius: 8)
                }
            }.padding(.horizontal, Spacing.l).padding(.top, Spacing.xs)
        }.scrollIndicators(.hidden).background(Color.a.paper).foregroundStyle(Color.a.brown)
            .safeAreaInset(edge: .bottom) {
                Button(editingParts || draft.shape == .pillow ? "완성하기" : "다음 단계로") {
                    if editingParts || draft.shape == .pillow { draft.preset = configuration; onNext() }
                    else { choosingShape = true }
                }.buttonStyle(FocusPrimaryButton()).padding(.horizontal, Spacing.l).padding(.bottom, Spacing.xs)
            }
            .navigationBarBackButtonHidden().navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { if editingParts { editingParts = false } else if choosingShape { choosingShape = false } else { dismiss() } } label: { Image("a_back").resizable().frame(width: 26, height: 26) }.accessibilityLabel("뒤로")
                }.sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .principal) { Text("making fluff").notCliche(28, relativeTo: .title).foregroundStyle(Color.a.brown) }
            }
    }
    private var preview: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 14).fill(CreationStyle.yellow)
            Image("a_starburst").resizable().scaledToFit()
            if draft.shape == .pillow {
                DollArtwork(shape: .pillow, cutout: Image(uiImage: draft.finalCutout ?? UIImage()), faceScale: draft.faceScale).padding(Spacing.xl)
            } else {
                PresetDollView(configuration: configuration, onPart: { selectedPart = $0 }, onSnapshot: { draft.snapshot = $0 }).padding(.bottom, 40)
            }
            Text(editingParts ? "슬라이드를 조절해 자유롭게 커스텀해보세요" : "속재료를 눌러 촉감을 비교해보세요")
                .font(.caption).foregroundStyle(Color.a.cream).padding(Spacing.xs).padding(.horizontal, Spacing.xs)
                .background(Color.a.brown, in: Capsule()).padding(.bottom, Spacing.s)
            if editingParts {
                Button("초기화", systemImage: "arrow.counterclockwise") { draft.preset.parts = [:] }
                    .font(.caption.bold()).padding(Spacing.xs).background(Color.a.card, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(Spacing.xs)
            }
        }.padding(Spacing.xs).frame(height: 290).creationOutline(fill: CreationStyle.blue, radius: 22)
    }
    private var partEditor: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            if draft.photo != nil || draft.finalCutout != nil {
                Toggle("얼굴에 선택한 사진 넣기", isOn: $draft.usesPresetPhoto)
                    .font(.subheadline.bold()).tint(Color.a.brown)
                    .onChange(of: draft.usesPresetPhoto) { draft.snapshot = nil }
            }
            if configuration.face != nil {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("얼굴 사진 맞추기").font(.headline)
                    Text("사진은 얼굴 테두리 안에만 들어가요").font(.caption).foregroundStyle(Color.a.soft)
                    HStack { Text("확대").font(.caption); Slider(value: $draft.faceScale, in: 1...3).accessibilityLabel("얼굴 사진 확대") }
                    HStack { Text("좌우").font(.caption); Slider(value: $draft.faceOffsetX, in: -0.5...0.5).accessibilityLabel("얼굴 사진 좌우 위치") }
                    HStack { Text("위아래").font(.caption); Slider(value: $draft.faceOffsetY, in: -0.5...0.5).accessibilityLabel("얼굴 사진 위아래 위치") }
                    Button("사진 위치 초기화") { draft.faceScale = 1; draft.faceOffsetX = 0; draft.faceOffsetY = 0 }.font(.caption)
                }.padding(Spacing.m).creationOutline(fill: Color.a.card, radius: 12)
            }
            HStack { Text("부위 선택").font(.headline); Spacer(); Text("미리보기에서 눌러도 선택돼요").font(.caption).foregroundStyle(Color.a.soft) }
            ScrollView(.horizontal) {
                HStack(spacing: Spacing.xs) {
                    ForEach(DollPart.allCases) { part in
                        Button(part.label) { selectedPart = part }.font(.caption.bold()).padding(Spacing.s)
                            .creationOutline(fill: selectedPart == part ? CreationStyle.blue : Color.a.card, radius: 8)
                            .accessibilityAddTraits(selectedPart == part ? .isSelected : [])
                    }
                }
            }.scrollIndicators(.hidden)
            VStack(spacing: Spacing.s) {
                partSlider("굵기", key: \.width, range: 0.6...1.4)
                partSlider("크기", key: \.size, range: 0.7...1.3)
                partSlider("길이", key: \.length, range: 0.6...1.4)
                partSlider("위치", key: \.offset, range: -1...1)
                HStack {
                    Text("색상").font(.subheadline.bold())
                    ForEach(["#FFF3D6", "#F3B7C8", "#F6AA7E", "#FFE39B", "#A3C99A", "#A5A6E8", "#CBB4E7"], id: \.self) { hex in
                        Button { setColor(hex) } label: {
                            Circle().fill(Color(uiColor: Palette.uiColor(hex))).frame(width: 26, height: 26)
                                .overlay(Circle().stroke(Color.a.brown, lineWidth: configuration.part(selectedPart).color == hex ? 2 : 0))
                        }.accessibilityLabel("\(selectedPart.label) 색상 \(hex)")
                    }
                    ColorPicker("직접 선택", selection: Binding(get: { Color(uiColor: Palette.uiColor(configuration.part(selectedPart).color ?? "#FFF3D6")) }, set: { setColor(Palette.hex($0)) }), supportsOpacity: false).labelsHidden()
                }
            }.padding(Spacing.m).creationOutline(fill: Color.a.card, radius: 12)
        }
    }
    private func partSlider(_ label: String, key: WritableKeyPath<PresetConfiguration.Part, Float>, range: ClosedRange<Float>) -> some View {
        HStack {
            Text(label).font(.subheadline.bold()).frame(width: 40, alignment: .leading)
            Slider(value: Binding(get: { draft.preset.part(selectedPart)[keyPath: key] }, set: { value in
                var part = draft.preset.part(selectedPart); part[keyPath: key] = value; draft.preset.parts[selectedPart.rawValue] = part
            }), in: range).tint(Color.a.brown).accessibilityLabel("\(selectedPart.label) \(label)")
            Text("\(Int(configuration.part(selectedPart)[keyPath: key] * 100))").font(.caption).monospacedDigit().frame(width: 32)
        }
    }
    private func setColor(_ hex: String) { var part = draft.preset.part(selectedPart); part.color = hex; draft.preset.parts[selectedPart.rawValue] = part }
    private func fillingLabel(_ filling: Filling) -> String {
        switch filling { case .fluffy: "폭신 솜"; case .beads: "몽글 비즈"; case .jelly: "쫀득 젤리"; case .foam: "말랑 폼" }
    }
}

#Preview { NavigationStack { DollCustomizeStepA(draft: DollDraft()) {} } }

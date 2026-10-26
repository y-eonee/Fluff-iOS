import SwiftUI

struct DollCustomizeStepA: View {
    @Bindable var draft: DollDraft
    let onNext: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("soundOn") private var soundOn = true
    @State private var page = 0
    @State private var showDetails = false
    @State private var selectedPart = DollPart.head
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
                CreationProgress(step: 3)
                Text(["모양 조절", "속재료 선택", "이름 짓기"][page])
                    .pretendard(.bold, 17).accessibilityAddTraits(.isHeader)
                preview(height: min(306, max(190, geometry.size.height - 440)))
                Group {
                    if page == 0 {
                        if draft.shape == .pillow {
                            FaceSizeControl(scale: $draft.customScale)
                        } else {
                            partEditor
                        }
                    }
                    else if page == 1 { fillingEditor }
                    else { nameEditor }
                }.padding(.horizontal, 6)
            }.padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 16)
        }.scrollIndicators(.hidden).background(Color.a.paper).foregroundStyle(Color.a.brown)
            .safeAreaInset(edge: .bottom) {
                Button(page < 2 ? "다음 단계로" : "완성하기") {
                    if page < 2 {
                        withAnimation(.easeInOut(duration: 0.2)) { page += 1 } }
                    else { draft.preset = configuration; onNext() }
                }.buttonStyle(CreationPrimaryButton()).padding(.horizontal, 22).padding(.bottom, 8)
                    .background(Color.a.paper)
            }
            .navigationBarBackButtonHidden().navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { if page > 0 { page -= 1 } else { dismiss() } } label: {
                        Image("a_back").resizable().frame(width: 24, height: 24)
                    }.accessibilityLabel("뒤로")
                }.sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .principal) { Text("making fluff").notCliche(28, relativeTo: .title).foregroundStyle(Color.a.brown) }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(DollShape.presets, id: \.self) { shape in
                            Button(shape.label) { draft.shape = shape; draft.snapshot = nil }
                        }
                        Button("자유 · 사진 누끼") { draft.shape = .pillow; draft.snapshot = nil }
                        Button("색상·귀 세부 조절") { showDetails = true }
                    } label: { Image(systemName: "ellipsis").frame(width: 24, height: 24) }
                    .accessibilityLabel("인형 모양과 세부 설정")
                }.sharedBackgroundVisibility(.hidden)
            }
            .sheet(isPresented: $showDetails) {
                NavigationStack {
                    ScrollView { VStack(alignment: .leading, spacing: 16) { detailEditor }.padding(24) }
                        .background(Color.a.paper).foregroundStyle(Color.a.brown)
                        .navigationTitle("인형 세부 조절").navigationBarTitleDisplayMode(.inline)
                        .toolbar { Button("완료") { showDetails = false } }
                }.presentationDetents([.medium, .large])
            }
        }
    }
    private var previewGuide: String {
        switch page {
        case 1: "속재료를 눌러 촉감을 비교해보세요"
        case 2: "솜뭉치에게 이름을 지어주세요"
        default: draft.shape == .pillow ? "솜뭉치의 크기를 맞춰주세요" : "조절할 인형 부위를 선택해주세요"
        }
    }

    private func preview(height: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 14).fill(CreationStyle.yellow)
            Image(draft.shape == .pillow ? "ui_focus_starburst" : "ui_create_starburst").resizable().scaledToFit().frame(height: min(240, height - 20)).frame(maxHeight: .infinity, alignment: .top).accessibilityHidden(true)
            Group {
                if draft.shape == .pillow {
                    CustomPhotoPreview(draft: draft)
                } else {
                    PresetDollView(configuration: configuration, cameraDistance: 0.90, cameraTarget: 0.19,
                                   onPart: { selectedPart = $0 }, onSnapshot: { draft.snapshot = $0 })
                        .renderedOnlyWhileVisible(background: .clear)
                }
            }.padding(.bottom, 44)
            if draft.shape != .pillow {
            GeometryReader { geometry in
                let artworkHeight = min(240, height - 20)
                let artworkWidth = min(geometry.size.width, artworkHeight * 1.4)
                let inset = (geometry.size.width - artworkWidth) / 2
                shapeArrow(-1).position(x: inset + artworkWidth * 0.0714, y: artworkHeight * 0.60)
                shapeArrow(1).position(x: inset + artworkWidth * 0.9286, y: artworkHeight * 0.60)
            }
            }
            HStack(spacing: 6) {
                Image("ui_create_sparkle").resizable().frame(width: 14, height: 14).accessibilityHidden(true)
                Text(previewGuide).pretendard(.medium, 13, tracking: -0.26)
            }.foregroundStyle(Color.a.cream).padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color.a.brown, in: Capsule()).padding(.bottom, 10)
        }.padding(10).frame(height: height).background(CreationStyle.blue, in: RoundedRectangle(cornerRadius: 22))
    }
    private func shapeArrow(_ direction: Int) -> some View {
        Button {
            let shapes = DollShape.presets
            let index = shapes.firstIndex(of: draft.shape) ?? 0
            draft.shape = shapes[(index + direction + shapes.count) % shapes.count]; draft.snapshot = nil
        } label: {
            Color.clear.frame(width: 44, height: 44).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(direction < 0 ? "이전 인형 모양" : "다음 인형 모양")
    }
    private var partEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("인형 모양").pretendard(.bold, 17, tracking: -0.51)
                Spacer()
                Text("미리보기에서 눌러도 선택돼요").pretendard(.medium, 12).foregroundStyle(Color.a.soft)
            }
            if draft.shape == .pillow { FaceSizeControl(scale: $draft.customScale) }
            else {
                HStack(spacing: 6) {
                    ForEach(DollPart.allCases.filter { $0 != .ears }) { part in
                        Button { selectedPart = part } label: {
                            VStack(spacing: 2) {
                                Image("ui_part_\(part.rawValue)").resizable().scaledToFit().frame(width: 22, height: 24)
                                Text(part.label).pretendard(.bold, 12).lineLimit(1).minimumScaleFactor(0.8)
                            }.frame(maxWidth: .infinity).frame(height: 54)
                                .creationOutline(fill: selectedPart == part ? CreationStyle.blue.opacity(0.65) : Color.a.card, radius: 10)
                        }.buttonStyle(.plain).accessibilityAddTraits(selectedPart == part ? .isSelected : [])
                    }
                }
                VStack(spacing: 10) {
                    partSlider("높이", key: \.length, range: 0.6...1.4)
                    partSlider("너비", key: \.width, range: 0.6...1.4)
                    partSlider("위치", key: \.offset, range: -1...1)
                }
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
        VStack(alignment: .leading, spacing: 12) {
            Text("인형 이름").pretendard(.bold, 17)
            HStack {
                TextField("인형 이름", text: $draft.name, prompt: Text("솜뭉치").foregroundStyle(Color.a.soft.opacity(0.65))).onChange(of: draft.name) { draft.name = String(draft.name.prefix(10)) }
                Text("\(draft.name.count)/10").pretendard(.regular, 13).foregroundStyle(Color.a.soft)
            }.padding(.horizontal, 16).frame(height: 50).creationOutline(fill: Color.a.card, radius: 8)
        }
    }
    @ViewBuilder private var detailEditor: some View {
        Picker("부위", selection: $selectedPart) { ForEach(DollPart.allCases) { Text($0.label).tag($0) } }
        partSlider("크기", key: \.size, range: 0.7...1.3)
        partSlider("높이", key: \.length, range: 0.6...1.4)
        partSlider("너비", key: \.width, range: 0.6...1.4)
        ColorPicker("색상", selection: Binding(get: { Color(uiColor: Palette.uiColor(configuration.part(selectedPart).color ?? "#FFF3D6")) }, set: { setColor(Palette.hex($0)) }), supportsOpacity: false)
        Button("전체 부위 초기화") { draft.preset.parts = [:]; draft.snapshot = nil }
    }
    private func partSlider(_ label: String, key: WritableKeyPath<PresetConfiguration.Part, Float>, range: ClosedRange<Float>) -> some View {
        HStack {
            Text(label).pretendard(.bold, 14).frame(width: 30, alignment: .leading)
            CreationSlider(value: Binding(get: { draft.preset.part(selectedPart)[keyPath: key] }, set: { value in
                var part = draft.preset.part(selectedPart); part[keyPath: key] = value; draft.preset.parts[selectedPart.rawValue] = part
            }), range: range, label: "\(selectedPart.label) \(label)").frame(height: 30)
            Text("\(Int(((configuration.part(selectedPart)[keyPath: key] - range.lowerBound) / (range.upperBound - range.lowerBound) * 100).rounded()))").font(.caption).monospacedDigit().frame(width: 26).foregroundStyle(CreationStyle.value)
        }.padding(.horizontal, 16).frame(height: 42).creationOutline(fill: Color.a.card, radius: 7)
    }
    private func setColor(_ hex: String) { var part = draft.preset.part(selectedPart); part.color = hex; draft.preset.parts[selectedPart.rawValue] = part }
    private func fillingLabel(_ filling: Filling) -> String {
        switch filling { case .fluffy: "폭신 솜"; case .beads: "몽글 비즈"; case .jelly: "쫀득 젤리"; case .foam: "말랑 폼" }
    }
}

#Preview { NavigationStack { DollCustomizeStepA(draft: DollDraft()) {} } }

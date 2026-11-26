import SwiftUI

struct CreateMethodStep: View {
    @Bindable var draft: DollDraft
    var onPrevious: (() -> Void)? = nil
    let onPreset: () -> Void
    let onCutout: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var usesPreset = true
    private var configuration: PresetConfiguration {
        var value = draft.preset
        value.shape = draft.shape == .pillow ? .bear : draft.shape
        value.face = draft.presetPhotoData
        value.faceScale = Float(draft.faceScale)
        value.faceOffsetX = draft.faceOffsetX
        value.faceOffsetY = draft.faceOffsetY
        return value
    }
    var body: some View {
        SplitStack { wide in
            if wide { hero.padding(16) }
        } secondary: { wide in
        VStack(spacing: 0) {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !wide {
                        hero.frame(height: min(383.308, max(160, geometry.size.height - 175)))
                            .padding(.horizontal, 9).padding(.bottom, 16.69)
                    }
                    HStack(spacing: 0) {
                        methodMode("프리셋", selected: usesPreset) { usesPreset = true }
                        methodMode("커스텀", selected: !usesPreset) { usesPreset = false }
                    }.padding(.horizontal, 4.5265).padding(.vertical, 3.737)
                        .background(Color.rep4.c01, in: Capsule()).fixedSize()
                        .padding(.leading, 2.88).padding(.bottom, 16.35)
                    Text(usesPreset ? "함께할 인형 모양을 골라주세요" : "투명화한 이미지를 그대로 사용해요")
                        .pretendard(.regular, 14, tracking: -0.7).frame(height: 20.3).padding(.leading, 6)
                    if usesPreset {
                        HStack(spacing: 6) {
                            ForEach([DollShape.bear, .cat, .rabbit], id: \.self) { shape in
                                mode(shape.label, icon: shape == .bear ? "shape_bear" : shape == .cat ? "shape_cat" : "shape_rabbit", selected: configuration.shape == shape) {
                                    draft.shape = shape; draft.snapshot = nil
                                }
                            }
                        }.padding(.top, 1.48).padding(.leading, 6)
                    }
                }.padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 20)
            }.scrollIndicators(.hidden).scrollEdgeEffectHidden(true, for: .top)
        }
                HStack(spacing: 12) {
                    Button("다시 선택") { if let onPrevious { onPrevious() } else { dismiss() } }.buttonStyle(CreationSecondaryButton())
                    Button("다음") { if usesPreset { onPreset() } else { onCutout() } }.buttonStyle(CreationPrimaryButton())
                }.padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 16)
        }
        }.background(FlowDesign.canvas.ignoresSafeArea()).foregroundStyle(Color.rep4.c08)
            .safeAreaInset(edge: .top, spacing: 0) { CreationProgress(step: usesPreset ? 2 : 3, skipsShape: !usesPreset) }
            .onAppear { usesPreset = draft.shape != .pillow }
            .flowPageTitle("인형 만들기").navigationBarBackButtonHidden()
    }
    private var hero: some View {
        RepresentativeHero(showsGlow: true) {
            Group {
                if usesPreset {
                    PresetDollView(configuration: configuration, cameraDistance: 0.90, cameraTarget: 0.19, fitsModel: true, fitMargin: 1.0)
                        .renderedOnlyWhileVisible(background: .clear)
                        .offset(y: -6)
                } else { CustomPhotoPreview(draft: draft) }
            }.padding(.horizontal, 24).padding(.vertical, 20)
        }
    }
    private func mode(_ title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if selected { Image(systemName: "checkmark").font(.system(size: 10)) }
                Image(icon).resizable().scaledToFit().frame(width: 16, height: 16).accessibilityHidden(true)
                Text(title).pretendard(.regular, 12.743, tracking: -0.637)
            }
                .padding(.horizontal, 12).frame(height: 32.914)
                .modifier(RepresentativeSelectionSurface(selected: selected, radius: 18.286))
                .frame(height: 44)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
    private func methodMode(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text((selected ? "✓ " : "") + title).pretendard(.regular, 12.167, tracking: -0.6084)
                .frame(width: 62, height: 31.276)
                .modifier(RepresentativeSelectionSurface(selected: selected, radius: 24.444))
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
}
#Preview { NavigationStack { CreateMethodStep(draft: DollDraft(), onPreset: {}, onCutout: {}) } }

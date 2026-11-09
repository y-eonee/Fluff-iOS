import SwiftUI

struct CreateMethodStep: View {
    @Bindable var draft: DollDraft
    var onPrevious: (() -> Void)? = nil
    let onPreset: () -> Void
    let onCutout: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var usesPreset = false

    private var configuration: PresetConfiguration {
        var value = draft.preset
        value.shape = draft.shape == .pillow ? .cat : draft.shape
        value.face = draft.presetPhotoData
        value.faceScale = Float(draft.faceScale)
        value.faceOffsetX = draft.faceOffsetX
        value.faceOffsetY = draft.faceOffsetY
        return value
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 14).fill(CreationStyle.yellow)
                    Image("ui_method_starburst").resizable().aspectRatio(336.0 / 240, contentMode: .fit)
                        .frame(maxHeight: .infinity, alignment: .top).accessibilityHidden(true)
                    Group {
                        if usesPreset {
                            PresetDollView(configuration: configuration, cameraDistance: 0.90, cameraTarget: 0.19, fitsModel: true)
                                .renderedOnlyWhileVisible(background: .clear)
                        } else {
                            CustomPhotoPreview(draft: draft)
                        }
                    }
                        .padding(.bottom, 44)
                    HStack(spacing: 6) {

                        Text("함께할 인형 모양을 골라주세요")
                            .pretendard(.medium, 13)
                    }.foregroundStyle(Color.a.creamText).padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.a.brown, in: Capsule()).padding(.bottom, 10)
                }.padding(10).frame(height: 328)
                    .background(CreationStyle.blue, in: RoundedRectangle(cornerRadius: 22))
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("인형 모양").pretendard(.bold, 17)
                    HStack(spacing: Spacing.xs) {
                        choice("프리셋", selected: usesPreset) { usesPreset = true }
                        choice("커스텀", selected: !usesPreset) { usesPreset = false }
                    }
                    Text(usesPreset ? "함께할 인형 모양을 골라주세요" : "투명화한 이미지를 그대로 사용해요")
                        .appFont(.footnote).foregroundStyle(Color.a.soft)
                    if usesPreset {
                        HStack(spacing: Spacing.s) {
                            ForEach(DollShape.presets, id: \.self) { shape in
                                Button {
                                    draft.shape = shape
                                    draft.snapshot = nil
                                } label: {
                                    VStack(spacing: Spacing.xxs) {
                                        CottonArtwork(shape: shape).frame(height: 52)
                                        Text(shape.label).pretendard(.bold, 13)
                                    }.frame(maxWidth: .infinity).padding(.vertical, Spacing.xs)
                                        .creationOutline(fill: configuration.shape == shape ? Color.mib.bg.mintSoft : Color.a.card, radius: 12)
                                        .overlay(alignment: .topTrailing) {
                                            if configuration.shape == shape {
                                                Image(systemName: "checkmark.circle.fill").padding(Spacing.xs)
                                            }
                                        }
                                }.buttonStyle(.plain)
                                    .accessibilityLabel("\(shape.label) 프리셋")
                                    .accessibilityAddTraits(configuration.shape == shape ? .isSelected : [])
                            }
                        }
                    }
                }.padding(.horizontal, 6)
            }.padding(.horizontal, Spacing.m).padding(.vertical, Spacing.s)
        }.background(Color.a.paper).foregroundStyle(Color.a.brown)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    Button("이전 단계") { if let onPrevious { onPrevious() } else { dismiss() } }.buttonStyle(CreationSecondaryButton())
                    Button("다음 단계") { if usesPreset { onPreset() } else { onCutout() } }.buttonStyle(CreationPrimaryButton())
                }.padding(.horizontal, 22).padding(.bottom, Spacing.xs).background(Color.a.paper)
            }
            .onAppear { usesPreset = draft.shape != .pillow }
            .navigationBarBackButtonHidden().navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("making fluff").notCliche(28, relativeTo: .title).foregroundStyle(Color.a.brown)
                }
            }
    }

    private func choice(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).pretendard(.medium, 13).frame(width: 102, height: 40)
                .background(selected ? Color.mib.bg.mintSoft : Color.mib.bg.surface, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? Color.mib.line.selected : Color.mib.line.default, lineWidth: selected ? 1.5 : 1))
                .frame(minHeight: 44)
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview {
    NavigationStack {
        CreateMethodStep(draft: DollDraft(), onPreset: {}, onCutout: {})
            .safeAreaInset(edge: .top) { CreationProgress(step: 2) }
    }
}

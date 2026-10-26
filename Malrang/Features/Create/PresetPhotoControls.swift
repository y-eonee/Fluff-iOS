import SwiftUI

struct PresetPhotoControls: View {
    @Bindable var draft: DollDraft

    var body: some View {
        HStack(spacing: Spacing.s) {
            Text("얼굴 테두리").pretendard(.bold, 14).frame(width: 74, alignment: .leading)
            CreationSlider(value: Binding(get: { draft.preset.openingScale }, set: {
                draft.preset.faceOpeningScale = ($0 * 20).rounded() / 20
                draft.snapshot = nil
            }), range: 0.8...1.1, label: "얼굴 테두리 크기").frame(height: 30)
            Text("\(Int((draft.preset.openingScale * 100).rounded()))%")
                .appFont(.caption).monospacedDigit().frame(width: 42)
        }.padding(.horizontal, Spacing.s).frame(height: 44)
            .creationOutline(fill: Color.a.card, radius: 8)
    }
}

#Preview { PresetPhotoControls(draft: DollDraft()).padding() }

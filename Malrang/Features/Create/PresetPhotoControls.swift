import SwiftUI

struct PresetPhotoControls: View {
    @Bindable var draft: DollDraft

    var body: some View {
        HStack(spacing: 0) {
            Text("얼굴 테두리").pretendard(.medium, 12).frame(width: 67.09, alignment: .leading)
            CreationSlider(value: Binding(get: { draft.preset.openingScale }, set: {
                draft.preset.faceOpeningScale = ($0 * 20).rounded() / 20
                draft.snapshot = nil
            }), range: 0.8...1.1, label: "얼굴 테두리 크기", neutralValue: 1, neutralPosition: 0.58).frame(height: 30)
            Text("\(Int((draft.preset.openingScale * 100).rounded()))%")
                .pretendard(.medium, 12).monospacedDigit().frame(width: 44, alignment: .trailing)
        }.padding(.trailing, 10).frame(height: 34)
    }
}

#Preview { PresetPhotoControls(draft: DollDraft()).padding() }

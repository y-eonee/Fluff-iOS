import SwiftUI

struct PresetPhotoControls: View {
    @Bindable var draft: DollDraft
    var editsPhoto = false

    var body: some View {
        if editsPhoto {
            VStack(spacing: 8) {
                row("사진 확대", value: Binding(get: { Float(draft.faceScale) }, set: {
                    draft.faceScale = CGFloat($0); draft.snapshot = nil
                }), range: 1...3, label: "얼굴 사진 확대", display: "\(Int((draft.faceScale * 100).rounded()))%")
                row("좌우 위치", value: Binding(get: { draft.faceOffsetX }, set: {
                    draft.faceOffsetX = $0; draft.snapshot = nil
                }), range: -0.5...0.5, label: "얼굴 사진 좌우 위치", display: "\(Int((draft.faceOffsetX * 100).rounded()))")
                row("상하 위치", value: Binding(get: { draft.faceOffsetY }, set: {
                    draft.faceOffsetY = $0; draft.snapshot = nil
                }), range: -0.5...0.5, label: "얼굴 사진 상하 위치", display: "\(Int((draft.faceOffsetY * 100).rounded()))")
                Button("사진 위치 초기화") {
                    draft.faceScale = 1; draft.faceOffsetX = 0; draft.faceOffsetY = 0; draft.snapshot = nil
                }.pretendard(.medium, 12).foregroundStyle(Color.rep4.c29)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .trailing)
            }
        } else {
            HStack(spacing: 0) {
                Text("얼굴 테두리").pretendard(.medium, 12).frame(width: 67.09, alignment: .leading)
                CreationSlider(value: Binding(get: { draft.preset.openingScale }, set: {
                    draft.preset.faceOpeningScale = ($0 * 20).rounded() / 20
                    draft.snapshot = nil
                }), range: 0.8...1.1, label: "얼굴 테두리 크기", neutralValue: 1, neutralPosition: 0.58).frame(height: 44)
                Text("\(Int((draft.preset.openingScale * 100).rounded()))%")
                    .pretendard(.medium, 12).monospacedDigit().frame(width: 44, alignment: .trailing)
            }.padding(.trailing, 10).frame(height: 44)
        }
    }

    private func row(_ title: String, value: Binding<Float>, range: ClosedRange<Float>, label: String, display: String) -> some View {
        HStack(spacing: 0) {
            Text(title).pretendard(.medium, 12).frame(width: 67.09, alignment: .leading)
            CreationSlider(value: value, range: range, label: label).frame(height: 44)
            Text(display).pretendard(.medium, 12).monospacedDigit().frame(width: 44, alignment: .trailing)
        }.padding(.trailing, 10).frame(height: 44)
    }
}

#Preview { PresetPhotoControls(draft: DollDraft(), editsPhoto: true).padding() }

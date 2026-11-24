import SwiftUI

/// Reuses the original filling sounds with the shared outline icon style in a dedicated creation step.
struct DollFillingStep: View {
    @Binding var selection: Filling
    @AppStorage("soundOn") private var soundOn = true
    private let assets: [Filling: String] = [
        .fluffy: "filling_line_sherbet", .beads: "filling_line_wax",
        .jelly: "filling_line_slime", .foam: "filling_line_crunch"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("속재료 선택하기").pretendard(.bold, 17, tracking: -0.85)
            Text(soundOn ? "눌러서 만질 때 나는 소리를 들어보세요." : "소리가 꺼져 있어요. 속재료는 선택할 수 있어요.")
                .pretendard(.regular, 14, tracking: -0.7)
                .foregroundStyle(Color.rep4.c29)
            HStack(spacing: Spacing.s) {
                ForEach(Filling.allCases, id: \.self) { filling in
                    Button {
                        selection = filling
                        Filling.stopSounds()
                        if soundOn { filling.playSound() }
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            Image(assets[filling]!).resizable().scaledToFit()
                                .frame(width: 38, height: 34)
                            Text(filling.label).pretendard(.medium, 13)
                                .lineLimit(1).minimumScaleFactor(0.8)
                        }.frame(maxWidth: .infinity).frame(height: 88)
                            .modifier(RepresentativeSelectionSurface(selected: selection == filling, radius: 12))
                            .overlay(alignment: .topTrailing) {
                                if selection == filling {
                                    Image(systemName: "checkmark").font(.caption.weight(.semibold))
                                        .padding(Spacing.xs).accessibilityHidden(true)
                                }
                            }
                    }.buttonStyle(.plain)
                        .accessibilityLabel(filling.label)
                        .accessibilityValue(selection == filling ? "선택됨" : "선택 안 됨")
                        .accessibilityHint("선택하고 소리를 미리 들어요")
                        .accessibilityAddTraits(selection == filling ? .isSelected : [])
                }
            }
        }.foregroundStyle(Color.rep4.c08)
            .onDisappear { Filling.stopSounds() }
    }
}

#Preview {
    @Previewable @State var filling = Filling.fluffy
    DollFillingStep(selection: $filling).padding().environment(\.updatedFlowDesign, true)
}

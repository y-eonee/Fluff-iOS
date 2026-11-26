import SwiftUI

/// The same compact picker is used by the home sheet and AR's dance panel.
struct DanceChoiceContent: View {
    let selection: DanceMove?
    let onSelect: (DanceMove) -> Void
    let onClose: () -> Void
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("춤추기").pretendard(.semiBold,16)
                Spacer()
                Button(action:onClose) { Image(systemName:"xmark").frame(width:44,height:32) }
                    .accessibilityLabel("춤추기 닫기")
            }.padding(.leading,4).frame(height:32)
            HStack(spacing:6) {
                ForEach(DanceMove.selectable,id: \.self) { move in
                    Button { onSelect(move) } label: {
                        VStack(spacing:3) {
                            DanceMoveIcon(move:move).frame(width:40,height:36).accessibilityHidden(true)
                            Text(move.label).pretendard(.medium,14).lineLimit(1).minimumScaleFactor(0.8)
                        }.frame(maxWidth:.infinity,minHeight:76)
                            .background {
                                RoundedRectangle(cornerRadius:14)
                                    .fill(selection == move ? AnyShapeStyle(FlowDesign.selected) : AnyShapeStyle(Color.white))
                            }
                    }.buttonStyle(DanceCharacterButtonStyle()).accessibilityLabel(move.label)
                        .accessibilityAddTraits(selection == move ? .isSelected : [])
                }
            }
        }.foregroundStyle(Color.rep4.c08)
    }
}

/// Original Figma 1927:38 assets: the four resting variants and the pressed variant.
private struct DanceMoveIcon: View {
    let move: DanceMove
    @Environment(\.danceCharacterPressed) private var pressed
    private var asset: String {
        if pressed { return "dance_character_pressed" }
        switch move {
        case .morningExercise: return "dance_character_mongle"
        case .danceDance: return "dance_character_round"
        case .tapDance: return "dance_character_soft"
        default: return "dance_character_fluffy"
        }
    }
    var body: some View {
        Image(asset).renderingMode(.original).resizable().scaledToFit()
    }
}

private struct DanceCharacterPressedKey: EnvironmentKey {
    static let defaultValue = false
}
private extension EnvironmentValues {
    var danceCharacterPressed: Bool {
        get { self[DanceCharacterPressedKey.self] }
        set { self[DanceCharacterPressedKey.self] = newValue }
    }
}
private struct DanceCharacterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.environment(\.danceCharacterPressed, configuration.isPressed)
    }
}

import SwiftUI

/// Home menus share the compact Figma surface (1949:13760).
struct HomePopup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).pretendard(.medium, 14).foregroundStyle(Color.rep4.c16)
                .frame(height: 20).lineLimit(1)
            content
        }.buttonStyle(HomePopupPressStyle()).padding(13).frame(width: 232)
            .background(.white, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(HomePopupStyle.border, lineWidth: 1))
            .accessibilityElement(children: .contain)
    }
}

enum HomePopupStyle {
    static let border = Color(uiColor: Palette.uiColor("#E9E9E9"))
    static let selectedBorder = Color(uiColor: Palette.uiColor("#C6DAFF"))
    private static let transform: [[Double]] = [[0.03376460447907448, 0.6303068399429321, 0.5005324482917786], [-0.6303068399429321, 0.004156933166086674, 0.9231472611427307]]
    static let selected = gradient(ending: Color(.sRGB, red: 0.6941176653, green: 0.8470588326, blue: 0.9960784316))
    static let danceSelection = gradient(ending: Color(.sRGB, red: 0.7716346383, green: 0.8834385276, blue: 1))
    private static func gradient(ending color: Color) -> RepresentativeGradient {
        RepresentativeGradient(stops: [
            .init(color: Color(.sRGB, red: 0.9974356294, green: 0.9974356294, blue: 0.9974356294), location: 0),
            .init(color: color, location: 0.9697805643)
        ], transform: transform, opacity: 1)
    }
}

struct HomePopupLabel<Icon: View>: View {
    let title: String
    var primary = false
    @ViewBuilder var icon: Icon
    @Environment(\.homePopupPressed) private var pressed

    var body: some View {
        HStack(spacing: 12) {
            icon.frame(width: 28, height: 28).accessibilityHidden(true)
            Text(title).pretendard(primary ? .medium : .regular, 16).lineLimit(1).minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }.foregroundStyle(Color.rep4.c08).padding(.horizontal, 9).frame(height: 50)
            .background {
                if primary || pressed { RepresentativeGradientFill(definition: HomePopupStyle.selected) }
                else { Color.white }
            }.clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder((primary || pressed) ? HomePopupStyle.selectedBorder : HomePopupStyle.border, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}

enum HomeDollDance: String, CaseIterable {
    case exercise, dance, tap, wiggle
    var title: String {
        switch self {
        case .exercise: "아침체조"
        case .dance: "댄스댄스"
        case .tap: "탭댄스"
        case .wiggle: "씰룩씰룩"
        }
    }
    var move: DanceMove {
        switch self {
        case .exercise: .morningExercise
        case .dance: .danceDance
        case .tap: .tapDance
        case .wiggle: .wiggle
        }
    }
}

struct HomeDollDancePicker: View {
    @Binding var selection: HomeDollDance?
    var onClose: () -> Void
    var body: some View {
        DanceChoiceContent(selection: selection?.move, onSelect: { move in
            selection = HomeDollDance.allCases.first { $0.move == move }
        }, onClose: onClose)
        .padding(.horizontal,20).padding(.top,20).padding(.bottom,12)
        .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.top)
        .background(Color.white, ignoresSafeAreaEdges: [])
        .accessibilityElement(children:.contain)
        .accessibilityIdentifier("home-doll-dance-picker")
    }
}

private struct HomePopupPressedKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var homePopupPressed: Bool {
        get { self[HomePopupPressedKey.self] }
        set { self[HomePopupPressedKey.self] = newValue }
    }
}
struct HomePopupPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.environment(\.homePopupPressed, configuration.isPressed)
    }
}

import SwiftUI

/// Home menus share the compact Figma surface (1949:13760).
struct HomePopup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).pretendard(.medium, 13).foregroundStyle(Color.rep4.c16)
                .frame(height: 20).lineLimit(1)
            content
        }.padding(13).frame(width: 204)
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

    var body: some View {
        HStack(spacing: 12) {
            icon.frame(width: 28, height: 28).accessibilityHidden(true)
            Text(title).pretendard(primary ? .medium : .regular, 16).lineLimit(1).minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }.foregroundStyle(Color.rep4.c08).padding(.horizontal, 9).frame(height: 44)
            .background {
                if primary { RepresentativeGradientFill(definition: HomePopupStyle.selected) }
                else { Color.rep4.c11 }
            }.clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(primary ? HomePopupStyle.selectedBorder : HomePopupStyle.border, lineWidth: 1))
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
    @Binding var selection: HomeDollDance
    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomeDollDance.allCases, id: \.self) { dance in
                Button { selection = dance } label: {
                    Text((selection == dance ? "✓ " : "") + dance.title)
                        .pretendard(.regular, 12.167, tracking: -0.6084)
                        .lineLimit(1).fixedSize(horizontal: true, vertical: false)
                        .frame(maxWidth: .infinity).frame(width: selection == dance ? 68 : nil).frame(height: 31)
                        .background {
                            if selection == dance { RepresentativeGradientFill(definition: HomePopupStyle.danceSelection).clipShape(Capsule()) }
                        }
                        .overlay(Capsule().strokeBorder(selection == dance ? FlowDesign.blue : .clear, lineWidth: 0.873))
                }.buttonStyle(.plain).accessibilityLabel(dance.title)
                    .accessibilityAddTraits(selection == dance ? .isSelected : [])
            }
        }.foregroundStyle(Color.rep4.c08).padding(.horizontal, 5).frame(width: 239, height: 39)
            .background(.white, in: Capsule()).accessibilityIdentifier("home-doll-dance-picker")
            .transaction { $0.animation = nil }
    }
}

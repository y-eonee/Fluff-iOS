import SwiftUI

/// 945:2242 홈 프레임의 장식 치수. 원본 SVG의 필터 여백까지 포함한다.
enum CozyHomeStyle {
    static let button: CGFloat = 49
    static let headerInset: CGFloat = 22
    static let headerHeight: CGFloat = 48
    static let titleSize: CGFloat = 34
    static let titleTracking: CGFloat = -1.36
    static let tabHeight: CGFloat = 66
    static let tabLabel: CGFloat = 11
    static let tabTracking: CGFloat = -0.22
    static let tabRadius: CGFloat = 4
    static let tabLine: CGFloat = 1.2
    static let tabLip: CGFloat = 16
    static let tabLipInset: CGFloat = 6
    static let tabLeading: CGFloat = 27.6
    static let tabTrailing: CGFloat = 21.6
    static let tabFrost = Color(uiColor: Palette.uiColor("#FFF9F2"))
    static let tabReflection = LinearGradient(stops: [.init(color: .white.opacity(0.55), location: 0),
                                                     .init(color: .white.opacity(0.04), location: 0.20),
                                                     .init(color: .clear, location: 0.65),
                                                     .init(color: .white.opacity(0.12), location: 1)],
                                                startPoint: .top, endPoint: .bottom)
    static let selectedLipOffset: CGFloat = -12
    static let idleLipOffset: CGFloat = -6
    static let selectedLipAngle = -3.07
    static let selectedLip = LinearGradient(colors: [Color(uiColor: Palette.uiColor("#EFE5FF")), .white,
                                                      Color(uiColor: Palette.uiColor("#F4EBFE"))],
                                            startPoint: .leading, endPoint: .trailing)
    static let glassHighlight = LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.08), .white.opacity(0.5)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct CozyHomeAction: View {
    let asset: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(asset)
                .frame(width: CozyHomeStyle.button, height: CozyHomeStyle.button)
                .glassEffect(.clear.tint(Color(uiColor: Palette.uiColor("#E9DFEE")).opacity(0.32)).interactive(), in: Circle())
                .overlay {
                    Circle().strokeBorder(CozyHomeStyle.glassHighlight, lineWidth: CozyHomeStyle.tabLine)
                }
                .shadow(color: Color.a.brown.opacity(0.12), radius: Spacing.xs, y: Spacing.xxs)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct CozyHomeTabs: View {
    @Binding var selection: AppTab

    private let tabs: [(AppTab, String, String)] = [
        (.dolls, "솜뭉치들", "cozy_dolls"), (.home, "내 방", "cozy_home"),
        (.friends, "친구", "cozy_friends"), (.mypage, "마이", "cozy_my")
    ]

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(tabs, id: \.0) { tab, title, asset in
                let selected = selection == tab
                Button { selection = tab } label: {
                    VStack(spacing: 0) {
                        Image(asset)
                            .frame(height: CozyHomeStyle.headerHeight)
                        Text(title)
                            .pretendard(selected ? .bold : .regular, CozyHomeStyle.tabLabel,
                                        tracking: CozyHomeStyle.tabTracking)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: CozyHomeStyle.tabHeight)
                    .background {
                        RoundedRectangle(cornerRadius: CozyHomeStyle.tabRadius)
                            .fill(.clear)
                            .glassEffect(.regular.tint(CozyHomeStyle.tabFrost.opacity(0.20)).interactive(),
                                         in: RoundedRectangle(cornerRadius: CozyHomeStyle.tabRadius))
                            .opacity(0.58)
                            .overlay {
                                RoundedRectangle(cornerRadius: CozyHomeStyle.tabRadius)
                                    .fill(CozyHomeStyle.tabReflection)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: CozyHomeStyle.tabRadius)
                                    .strokeBorder(CozyHomeStyle.glassHighlight, lineWidth: CozyHomeStyle.tabLine)
                            }
                    }
                    .background(alignment: .top) {
                        UnevenRoundedRectangle(topLeadingRadius: CozyHomeStyle.tabRadius,
                                               topTrailingRadius: CozyHomeStyle.tabRadius)
                            .fill(selected ? AnyShapeStyle(CozyHomeStyle.selectedLip) : AnyShapeStyle(Color.white.opacity(0.35)))
                            .overlay {
                                UnevenRoundedRectangle(topLeadingRadius: CozyHomeStyle.tabRadius,
                                                       topTrailingRadius: CozyHomeStyle.tabRadius)
                                    .strokeBorder(.white, lineWidth: CozyHomeStyle.tabLine)
                            }
                            .frame(height: CozyHomeStyle.tabLip)
                            .mask(alignment: .top) {
                                Rectangle().frame(height: selected ? -CozyHomeStyle.selectedLipOffset : -CozyHomeStyle.idleLipOffset)
                            }
                            .padding(.horizontal, selected ? CozyHomeStyle.tabLipInset / 2 : CozyHomeStyle.tabLipInset)
                            .rotationEffect(.degrees(selected ? CozyHomeStyle.selectedLipAngle : 0))
                            .offset(y: selected ? CozyHomeStyle.selectedLipOffset : CozyHomeStyle.idleLipOffset)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(.leading, CozyHomeStyle.tabLeading)
        .padding(.trailing, CozyHomeStyle.tabTrailing)
        .padding(.top, Spacing.s)
    }
}

#Preview("입체 홈 탭") {
    ZStack {
        Color.a.pink
        VStack {
            CozyHomeAction(asset: "cozy_create", label: "인형 만들기", action: {})
            CozyHomeTabs(selection: .constant(.home))
        }
    }
}

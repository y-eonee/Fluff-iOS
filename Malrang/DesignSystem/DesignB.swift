import SwiftUI

extension Color {
    enum b {
        static let paper = Color(red: 251/255, green: 243/255, blue: 220/255)
        static let ink = Color(red: 28/255, green: 26/255, blue: 24/255)
        static let brown = Color(red: 75/255, green: 52/255, blue: 38/255)
        static let soft = Color(red: 138/255, green: 132/255, blue: 125/255)
        static let line = Color(red: 230/255, green: 225/255, blue: 218/255)
        static let orange = Color(red: 240/255, green: 120/255, blue: 62/255)
        static let peach = Color(red: 255/255, green: 178/255, blue: 126/255)
        static let inactive = Color(red: 235/255, green: 230/255, blue: 223/255)
        static let danger = Color(red: 184/255, green: 85/255, blue: 63/255)
    }
}

enum BStyle {
    static let title: CGFloat = 24
    static let sheetHeight: CGFloat = 300
    static let previewHeight: CGFloat = 300
    static let orange = LinearGradient(colors: [Color.b.orange, Color.b.peach], startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// 선택 탭과 버튼이 같은 주황색·흰색 반사광을 공유한다.
struct BButtonSurface: View {
    var primary = true
    var radius: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(primary ? AnyShapeStyle(BStyle.orange) : AnyShapeStyle(LinearGradient(
                colors: [.white, Color.b.peach.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay {
                Image("b_screen0_imgEllipse2085").resizable().scaledToFill()
                    .blendMode(.screen).opacity(primary ? 0.55 : 0.8)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(.white.opacity(0.85)))
            .allowsHitTesting(false)
    }
}

/// 탭바와 같은 부드러운 반사광. 버튼의 기존 모양 안에만 효과를 넣는다.
struct BGlossButtonStyle: ButtonStyle {
    @Environment(\.whiteDollButtons) private var whiteDollButtons
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var radius: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                if !whiteDollButtons {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient(stops: [.init(color: .white.opacity(0.48), location: 0),
                                                 .init(color: .white.opacity(0.06), location: 0.45),
                                                 .init(color: .clear, location: 0.55)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .blendMode(.screen)
                    .allowsHitTesting(false)
                }
            }
            .overlay {
                if !whiteDollButtons {
                    RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(.white.opacity(0.55))
                }
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
            .animation(reduceMotion ? nil : .spring(response: 0.25), value: configuration.isPressed)
    }
}

extension View {
    @ViewBuilder func buttonGloss(radius: CGFloat = 16) -> some View {
        if DesignVariant.current == .b { buttonStyle(BGlossButtonStyle(radius: radius)) }
        else { buttonStyle(.plain) }
    }
}

struct BBackground: View {
    var grid = false
    var body: some View {
        LinearGradient(colors: [.white, Color.b.paper], startPoint: .top, endPoint: .bottom)
            .overlay {
                if grid {
                    Image("b_screen0_imgGroup1107").resizable().scaledToFill()
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

struct BTabBar: View {
    @Binding var selection: AppTab
    private let tabs: [(AppTab, String)] = [
        (.dolls, "솜뭉치들"), (.home, "홈"),
        (.friends, "친구"), (.mypage, "마이")
    ]
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(tabs, id: \.0) { tab, label in
                Button { selection = tab } label: {
                    VStack(spacing: Spacing.xxs) {
                        switch tab {
                        case .home: Image("b_screen0_imgVector").resizable().renderingMode(.template).scaledToFit().frame(width: 20, height: 20)
                        case .dolls:
                            HStack(spacing: -Spacing.xs) {
                                Image("b_screen0_imgVector1").resizable().renderingMode(selection == .dolls ? .template : .original).scaledToFit()
                                Image("b_screen0_imgVector2").resizable().renderingMode(selection == .dolls ? .template : .original).scaledToFit()
                            }.frame(width: 30, height: 20)
                        case .friends: Image("b_screen0_imgVector3").resizable().renderingMode(.template).scaledToFit().frame(width: 20, height: 20)
                        case .mypage: Image("b_screen0_imgVector4").resizable().renderingMode(.template).scaledToFit().frame(width: 20, height: 20)
                        }
                        Text(label).pretendard(selection == tab ? .bold : .medium, 11)
                    }
                    .foregroundStyle(selection == tab ? .white : Color.b.soft)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background {
                        if selection == tab {
                            BButtonSurface(radius: 28)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(Spacing.xxs)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white, lineWidth: 1))
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.xs)
    }
}

#Preview {
    ZStack { BBackground(grid: true); VStack { Spacer(); BTabBar(selection: .constant(.home)) } }
}

import CoreText
import SwiftUI

/// 테스터가 마이페이지에서 고르는 디자인 시안. 시안 A는 피그마 1안이고, 시안 B는 따뜻한 원목과 부드러운 입체 스타일이다.
/// 시안이 다른 화면은 내 방, 솜뭉치 만들기(속재료·모양 고르기), 방 꾸미기 세 개다.
enum DesignVariant: String {
    case a, b

    /// 마이페이지에서 고른 시안. 색과 글꼴 토큰이 이 값을 읽는다.
    static var current: DesignVariant {
        DesignVariant(rawValue: UserDefaults.standard.string(forKey: "designVariant") ?? "") ?? .a
    }
}

extension Color {
    /// 시안 A(피그마 1안)의 색. 손그림 느낌의 갈색 선과 크림색 종이 바탕을 쓴다.
    enum a {
        static let paper = Color(hex: 0xFFFFF4)
        static let card = Color(hex: 0xFFF9F2)
        static let brown = Color(hex: 0x6B4A3E)
        static let line = Color(hex: 0x8E6A5C)
        static let soft = Color(hex: 0x8A6A5E)
        static let cream = Color(hex: 0xFEF2CC)
        static let creamText = Color(hex: 0xFFF6EE)
        static let pink = Color(hex: 0xF7B9C8)
        static let pinkLight = Color(hex: 0xFBDDE4)
        static let blue = Color(hex: 0xA6C5E2)
        static let blueLight = Color(hex: 0xCFE8F2)
        static let yellow = Color(hex: 0xFDE9A0)
        static let yellowLight = Color(hex: 0xFCEBC0)
        static let mint = Color(hex: 0xCDEBD9)
        static let danger = Color(hex: 0xB5475F)
        static let dangerLine = Color(hex: 0xC9576F)
        static let dangerFill = Color(hex: 0xFFF1F3)
    }

    fileprivate init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

extension Font {
    /// Resources의 Origin과 Pretendard 글꼴을 등록한다.
    static func registerCustomFonts() {
        for url in Bundle.main.urls(forResourcesWithExtension: "otf", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

enum Pretendard: String {
    case regular = "Regular", medium = "Medium", semiBold = "SemiBold", bold = "Bold", black = "Black"
}

extension View {
    /// A·B 공통 본문 글꼴(Pretendard).
    func pretendard(_ weight: Pretendard, _ size: CGFloat, tracking: CGFloat = 0) -> some View {
        font(.custom("Pretendard-\(weight.rawValue)", size: size, relativeTo: .body))
            .tracking(tracking)
            .fontDesign(nil)
    }

    /// 영문 제목은 첨부된 Origin Display를 쓴다.
    func origin(_ size: CGFloat, relativeTo style: Font.TextStyle) -> some View {
        font(.custom("Origin-RegularDisplay", size: size, relativeTo: style))
            .fontDesign(nil)
    }

    /// A안에서 원래 사용하던 손글씨 제목.
    func notCliche(_ size: CGFloat, relativeTo style: Font.TextStyle) -> some View {
        font(.custom("establishNotClicheOTF", size: size, relativeTo: style))
            .fontDesign(nil)
    }

    /// 손으로 그린 듯한 갈색 테두리 상자 (시안 A)
    func sketchBox(fill: Color = Color.a.card, radius: CGFloat = 8, line: CGFloat = 1.2, dashed: Bool = false) -> some View {
        background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.a.line, style: StrokeStyle(lineWidth: line, dash: dashed ? [4, 3] : [])))
    }
}

/// 모눈종이 배경 (시안 A)
struct GridPaper: View {
    var body: some View {
        ZStack {
            Color.a.paper
            Image("a_grid")
                .resizable()
                .scaledToFill()
        }
        .ignoresSafeArea()
    }
}

/// 시안 A의 동그란 보조 버튼. 아이콘만 있고 이름은 VoiceOver로 읽는다.
struct SketchCircleButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body)
                .foregroundStyle(Color.a.brown)
                .frame(width: 48, height: 48)
                .sketchBox(radius: 24)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// 시안 A의 수첩 모양 하단 탭. 선택한 탭은 분홍 띠가 위로 올라온다.
struct NotebookTabBar: View {
    @Binding var selection: AppTab

    private struct Item {
        let tab: AppTab
        let title: String
        let asset: String?
    }

    private let items = [
        Item(tab: .dolls, title: "솜뭉치들", asset: nil),
        Item(tab: .home, title: "내 방", asset: "a_tab_home"),
        Item(tab: .friends, title: "친구", asset: "a_tab_friends"),
        Item(tab: .mypage, title: "마이", asset: "a_tab_my"),
    ]

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(items, id: \.tab) { item in
                let isSelected = selection == item.tab
                Button {
                    selection = item.tab
                } label: {
                    VStack(spacing: Spacing.xxs) {
                        if let asset = item.asset {
                            Image(asset)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                        } else {
                            ZStack(alignment: .topLeading) {
                                Image("a_cloud_main")
                                Image("a_cloud_part").offset(x: 19.7, y: 9)
                            }
                            .frame(width: 41, height: 25)
                            .frame(height: 28)
                        }
                        Text(item.title)
                            .pretendard(isSelected ? .bold : .regular, 11, tracking: -0.22)
                            .foregroundStyle(Color.a.brown)
                    }
                    .frame(maxWidth: .infinity, minHeight: 66)
                    .sketchBox(radius: 4)
                    .background(alignment: .top) {
                        UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4, style: .continuous)
                            .fill(isSelected ? Color.a.pink : .white)
                            .overlay(UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4, style: .continuous)
                                .stroke(Color.a.line, lineWidth: 1.1))
                            .frame(height: 16)
                            .padding(.horizontal, Spacing.xxs)
                            .offset(y: isSelected ? -10 : -5)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.top, Spacing.s)
        .background { Color.a.paper.opacity(0.96).ignoresSafeArea(edges: .bottom) }
    }
}

#Preview("탭바") {
    VStack {
        Spacer()
        NotebookTabBar(selection: .constant(.home))
    }
    .background(GridPaper())
}


/// 화면 바탕. 시안 A는 모눈종이, 시안 B는 흰색에서 크림색으로 이어지는 바탕이다.
struct AppBackground: View {
    var body: some View {
        if DesignVariant.current == .a { GridPaper() } else { BBackground() }
    }
}

/// 두 시안에서 동일한 Pretendard 본문을 쓴다.
struct AppFont: ViewModifier {
    let style: Font.TextStyle
    var weight: Pretendard?

    private var size: CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        default: 11
        }
    }

    private var defaultWeight: Pretendard { style == .headline ? .bold : .regular }

    func body(content: Content) -> some View {
            content
                .font(.custom("Pretendard-\((weight ?? defaultWeight).rawValue)", size: size, relativeTo: style))
                .fontDesign(nil)
    }
}

extension Pretendard {
    var systemWeight: Font.Weight {
        switch self {
        case .regular: .regular
        case .medium: .medium
        case .semiBold: .semibold
        case .bold: .bold
        case .black: .black
        }
    }
}

extension View {
    func appFont(_ style: Font.TextStyle, _ weight: Pretendard? = nil) -> some View {
        modifier(AppFont(style: style, weight: weight))
    }

    /// 시안 A에서는 시스템 탭바 대신 수첩 모양 탭바를 이 화면 아래에 둔다.
    func notebookTabBar() -> some View {
        modifier(NotebookTabBarModifier())
    }
}

private struct NotebookTabBarModifier: ViewModifier {
    @Environment(AppState.self) private var appState
    @AppStorage("designVariant") private var variant = DesignVariant.a

    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .tabBar)
            .safeAreaInset(edge: .bottom) {
                if variant == .a {
                    NotebookTabBar(selection: Binding(get: { appState.tab }, set: { appState.tab = $0 }))
                } else {
                    BTabBar(selection: Binding(get: { appState.tab }, set: { appState.tab = $0 }))
                }
            }
    }
}

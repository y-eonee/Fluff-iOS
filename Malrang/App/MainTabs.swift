import SwiftUI

/// The three destinations keep their own navigation state. The reference's
/// detached room action opens tools without selecting an empty destination.
struct MainTabs: View {
    var couch: CouchSession? = nil
    @Environment(AppState.self) private var appState
    @AppStorage("hapticOn") private var hapticOn = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hidesBar = false
    @State private var roomActionButtonFrame = CGRect.zero
    private var selection: Binding<AppTab> {
        Binding(get: { appState.tab }, set: { appState.roomToolsOpen = false; appState.tab = $0 })
    }
    var body: some View {
        TabView(selection: selection) {
            Tab(value: AppTab.dolls) { DollListView().toolbar(.hidden, for: .tabBar) } label: { Text("솜뭉치들") }
            Tab(value: AppTab.home) { HomeView(couch: couch).toolbar(.hidden, for: .tabBar) } label: { Text("내 방") }
            Tab(value: AppTab.mypage) {
                NavigationStack { MyPageView() }.toolbar(.hidden, for: .tabBar)
            } label: { Text("마이") }
        }
        .tint(Color.rep4.c03)
        .sensoryFeedback(trigger: appState.tab) { _, _ in hapticOn ? .selection : nil }
        .sensoryFeedback(trigger: appState.roomToolsOpen) { _, _ in hapticOn ? .impact(weight: .light) : nil }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !hidesBar {
                navigationBar.padding(.top, 4).padding(.bottom, 14)
            }
        }
        .onPreferenceChange(AppTabBarHiddenPreference.self) { hidesBar = $0 }
        .environment(\.roomActionButtonFrame, roomActionButtonFrame)
        .environment(\.returnToDollList, { appState.tab = .dolls })
    }
    private var navigationBar: some View {
        HStack(spacing: 22.8) {
            HStack(spacing: -4.66) {
                destination(.dolls, title: "솜뭉치들", icon: "cloud")
                destination(.home, title: "내 방", icon: "home")
                destination(.mypage, title: "마이", icon: "user")
            }.frame(width: 220.58, height: 63.69)
                .background(appState.tab == .home ? Color.rep4.c01 : Color.clear, in: Capsule())
                .overlay {
                    if appState.tab != .home {
                        Capsule().strokeBorder(Color(uiColor: Palette.uiColor("#ECECEC")), lineWidth: 1)
                            .allowsHitTesting(false)
                    }
                }
            if appState.tab == .home {
                Button { appState.toggleRoomTools() } label: {
                    Group {
                        if appState.roomToolsOpen { Image(systemName: "xmark").font(.system(size: 22, weight: .medium)) }
                        else { Image("rep4_tab_tools").resizable().scaledToFit().frame(width: 29.2, height: 22) }
                    }.contentTransition(.opacity)
                        .animation(RoomMotion.response(reduceMotion: reduceMotion), value: appState.roomToolsOpen)
                        .frame(width: 63.69, height: 63.69).background(Color.rep4.c01, in: Circle())
                }.buttonStyle(RoomPressStyle()).accessibilityLabel(appState.roomToolsOpen ? "방 도구 닫기" : "방 도구")
                    .accessibilityAddTraits(appState.roomToolsOpen ? .isSelected : [])
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) }
                        action: { roomActionButtonFrame = $0 }
            }
        }.foregroundStyle(Color.rep4.c03).frame(maxWidth: .infinity).offset(x: appState.tab == .home ? 5.575 : 0)
    }
    private func destination(_ tab: AppTab, title: String, icon: String) -> some View {
        Button { selection.wrappedValue = tab } label: {
            VStack(spacing: 3.48) {
                Image("rep4_tab_" + icon + (tab == .dolls && appState.tab == .dolls ? "_selected" : tab == .home && appState.tab != .home ? "_unselected" : ""))
                    .resizable().scaledToFit().frame(width: 20.88, height: 20.88)
                    .opacity(appState.tab == .home || appState.tab == tab ? 1 : 0.45)
                if appState.tab == .dolls && tab != .dolls {
                    Text(title).pretendard(.bold, 13).foregroundStyle(Color.rep4.c09)
                } else {
                    Text(title).pretendard(appState.tab == .home ? .regular : (appState.tab == tab ? .medium : .regular), appState.tab == .home ? 14 : 12, tracking: appState.tab == .home ? -0.7 : 0)
                        .opacity(appState.tab == .home || appState.tab == tab ? 1 : 0.45)
                }
            }
                .frame(width: 70.046, height: 55.69).contentShape(Rectangle())
        }.buttonStyle(RoomPressStyle()).accessibilityAddTraits(appState.tab == tab ? .isSelected : [])
    }
}

struct AppTabBarHiddenPreference: PreferenceKey {
    static var defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

private struct RoomActionButtonFrameKey: EnvironmentKey {
    static let defaultValue = CGRect.zero
}

extension EnvironmentValues {
    var roomActionButtonFrame: CGRect {
        get { self[RoomActionButtonFrameKey.self] }
        set { self[RoomActionButtonFrameKey.self] = newValue }
    }
}

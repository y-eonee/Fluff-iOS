import SwiftData
import SwiftUI

/// The three destinations keep their own navigation state. The reference's
/// detached room action opens tools without selecting an empty destination.
struct MainTabs: View {
    var couch: CouchSession? = nil
    @Query(sort: \Doll.createdAt) private var dolls: [Doll]
    @Environment(AppState.self) private var appState
    @Environment(\.startupPresentationFinished) private var startupPresentationFinished
    @AppStorage("hapticOn") private var hapticOn = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hidesBar = false
    @State private var roomActionButtonFrame = CGRect.zero
    private var selection: Binding<AppTab> {
        Binding(get: { appState.tab }, set: { appState.roomToolsOpen = false; appState.tab = $0 })
    }
    private var showsRoomIntro: Bool {
        startupPresentationFinished && appState.tab == .home && !appState.roomEntrance.finished
    }

    var body: some View {
        TabView(selection: selection) {
            Tab(value: AppTab.dolls) { DollListView().toolbar(.hidden, for: .tabBar) } label: { Text("내 인형") }
            Tab(value: AppTab.home) { HomeView(couch: couch).toolbar(.hidden, for: .tabBar) } label: { Text("내 방") }
            Tab(value: AppTab.mypage) {
                NavigationStack { MyPageView() }.toolbar(.hidden, for: .tabBar)
            } label: { Text("마이") }
        }
        .tint(Color.rep4.c03)
        .sensoryFeedback(trigger: appState.tab) { _, _ in hapticOn ? .selection : nil }
        .sensoryFeedback(trigger: appState.roomToolsOpen) { _, _ in hapticOn ? .impact(weight: .light) : nil }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !hidesBar || showsRoomIntro {
                navigationBar.padding(.top, 4).padding(.bottom, 14)
            }
        }
        .allowsHitTesting(!showsRoomIntro)
        .accessibilityHidden(showsRoomIntro)
        .overlay {
            if showsRoomIntro {
                RoomLoadingView(entrance: appState.roomEntrance)
            }
        }
        .onAppear { appState.roomEntrance.chooseLoadingDoll(from: dolls) }
        .onPreferenceChange(AppTabBarHiddenPreference.self) { hidesBar = $0 }
        .environment(\.roomActionButtonFrame, roomActionButtonFrame)
        .environment(\.returnToDollList, { appState.tab = .dolls })
    }
    private var navigationBar: some View {
        HStack(spacing: 22.8) {
            HStack(spacing: -4.66) {
                destination(.dolls, title: "내 인형", icon: "cloud")
                destination(.home, title: "내 방", icon: "home")
                destination(.mypage, title: "마이", icon: "user")
            }.frame(width: 220.58, height: 63.69)
                .modifier(FluffTabGlass())
                .modifier(RoomEntranceMotion(entrance: appState.roomEntrance, node: appState.tab == .home ? (appState.roomEntrance.loadingDoll == nil ? "1932:6578" : "1913:7942") : ""))
            if appState.tab == .home {
                Button { appState.toggleRoomTools() } label: {
                    Group {
                        if appState.roomToolsOpen { Image(systemName: "xmark").font(.system(size: 22, weight: .medium)) }
                        else { Image("fluff_floating").resizable().scaledToFit().frame(width: 36, height: 36) }
                    }.contentTransition(.opacity)
                        .animation(RoomMotion.response(reduceMotion: reduceMotion), value: appState.roomToolsOpen)
                        .frame(width: 63.69, height: 63.69).background(Color.rep4.c01, in: Circle())
                }.buttonStyle(RoomPressStyle()).accessibilityLabel(appState.roomToolsOpen ? "방 도구 닫기" : "방 도구")
                    .modifier(RoomEntranceMotion(entrance: appState.roomEntrance, node: appState.roomEntrance.loadingDoll == nil ? "1932:6578" : "1913:7942"))
                    .accessibilityAddTraits(appState.roomToolsOpen ? .isSelected : [])
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) }
                        action: { roomActionButtonFrame = $0 }
            }
        }.foregroundStyle(Color.rep4.c03).frame(maxWidth: .infinity).offset(x: appState.tab == .home ? 5.575 : 0)
    }
    private func destination(_ tab: AppTab, title: String, icon: String) -> some View {
        Button { selection.wrappedValue = tab } label: {
            VStack(spacing: 3.48) {
                Image(tab == .dolls && appState.tab != .dolls ? "rep4_tab_cloud" :
                      tab == .home && appState.tab == .home ? "rep4_tab_home" : "fluff_tab_" + icon)
                    .renderingMode(.template).resizable().scaledToFit()
                    .frame(width: 20.883, height: 20.883)
                    .foregroundStyle(appState.tab == tab ? Color.rep4.c08 : Color(uiColor: Palette.uiColor("#A2A2A2")))
                Text(title).pretendard(.medium, 12)
                    .foregroundStyle(appState.tab == tab ? Color.rep4.c08 : Color(uiColor: Palette.uiColor("#A2A2A2")))
            }
                .frame(width: 70.046, height: 55.69)
                .contentShape(Rectangle())
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

private struct StartupPresentationFinishedKey: EnvironmentKey {
    // Standalone previews do not have the app's splash presentation.
    static let defaultValue = true
}

extension EnvironmentValues {
    var startupPresentationFinished: Bool {
        get { self[StartupPresentationFinishedKey.self] }
        set { self[StartupPresentationFinishedKey.self] = newValue }
    }

    var roomActionButtonFrame: CGRect {
        get { self[RoomActionButtonFrameKey.self] }
        set { self[RoomActionButtonFrameKey.self] = newValue }
    }
}

/// The reference keeps a compact three-item capsule and a detached room action.
/// Use one native glass material for this existing navigation surface on every tab.
private struct FluffTabGlass: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    func body(content: Content) -> some View {
        Group {
            if reduceTransparency { content.background(Color.rep4.c01, in: Capsule()) }
            else { content.glassEffect(.regular.tint(.white.opacity(0.16)), in: Capsule()) }
        }
        .overlay { Capsule().strokeBorder(.white.opacity(0.85), lineWidth: 1).allowsHitTesting(false) }
    }
}

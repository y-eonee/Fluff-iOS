import SwiftUI

struct MainTabs: View {
    @Environment(AppState.self) private var appState

    private enum Selection: Hashable { case destination(AppTab), roomTools }
    private var selection: Binding<Selection> {
        Binding(get: { .destination(appState.tab) }, set: { value in
            switch value {
            case .destination(let tab): appState.roomToolsOpen = false; appState.tab = tab
            case .roomTools: appState.toggleRoomTools()
            }
        })
    }
    private var toolsRole: TabRole {
        if #available(iOS 27, *) { return .prominent }
        // iOS 26's detached trailing slot; supply our own label and handle as an action.
        return .search
    }

    var body: some View {
        TabView(selection: selection) {
            Tab(value: Selection.destination(AppTab.dolls)) { DollListView().tint(Color.mib.text.primary).toolbarColorScheme(.light, for: .tabBar) } label: {
                Label("인형들", image: "d1_cloud")
            }
            Tab(value: Selection.destination(AppTab.home)) { HomeView().tint(Color.mib.text.primary).toolbarColorScheme(.light, for: .tabBar) } label: {
                Label("내 방", image: "d1_homeTab")
            }
            Tab(value: Selection.destination(AppTab.mypage)) {
                NavigationStack { MyPageView() }.tint(Color.mib.text.primary).toolbarColorScheme(.light, for: .tabBar)
            } label: {
                Label("마이", image: "d1_my")
            }
            if appState.tab == .home {
                Tab("방 도구", systemImage: appState.roomToolsOpen ? "xmark" : "wrench.and.screwdriver.fill", value: Selection.roomTools, role: toolsRole) {
                    Color.clear
                }
            }
        }
        .tint(Color.mib.text.primary)
        .environment(\.returnToDollList, { appState.tab = .dolls })
    }
}

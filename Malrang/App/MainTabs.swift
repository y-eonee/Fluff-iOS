import SwiftUI

struct MainTabs: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView(selection: Binding(get: { appState.tab }, set: { appState.tab = $0 })) {
            Tab("솜뭉치들", systemImage: "teddybear", value: AppTab.dolls) { DollListView() }
            Tab("내 방", systemImage: "house", value: AppTab.home) { HomeView() }
            Tab("친구", systemImage: "person.2", value: AppTab.friends) { FriendsView() }
            Tab("마이", systemImage: "person.crop.circle", value: AppTab.mypage) {
                NavigationStack { MyPageView() }
            }
        }.tint(Color.a.brown)
    }
}

import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("nickname") private var nickname = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(MultiRoom.self) private var multiRoom
    @Query private var items: [RoomItem]
    @State private var appState = AppState()

    var body: some View {
        if isSignedIn && nickname.isEmpty {
            NavigationStack { ProfileEditView(isCreating: true) }
        } else if isSignedIn {
            TabView(selection: $appState.tab) {
                Tab("인형 목록", systemImage: "teddybear", value: .dolls) {
                    DollListView()
                }
                Tab("홈", systemImage: "house", value: .home) {
                    HomeView()
                }
                Tab("친구", systemImage: "person.2", value: .friends) {
                    FriendsView()
                }
            }
            .environment(appState)
            .task {
                if items.isEmpty {
                    RoomItem.starterRoom.forEach(modelContext.insert)
                }
            }
            .task { await multiRoom.observeSessions() }
            .fullScreenCover(isPresented: Binding(get: { multiRoom.session != nil }, set: { if !$0 { multiRoom.leave() } })) {
                MultiRoomView()
            }
        } else {
            OnboardingView { isSignedIn = true }
        }
    }
}

#Preview {
    RootView()
        .environment(FriendStore(api: MockFriendAPI()))
        .environment(MultiRoom())
        .modelContainer(.preview)
}

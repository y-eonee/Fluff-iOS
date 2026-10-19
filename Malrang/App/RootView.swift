import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("nickname") private var nickname = ""
    @AppStorage("didRestoreIllustrationShelf") private var didRestoreIllustrationShelf = false
    @AppStorage("didArrangeYellowWallDecor") private var didArrangeYellowWallDecor = false
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
                Tab("마이페이지", systemImage: "person.crop.circle", value: .mypage) {
                    NavigationStack { MyPageView() }
                }
            }
            .environment(appState)
            .task {
                if items.isEmpty {
                    RoomItem.starterRoom.forEach(modelContext.insert)
                } else if !didRestoreIllustrationShelf,
                          !items.contains(where: { $0.kind == .shelf }),
                          let shelf = RoomItem.starterRoom.first(where: { $0.kind == .shelf }) {
                    // 기존 방에는 새 기본 가구가 없으므로 한 번만 보충한다.
                    modelContext.insert(shelf)
                }
                if !didRestoreIllustrationShelf, (try? modelContext.save()) != nil {
                    didRestoreIllustrationShelf = true
                }
                if !didArrangeYellowWallDecor {
                    for item in items where item.kind == .frame || item.kind == .shelf {
                        let spot = RoomLayout.snapped([item.kind == .frame ? -0.5 : 0.4, -1], for: item.kind, yaw: Float(item.yaw))
                        item.x = Double(spot.x)
                        item.z = Double(spot.y)
                    }
                    if (try? modelContext.save()) != nil {
                        didArrangeYellowWallDecor = true
                    }
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

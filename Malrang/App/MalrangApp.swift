import SwiftData
import SwiftUI

@main
struct MalrangApp: App {
    @State private var friendStore = FriendStore(api: MockFriendAPI())
    @State private var multiRoom = MultiRoom()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(friendStore)
                .environment(multiRoom)
                .fontDesign(.rounded)
                .tint(Color.app.ink)
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [Doll.self, RoomItem.self, DecorPhoto.self])
    }
}

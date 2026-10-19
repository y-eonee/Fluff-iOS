import SwiftData
import SwiftUI

@main
struct MalrangApp: App {
    @State private var friendStore = FriendStore(api: MockFriendAPI())
    @State private var multiRoom = MultiRoom()
    @AppStorage("designVariant") private var variant = DesignVariant.a

    init() {
        Font.registerCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(friendStore)
                .environment(multiRoom)
                .fontDesign(variant == .a ? nil : .rounded)
                .tint(Color.app.ink)
                .id(variant)
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [Doll.self, RoomItem.self, DecorPhoto.self])
    }
}

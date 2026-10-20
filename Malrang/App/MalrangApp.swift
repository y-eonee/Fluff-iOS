import SwiftData
import SwiftUI

@main
struct MalrangApp: App {
    @State private var friendStore = FriendStore(api: MockFriendAPI())
    @State private var multiRoom = MultiRoom()
    @AppStorage("designVariant") private var variant = DesignVariant.a
    @State private var isShowingSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {
        Font.registerCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .allowsHitTesting(!isShowingSplash)
                    .accessibilityHidden(isShowingSplash)
                if isShowingSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                do { try await Task.sleep(for: .seconds(1.2)) }
                catch { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) {
                    isShowingSplash = false
                }
            }
            .environment(friendStore)
            .environment(multiRoom)
            .font(.custom("Pretendard-Regular", size: 17, relativeTo: .body))
            .tint(Color.app.ink)
            .id(variant)
            .preferredColorScheme(.light)
        }
        .modelContainer(for: [Doll.self, RoomItem.self, DecorPhoto.self])
    }
}

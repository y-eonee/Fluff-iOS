import SwiftUI

/// 모든 탭의 상단에 두는 알림함 버튼
struct NotificationsButton: View {
    @Environment(FriendStore.self) private var store

    var body: some View {
        NavigationLink {
            NotificationsView()
        } label: {
            Label("알림함", systemImage: store.hasUnreadNotifications ? "bell.badge" : "bell")
                .symbolRenderingMode(.multicolor)
        }
    }
}

#Preview {
    NavigationStack {
        Color.app.background
            .toolbar { NotificationsButton() }
    }
    .environment(FriendStore(api: MockFriendAPI()))
}

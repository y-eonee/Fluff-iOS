import SwiftUI

/// 알림함: 친구 요청, 방명록, 좋아요, 멀티 룸 초대
struct NotificationsView: View {
    @Environment(FriendStore.self) private var store
    @State private var isLoaded = false
    @State private var didFail = false
    @State private var isShowingMultiRoomNotice = false

    var body: some View {
        List {
            if didFail {
                Text("알림을 불러오지 못했어요")
            } else if !isLoaded {
                ProgressView()
            } else if store.notifications.isEmpty {
                Text("새 알림이 없어요")
                    .foregroundStyle(Color.app.inkSecondary)
            } else {
                ForEach(store.notifications) { notification in
                    row(notification)
                }
            }
        }
        .font(.body)
        .foregroundStyle(Color.app.ink)
        .scrollContentBackground(.hidden)
        .background(Color.app.background)
        .navigationTitle("알림함")
        .navigationBarTitleDisplayMode(.inline)
        .alert("멀티 룸은 준비 중이에요", isPresented: $isShowingMultiRoomNotice) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("곧 친구와 같은 방에서 함께 놀 수 있어요")
        }
        .task {
            do {
                try await store.loadNotifications()
                isLoaded = true
            } catch {
                didFail = true
            }
        }
    }

    private func row(_ notification: AppNotification) -> some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: notification.kind.symbol)
                .frame(width: 32)
            Text(notification.message)
                .frame(maxWidth: .infinity, alignment: .leading)
            switch notification.kind {
            case .friendRequest:
                Button("수락") {
                    Task { try? await store.accept(notification) }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.app.accent)
                .foregroundStyle(Color.app.ink)
            case .guestbook:
                NavigationLink("보기") {
                    GuestbookView(ownerID: "me", title: "내 방명록", canWrite: false)
                }
                .fixedSize()
            case .like:
                EmptyView()
            case .multiRoomInvite:
                Button("들어가기") { isShowingMultiRoomNotice = true }
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
    .environment(FriendStore(api: MockFriendAPI()))
}

import SwiftUI

/// 알림함: 친구 요청, 방명록, 좋아요
struct NotificationsView: View {
    @Environment(FriendStore.self) private var store
    @State private var isLoaded = false
    @State private var didFail = false
    @State private var filter: AppNotification.Kind?

    private var shown: [AppNotification] {
        store.notifications.filter { filter == nil || $0.kind == filter }
    }

    var body: some View {
        List {
            if didFail {
                Text("알림을 불러오지 못했어요")
            } else if !isLoaded {
                ProgressView()
            } else if shown.isEmpty {
                Text("새 알림이 없어요")
                    .foregroundStyle(Color.app.inkSecondary)
            } else {
                ForEach(shown) { notification in
                    row(notification)
                }
            }
        }
        .appFont(.body)
        .foregroundStyle(Color.app.ink)
        .scrollContentBackground(.hidden)
        .background { AppBackground() }
        .safeAreaInset(edge: .top) {
            HStack(spacing: Spacing.xs) {
                Chip(title: "전체", isSelected: filter == nil, isCompact: true) { filter = nil }
                ForEach(AppNotification.Kind.allCases, id: \.self) { kind in
                    Chip(title: kind.tag, isSelected: filter == kind, isCompact: true) { filter = kind }
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .background { AppBackground() }
        }
        .navigationTitle("알림함")
        .navigationBarTitleDisplayMode(.inline)
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

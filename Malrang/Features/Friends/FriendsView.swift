import SwiftUI

/// 친구 목록: 친구들의 방을 모아 보는 그리드
struct FriendsView: View {
    @Environment(FriendStore.self) private var store
    @State private var phase = Phase.loading
    @State private var isAdding = false
    @State private var rooms: [String: FriendRoom] = [:]

    enum Phase {
        case loading, failed, loaded
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .loading:
                    ProgressView()
                case .failed:
                    NoticeCard(symbol: "wifi.exclamationmark", title: "친구 목록을 불러오지 못했어요",
                               message: "잠시 뒤 다시 시도해 주세요", actionTitle: "다시 불러오기") {
                        Task { await load() }
                    }
                case .loaded:
                    grid
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.app.background)
            .navigationTitle("친구")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("친구 추가", systemImage: "person.badge.plus") { isAdding = true }
                    NotificationsButton()
                }
            }
            .navigationDestination(for: Friend.self) { friend in
                FriendRoomView(friend: friend)
            }
            .sheet(isPresented: $isAdding) {
                AddFriendSheet()
            }
            .task { await load() }
        }
    }

    private var grid: some View {
        Group {
            if store.friends.isEmpty {
                NoticeCard(symbol: "person.2", title: "아직 친구가 없어요",
                           message: "연락처에서 친구를 찾아 서로의 방에 놀러 가 보세요",
                           actionTitle: "친구 추가") { isAdding = true }
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.xs) {
                        ForEach(store.friends) { friend in
                            NavigationLink(value: friend) {
                                row(friend)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(Spacing.m)
                }
            }
        }
    }

    private func row(_ friend: Friend) -> some View {
        HStack(spacing: Spacing.s) {
            thumbnail(of: friend)
                .frame(width: 104, height: 84)
                .background(Color.app.pastelSky.opacity(0.4), in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
            Text("\(friend.name)의 방")
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
        }
        .foregroundStyle(Color.app.ink)
        .padding(Spacing.s)
        .background(Color.app.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func thumbnail(of friend: Friend) -> some View {
        switch rooms[friend.id] {
        case .some(let room) where !room.items.isEmpty:
            RoomThumbnail(room: room)
        case .some:
            Image(systemName: "house")
                .font(.title2)
                .foregroundStyle(Color.app.inkSecondary)
        case .none:
            ProgressView()
        }
    }

    private func load() async {
        phase = .loading
        do {
            try await store.loadFriends()
            phase = .loaded
            // 방은 하나씩 불러오는 대로 썸네일이 채워진다. 못 불러온 방은 빈 방으로 보여준다.
            for friend in store.friends where rooms[friend.id] == nil {
                rooms[friend.id] = (try? await store.api.room(of: friend)) ?? FriendRoom(items: [], dolls: [])
            }
        } catch {
            phase = .failed
        }
    }
}

#Preview {
    FriendsView()
        .environment(FriendStore(api: MockFriendAPI()))
}

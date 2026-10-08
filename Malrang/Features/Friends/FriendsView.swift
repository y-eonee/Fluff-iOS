import SwiftUI

/// 친구 목록: 친구들의 방을 모아 보는 그리드
struct FriendsView: View {
    @Environment(FriendStore.self) private var store
    @State private var phase = Phase.loading
    @State private var isAdding = false

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
            Image(systemName: "house.fill")
                .font(.title3)
                .frame(width: 48, height: 48)
                .background(Color.app.pastelSky, in: Circle())
            Text("\(friend.name)의 방")
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
        }
        .foregroundStyle(Color.app.ink)
        .padding(Spacing.s)
        .frame(minHeight: 64)
        .background(Color.app.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func load() async {
        phase = .loading
        do {
            try await store.loadFriends()
            phase = .loaded
        } catch {
            phase = .failed
        }
    }
}

#Preview {
    FriendsView()
        .environment(FriendStore(api: MockFriendAPI()))
}

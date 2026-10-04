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
        ScrollView {
            if store.friends.isEmpty {
                Text("아직 친구가 없어요. 친구를 추가해 서로의 방에 놀러 가 보세요")
                    .font(.footnote)
                    .foregroundStyle(Color.app.inkSecondary)
                    .padding(.top, Spacing.m)
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.s), GridItem(.flexible())], spacing: Spacing.s) {
                ForEach(store.friends) { friend in
                    NavigationLink(value: friend) {
                        card(title: "\(friend.name)의 방", symbol: "house.fill")
                    }
                }
                Button {
                    isAdding = true
                } label: {
                    card(title: "친구 추가", symbol: "person.badge.plus", note: "아이디로 찾기")
                }
            }
            .buttonStyle(.plain)
            .padding(Spacing.m)
        }
    }

    private func card(title: String, symbol: String, note: String? = nil) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: symbol)
                .font(.largeTitle)
                .frame(width: 72, height: 72)
                .background(Color.app.pastelSky, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
            Text(title)
                .font(.headline)
            if let note {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(Color.app.inkSecondary)
            }
        }
        .foregroundStyle(Color.app.ink)
        .frame(maxWidth: .infinity, minHeight: 180)
        .cardStyle()
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

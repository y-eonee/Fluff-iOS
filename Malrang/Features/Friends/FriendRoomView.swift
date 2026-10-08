import SwiftUI

/// 친구의 3D 방을 구경하고, 인형을 만지고, 좋아요와 방명록을 남긴다.
struct FriendRoomView: View {
    let friend: Friend
    @Environment(FriendStore.self) private var store
    @State private var phase = Phase.loading
    @State private var selectedDoll: DollState?
    @State private var isShowingGuestbook = false

    enum Phase {
        case loading, failed, loaded(FriendRoom)
    }

    var body: some View {
        Group {
            switch phase {
            case .loading:
                ProgressView("\(friend.name)의 방에 가는 중")
            case .failed:
                NoticeCard(symbol: "wifi.exclamationmark", title: "방을 불러오지 못했어요",
                           message: "잠시 뒤 다시 시도해 주세요", actionTitle: "다시 불러오기") {
                    Task { await load() }
                }
            case .loaded(let room):
                if room.items.isEmpty {
                    NoticeCard(symbol: "house", title: "\(friend.name)님의 방이 아직 비어 있어요",
                               message: "방명록으로 응원을 남겨 볼까요?")
                } else {
                    RoomSceneView(items: room.items, dolls: room.dolls, mode: .view, onTapDoll: { id in
                        selectedDoll = room.dolls.first { $0.id == id }
                    }, onTapBoard: { isShowingGuestbook = true })
                    .renderedOnlyWhileVisible()
                    .overlay(alignment: .top) {
                        Text("인형을 탭해 만져 보세요")
                            .font(.footnote)
                            .foregroundStyle(Color.app.inkSecondary)
                            .padding(.top, Spacing.xs)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) { actions }
        .background(Color.app.background)
        .navigationTitle("\(friend.name)의 방")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isShowingGuestbook) {
            GuestbookView(ownerID: friend.id, title: "\(friend.name)의 방명록", canWrite: true)
        }
        .sheet(item: $selectedDoll) { doll in
            NavigationStack {
                SquishyView(doll: doll)
            }
        }
        .task { await load() }
    }

    private var actions: some View {
        let isLiked = store.likedFriendIDs.contains(friend.id)
        return HStack(spacing: Spacing.s) {
            Button {
                Task { await store.toggleLike(friend) }
            } label: {
                Label(isLiked ? "좋아요 취소" : "좋아요", systemImage: isLiked ? "heart.fill" : "heart")
            }
            .buttonStyle(.secondary)
            .sensoryFeedback(.impact(weight: .light), trigger: isLiked)
            Button {
                isShowingGuestbook = true
            } label: {
                Label("방명록", systemImage: "book")
            }
            .buttonStyle(.primary)
        }
        .padding(Spacing.m)
    }

    private func load() async {
        phase = .loading
        do {
            phase = .loaded(try await store.api.room(of: friend))
        } catch {
            phase = .failed
        }
    }
}

#Preview("방 있음") {
    NavigationStack {
        FriendRoomView(friend: Friend(id: "jiyoon", name: "지윤"))
    }
    .environment(FriendStore(api: MockFriendAPI()))
}

#Preview("빈 방") {
    NavigationStack {
        FriendRoomView(friend: Friend(id: "haneul", name: "하늘이"))
    }
    .environment(FriendStore(api: MockFriendAPI()))
}

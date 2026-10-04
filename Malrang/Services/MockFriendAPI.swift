import SwiftUI

/// 서버가 정해지기 전까지 쓰는 메모리 목업. 테스트 이미지는 인물 사진 대신 SF Symbols로 그린다.
final class MockFriendAPI: FriendAPI {
    private var friendList = [
        Friend(id: "jiyoon", name: "지윤"),
        Friend(id: "minseo", name: "민서"),
        Friend(id: "haneul", name: "하늘이"),
    ]
    private let strangers = [Friend(id: "soyul", name: "소율"), Friend(id: "dahye", name: "다혜")]
    private var guestbooks: [String: [GuestbookEntry]] = [
        "me": [
            GuestbookEntry(author: "민서", message: "놀러왔어요! 방 너무 예쁘다"),
            GuestbookEntry(author: "하늘", message: "인형 넘 귀여워 ㅠㅠ"),
            GuestbookEntry(author: "소율", message: "방명록 첫 줄!"),
        ],
        "jiyoon": [GuestbookEntry(author: "민서", message: "침대 위 인형 뭐야 귀여워")],
    ]

    func friends() async throws -> [Friend] {
        try await Task.sleep(for: .milliseconds(400))
        return friendList
    }

    func search(id: String) async throws -> [Friend] {
        try await Task.sleep(for: .milliseconds(300))
        return strangers.filter { $0.id.contains(id.lowercased()) || $0.name.contains(id) }
    }

    func sendRequest(to friend: Friend) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }

    func acceptRequest(from friend: Friend) async throws {
        if !friendList.contains(friend) { friendList.append(friend) }
    }

    func room(of friend: Friend) async throws -> FriendRoom {
        try await Task.sleep(for: .milliseconds(600))
        if friend.id == "haneul" { return FriendRoom(items: [], dolls: []) }
        var items = RoomItem.starterRoom.map(\.state)
        items[0].colorName = "pastelMint"
        let symbols = friend.id == "jiyoon" ? ["cat.fill", "hare.fill"] : ["dog.fill"]
        let dolls = symbols.enumerated().map { index, symbol in
            DollState(id: UUID(), name: "\(friend.name)의 인형", imageData: Self.sampleDollImage(symbol: symbol),
                      filling: .jelly, position: [-0.6 + Float(index) * 0.25, 0.3, -0.45], dance: index == 0 ? .sway : nil)
        }
        return FriendRoom(items: items, dolls: dolls)
    }

    func guestbook(of ownerID: String) async throws -> [GuestbookEntry] {
        try await Task.sleep(for: .milliseconds(300))
        return guestbooks[ownerID] ?? []
    }

    func writeGuestbook(_ message: String, to ownerID: String) async throws -> GuestbookEntry {
        let entry = GuestbookEntry(author: "나", message: message)
        guestbooks[ownerID, default: []].insert(entry, at: 0)
        return entry
    }

    func setLike(_ isLiked: Bool, for friend: Friend) async throws {}

    func notifications() async throws -> [AppNotification] {
        [
            AppNotification(kind: .friendRequest, from: strangers[0], message: "소율님이 친구 요청을 보냈어요"),
            AppNotification(kind: .guestbook, from: friendList[2], message: "하늘이님이 방명록을 남겼어요"),
            AppNotification(kind: .like, from: friendList[1], message: "민서님이 내 방에 좋아요를 눌렀어요"),
            AppNotification(kind: .multiRoomInvite, from: friendList[1], message: "민서님이 멀티 룸에 초대했어요"),
        ]
    }

    static func sampleDollImage(symbol: String) -> Data {
        let art = Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.app.ink)
            .padding(60)
            .background(Color.app.pastelYellow, in: Circle())
            .frame(width: 400, height: 400)
        let renderer = ImageRenderer(content: DollArtwork(shape: .pillow, cutout: Image(uiImage: ImageRenderer(content: art).uiImage ?? UIImage())))
        renderer.proposedSize = ProposedViewSize(width: 400, height: 500)
        return renderer.uiImage?.pngData() ?? Data()
    }
}

@Observable
final class FriendStore {
    let api: any FriendAPI
    var friends: [Friend] = []
    var notifications: [AppNotification] = []
    var hasUnreadNotifications = true
    var likedFriendIDs: Set<String> = []

    init(api: any FriendAPI) {
        self.api = api
    }

    func loadFriends() async throws {
        friends = try await api.friends()
    }

    func loadNotifications() async throws {
        notifications = try await api.notifications()
        hasUnreadNotifications = false
    }

    func toggleLike(_ friend: Friend) async {
        let isLiked = !likedFriendIDs.contains(friend.id)
        if isLiked { likedFriendIDs.insert(friend.id) } else { likedFriendIDs.remove(friend.id) }
        try? await api.setLike(isLiked, for: friend)
    }

    func accept(_ notification: AppNotification) async throws {
        try await api.acceptRequest(from: notification.from)
        notifications.removeAll { $0.id == notification.id }
        try await loadFriends()
    }
}

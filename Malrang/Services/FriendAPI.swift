import Foundation

struct Friend: Identifiable, Hashable {
    let id: String
    let name: String
}

struct FriendRoom {
    var items: [RoomItemState]
    var dolls: [DollState]
}

struct GuestbookEntry: Identifiable {
    let id = UUID()
    let author: String
    let message: String
}

struct AppNotification: Identifiable {
    enum Kind {
        case friendRequest, guestbook, like, multiRoomInvite

        var tag: String {
            switch self {
            case .friendRequest: "요청"
            case .guestbook: "방명록"
            case .like: "좋아요"
            case .multiRoomInvite: "초대"
            }
        }

        var symbol: String {
            switch self {
            case .friendRequest: "person.badge.plus"
            case .guestbook: "pencil.line"
            case .like: "heart.fill"
            case .multiRoomInvite: "house"
            }
        }
    }

    let id = UUID()
    let kind: Kind
    let from: Friend
    let message: String
}

/// 친구 기능 서버. 서버가 정해질 때까지 MockFriendAPI를 쓴다.
protocol FriendAPI {
    func friends() async throws -> [Friend]
    func search(id: String) async throws -> [Friend]
    func sendRequest(to friend: Friend) async throws
    func acceptRequest(from friend: Friend) async throws
    func room(of friend: Friend) async throws -> FriendRoom
    func guestbook(of ownerID: String) async throws -> [GuestbookEntry]
    func writeGuestbook(_ message: String, to ownerID: String) async throws -> GuestbookEntry
    func setLike(_ isLiked: Bool, for friend: Friend) async throws
    func notifications() async throws -> [AppNotification]
}

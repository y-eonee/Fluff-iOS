import CoreGraphics
import Foundation

struct Friend: Identifiable, Hashable {
    let id: String
    let name: String
}

struct FriendRoom {
    var items: [RoomItemState]
    var dolls: [DollState]
}

/// 방명록 메모지. x, y는 보드 안의 위치로, 0(왼쪽·위)에서 1(오른쪽·아래) 사이 값이다.
struct GuestbookEntry: Identifiable {
    let id = UUID()
    let author: String
    let message: String
    var colorName: String
    var x: Double
    var y: Double
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
    /// 연락처 전화번호 해시와 일치하는 가입자
    func friends(matching phoneHashes: [String]) async throws -> [Friend]
    func sendRequest(to friend: Friend) async throws
    func acceptRequest(from friend: Friend) async throws
    func room(of friend: Friend) async throws -> FriendRoom
    func guestbook(of ownerID: String) async throws -> [GuestbookEntry]
    func writeGuestbook(_ message: String, to ownerID: String) async throws -> GuestbookEntry
    func moveGuestbookEntry(_ id: UUID, to point: CGPoint, of ownerID: String) async throws
    func deleteGuestbookEntry(_ id: UUID, of ownerID: String) async throws
    func setLike(_ isLiked: Bool, for friend: Friend) async throws
    func notifications() async throws -> [AppNotification]
}

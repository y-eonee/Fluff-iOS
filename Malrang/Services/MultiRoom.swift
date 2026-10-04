import Combine
import CoreTransferable
import GroupActivities
import UIKit

/// SharePlay로 여는 멀티 룸. 방 주인(host)이 방을 보내고, 누가 인형을 옮기면 모두에게 알린다.
nonisolated struct MultiRoomActivity: GroupActivity, Transferable {
    /// 이 활동을 연 기기의 표시. 받은 쪽에서 내가 방 주인인지 가린다.
    var hostToken: UUID

    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = "말랑 멀티 룸"
        metadata.subtitle = "같은 방에서 인형을 함께 구경해요"
        metadata.type = .generic
        return metadata
    }

    static var transferRepresentation: some TransferRepresentation {
        GroupActivityTransferRepresentation { activity in activity }
    }
}

/// 기기끼리 주고받는 메시지. 사진은 작게 줄여서 보낸다.
nonisolated enum MultiRoomMessage: Codable, Sendable {
    struct Item: Codable, Sendable {
        var id: UUID
        var kind: String
        var x: Float
        var z: Float
        var colorName: String?
        var photo: Data?
        var photoScale: Float
        var photoFlipped: Bool
        var photoTurns: Int
    }

    struct Doll: Codable, Sendable {
        var id: UUID
        var name: String
        var image: Data
        var filling: String
        var position: [Float]
        var dance: String?
    }

    case items([Item])
    case doll(Doll)
    case moveDoll(id: UUID, position: [Float])
    case touchDoll(id: UUID)
    case setDance(id: UUID, dance: String?)
}

/// 누군가 인형을 만졌다는 표시. count가 바뀔 때마다 모든 화면에서 인형이 말랑하게 눌린다.
struct DollTouch: Equatable {
    var dollID: UUID
    var count: Int
}

@Observable
final class MultiRoom {
    let deviceToken = UUID()
    private(set) var session: GroupSession<MultiRoomActivity>?
    private(set) var isHost = false
    private(set) var participantCount = 0
    var items: [RoomItemState] = []
    var dolls: [DollState] = []
    private(set) var lastTouch: DollTouch?
    private var messenger: GroupSessionMessenger?
    private var knownParticipants: Set<Participant> = []
    private var tasks: [Task<Void, Never>] = []

    /// 앱이 켜져 있는 동안 SharePlay 세션이 오기를 기다린다.
    func observeSessions() async {
        for await session in MultiRoomActivity.sessions() {
            join(session)
        }
    }

    func leave() {
        if isHost { session?.end() } else { session?.leave() }
        reset()
    }

    /// 방 주인이 자기 방을 올린다. 이미 들어와 있는 사람에게도 보낸다.
    func publish(items: [RoomItemState], dolls: [DollState]) {
        self.items = items
        self.dolls = dolls
        send(to: .all)
    }

    func moveDoll(_ id: UUID, to position: SIMD3<Float>) {
        broadcast(.moveDoll(id: id, position: [position.x, position.y, position.z]))
    }

    func touchDoll(_ id: UUID) {
        broadcast(.touchDoll(id: id))
    }

    func setDance(_ dance: DanceMove?, for id: UUID) {
        broadcast(.setDance(id: id, dance: dance?.rawValue))
    }

    /// 내 화면에 먼저 반영하고 다른 사람에게 보낸다.
    private func broadcast(_ message: MultiRoomMessage) {
        apply(message)
        Task { try? await messenger?.send(message) }
    }

    private func join(_ session: GroupSession<MultiRoomActivity>) {
        reset()
        self.session = session
        isHost = session.activity.hostToken == deviceToken
        let messenger = GroupSessionMessenger(session: session)
        self.messenger = messenger
        tasks = [
            Task {
                for await (message, _) in messenger.messages(of: MultiRoomMessage.self) {
                    apply(message)
                }
            },
            Task {
                for await participants in session.$activeParticipants.values {
                    participantCount = participants.count
                    // 늦게 들어온 사람에게는 방 주인이 방 전체를 다시 보낸다.
                    let newcomers = participants.subtracting(knownParticipants).subtracting([session.localParticipant])
                    knownParticipants = participants
                    if isHost && !newcomers.isEmpty { send(to: .only(newcomers)) }
                }
            },
            Task {
                for await state in session.$state.values {
                    if case .invalidated = state { reset() }
                }
            },
        ]
        session.join()
    }

    private func send(to participants: Participants) {
        guard let messenger, isHost else { return }
        let items = items.map { item in
            MultiRoomMessage.Item(id: item.id, kind: item.kind.rawValue, x: item.x, z: item.z, colorName: item.colorName,
                                  photo: item.photoData.flatMap { Self.shrink($0, maxSide: 256, keepAlpha: false) },
                                  photoScale: item.photoScale, photoFlipped: item.photoFlipped, photoTurns: item.photoTurns)
        }
        let dolls = dolls.map { doll in
            MultiRoomMessage.Doll(id: doll.id, name: doll.name, image: Self.shrink(doll.imageData, maxSide: 256, keepAlpha: true) ?? Data(),
                                  filling: doll.filling.rawValue, position: [doll.position.x, doll.position.y, doll.position.z],
                                  dance: doll.dance?.rawValue)
        }
        Task {
            try? await messenger.send(MultiRoomMessage.items(items), to: participants)
            // 인형 이미지가 커서 하나씩 나눠 보낸다.
            for doll in dolls {
                try? await messenger.send(MultiRoomMessage.doll(doll), to: participants)
            }
        }
    }

    private func apply(_ message: MultiRoomMessage) {
        switch message {
        case .items(let payload):
            items = payload.compactMap { item in
                guard let kind = FurnitureKind(rawValue: item.kind) else { return nil }
                return RoomItemState(id: item.id, kind: kind, x: item.x, z: item.z, colorName: item.colorName, photoData: item.photo,
                                     photoScale: item.photoScale, photoFlipped: item.photoFlipped, photoTurns: item.photoTurns)
            }
        case .doll(let payload):
            let doll = DollState(id: payload.id, name: payload.name, imageData: payload.image,
                                 filling: Filling(rawValue: payload.filling) ?? .fluffy,
                                 position: Self.vector(payload.position), dance: payload.dance.flatMap(DanceMove.init))
            dolls.removeAll { $0.id == doll.id }
            dolls.append(doll)
        case .moveDoll(let id, let position):
            if let index = dolls.firstIndex(where: { $0.id == id }) {
                dolls[index].position = Self.vector(position)
            }
        case .touchDoll(let id):
            lastTouch = DollTouch(dollID: id, count: (lastTouch?.count ?? 0) + 1)
        case .setDance(let id, let dance):
            if let index = dolls.firstIndex(where: { $0.id == id }) {
                dolls[index].dance = dance.flatMap(DanceMove.init)
            }
        }
    }

    private func reset() {
        tasks.forEach { $0.cancel() }
        tasks = []
        session = nil
        messenger = nil
        isHost = false
        participantCount = 0
        lastTouch = nil
        knownParticipants = []
        items = []
        dolls = []
    }

    private static func vector(_ values: [Float]) -> SIMD3<Float> {
        values.count == 3 ? [values[0], values[1], values[2]] : .zero
    }

    private static func shrink(_ data: Data, maxSide: CGFloat, keepAlpha: Bool) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let small = CutoutService.normalized(image, maxSide: maxSide)
        return keepAlpha ? small.pngData() : small.jpegData(compressionQuality: 0.7)
    }
}

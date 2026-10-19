import Foundation
import SwiftData

@Model
final class RoomItem {
    var id = UUID()
    var kindRaw: String
    var x: Double
    var z: Double
    var colorName: String?
    @Attribute(.externalStorage) var photoData: Data?
    var photoScale = 1.0
    /// 사진을 프레임에 맞추는 방식. 0은 채우기(넘치는 부분은 잘라냄), 1은 맞추기(전체가 보임)
    var photoFit = 0
    var photoFlipped = false
    var photoTurns = 0
    /// 사진을 옮긴 위치(텍스처 좌표)
    var photoOffsetX = 0.0
    var photoOffsetY = 0.0
    /// 가구를 돌려 놓은 각도(라디안)
    var yaw = 0.0
    var createdAt = Date()

    init(kind: FurnitureKind, x: Double = 0, z: Double = 0) {
        self.kindRaw = kind.rawValue
        self.x = x
        self.z = z
    }

    var kind: FurnitureKind { FurnitureKind(rawValue: kindRaw) ?? .bed }

    var state: RoomItemState {
        RoomItemState(id: id, kind: kind, x: Float(x), z: Float(z), colorName: colorName,
                      photoData: photoData, photoScale: Float(photoScale), photoFit: photoFit, photoFlipped: photoFlipped, photoTurns: photoTurns,
                      photoOffsetX: Float(photoOffsetX), photoOffsetY: Float(photoOffsetY), yaw: Float(yaw))
    }

    func restore(_ state: RoomItemState) {
        x = Double(state.x)
        z = Double(state.z)
        colorName = state.colorName
        photoData = state.photoData
        photoScale = Double(state.photoScale)
        photoFit = state.photoFit
        photoFlipped = state.photoFlipped
        photoTurns = state.photoTurns
        photoOffsetX = Double(state.photoOffsetX)
        photoOffsetY = Double(state.photoOffsetY)
        yaw = Double(state.yaw)
    }

    /// 가구가 처음 놓인 그대로인지. 시안 A의 방 일러스트는 이때만 방 모습을 대신 보여준다.
    static func isStarterLayout(_ states: [RoomItemState]) -> Bool {
        let starter = starterRoom.map(\.state)
        guard states.count == starter.count else { return false }
        return starter.allSatisfy { start in
            states.contains {
                $0.kind == start.kind && $0.x == start.x && $0.z == start.z && $0.yaw == start.yaw
                    && $0.colorName == start.colorName && $0.photoData == nil
            }
        }
    }

    /// 처음 실행할 때 놓이는 기본 방
    /// 시안 A의 방 일러스트와 같은 자리에 놓는다. 일러스트 바닥의 네 꼭짓점을 방 바닥(-1...1)에 맞춰 잰 값이다.
    static var starterRoom: [RoomItem] {
        [
            RoomItem(kind: .wall),
            RoomItem(kind: .floor),
            RoomItem(kind: .bed, x: -0.5, z: -0.25),
            RoomItem(kind: .desk, x: 0.45, z: -0.77),
            RoomItem(kind: .chair, x: 0.55, z: 0.05),
            RoomItem(kind: .plant, x: -0.8, z: 0.75),
            RoomItem(kind: .rugRound, x: 0.15, z: 0.25),
            RoomItem(kind: .frame, x: -0.6, z: -0.96),
        ]
    }
}

/// 3D 장면과 친구 목업이 함께 쓰는 가구 값
struct RoomItemState: Identifiable, Equatable {
    let id: UUID
    var kind: FurnitureKind
    var x: Float
    var z: Float
    var colorName: String?
    var photoData: Data?
    var photoScale: Float = 1
    var photoFit = 0
    var photoFlipped = false
    var photoTurns = 0
    var photoOffsetX: Float = 0
    var photoOffsetY: Float = 0
    var yaw: Float = 0
}

@Model
final class DecorPhoto {
    var id = UUID()
    @Attribute(.externalStorage) var data: Data
    var createdAt = Date()

    init(data: Data) {
        self.data = data
    }
}

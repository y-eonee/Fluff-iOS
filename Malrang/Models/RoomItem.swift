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
    var photoFlipped = false
    var photoTurns = 0
    /// 사진을 비스듬히 기울인 각도(라디안)
    var photoAngle = 0.0
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
                      photoData: photoData, photoScale: Float(photoScale), photoFlipped: photoFlipped, photoTurns: photoTurns,
                      photoAngle: Float(photoAngle), yaw: Float(yaw))
    }

    func restore(_ state: RoomItemState) {
        x = Double(state.x)
        z = Double(state.z)
        colorName = state.colorName
        photoData = state.photoData
        photoScale = Double(state.photoScale)
        photoFlipped = state.photoFlipped
        photoTurns = state.photoTurns
        photoAngle = Double(state.photoAngle)
        yaw = Double(state.yaw)
    }

    /// 처음 실행할 때 놓이는 기본 방
    static var starterRoom: [RoomItem] {
        [
            RoomItem(kind: .wall),
            RoomItem(kind: .floor),
            RoomItem(kind: .bed, x: -0.6, z: -0.45),
            RoomItem(kind: .desk, x: 0.5, z: -0.72),
            RoomItem(kind: .shelf, x: -0.83, z: 0.55),
            RoomItem(kind: .rugRound, x: 0.25, z: 0.4),
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
    var photoFlipped = false
    var photoTurns = 0
    var photoAngle: Float = 0
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

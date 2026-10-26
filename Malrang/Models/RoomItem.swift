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
    var isMirrored = false
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
                      photoOffsetX: Float(photoOffsetX), photoOffsetY: Float(photoOffsetY), yaw: Float(yaw), isMirrored: isMirrored)
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
        isMirrored = state.isMirrored
    }

    /// 처음 실행할 때 놓이는 기본 방
    /// 945:2242의 침대 방향, 책상 의자, 앞쪽 라운지 의자를 분리해 배치한다.
    static var starterRoom: [RoomItem] {
        let bed = RoomItem(kind: .bed, x: -0.41, z: 0.18)
        bed.yaw = .pi / 2
        let chair = RoomItem(kind: .chair, x: 0.49, z: 0.01)
        chair.yaw = .pi
        let lounge = RoomItem(kind: .sofa, x: 0.67, z: 0.658)
        lounge.yaw = 1.3
        let rug = RoomItem(kind: .rugRound, x: 0.534, z: 0.734)
        rug.yaw = 0.633
        return [
            RoomItem(kind: .wall),
            RoomItem(kind: .floor),
            bed,
            RoomItem(kind: .desk, x: 0.345, z: -0.38),
            chair,
            lounge,
            RoomItem(kind: .lamp, x: 0.495, z: -0.30),
            rug,
            // 오른쪽 노란색 벽: 액자는 안쪽, 선반은 책상 위쪽.
            RoomItem(kind: .frame, x: -0.72, z: -0.9775),
            RoomItem(kind: .shelf, x: -0.05, z: -0.919),
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
    var isMirrored = false
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

import SwiftData
import SwiftUI
import UIKit

@Model
final class Doll {
    var id = UUID()
    var name: String
    var shapeRaw: String
    var fillingRaw: String
    /// 프리셋과 합성이 끝난 인형 이미지 (친구에게도 이것만 공유)
    @Attribute(.externalStorage) var imageData: Data
    var isPlaced = false
    var x = 0.0
    var y = 0.0
    var z = 0.0
    var danceRaw: String?
    var createdAt = Date()

    init(name: String, shape: DollShape, filling: Filling, imageData: Data) {
        self.name = name
        self.shapeRaw = shape.rawValue
        self.fillingRaw = filling.rawValue
        self.imageData = imageData
    }

    var filling: Filling { Filling(rawValue: fillingRaw) ?? .fluffy }

    var dance: DanceMove? {
        get { danceRaw.flatMap(DanceMove.init) }
        set { danceRaw = newValue?.rawValue }
    }

    var position: SIMD3<Float> {
        get { [Float(x), Float(y), Float(z)] }
        set { (x, y, z) = (Double(newValue.x), Double(newValue.y), Double(newValue.z)) }
    }

    var image: UIImage { UIImage(data: imageData) ?? UIImage() }

    var state: DollState {
        DollState(id: id, name: name, imageData: imageData, filling: filling, position: position, dance: dance)
    }
}

/// 3D 장면과 친구 목업이 함께 쓰는 인형 값
struct DollState: Identifiable, Equatable {
    let id: UUID
    var name: String
    var imageData: Data
    var filling: Filling
    var position: SIMD3<Float>
    var dance: DanceMove?
}

enum DollShape: String, CaseIterable {
    case bear, star, pillow

    var label: String {
        switch self {
        case .bear: "곰인형"
        case .star: "별인형"
        case .pillow: "솜인형"
        }
    }
}

/// 속재료. 만질 때 눌리는 깊이, 튕김, 햅틱, 소리가 달라진다.
enum Filling: String, CaseIterable {
    case fluffy, beads, jelly, foam

    var label: String {
        switch self {
        case .fluffy: "폭신 솜"
        case .beads: "몽글 비즈"
        case .jelly: "쫀득 젤리"
        case .foam: "말랑 폼"
        }
    }

    var pressDepth: CGFloat {
        switch self {
        case .fluffy: 0.22
        case .beads: 0.12
        case .jelly: 0.3
        case .foam: 0.26
        }
    }

    var bounce: Double {
        switch self {
        case .fluffy: 0.3
        case .beads: 0.1
        case .jelly: 0.7
        case .foam: 0.15
        }
    }

    var haptic: SensoryFeedback {
        switch self {
        case .fluffy: .impact(flexibility: .soft, intensity: 0.6)
        case .beads: .impact(flexibility: .rigid, intensity: 0.8)
        case .jelly: .impact(flexibility: .solid, intensity: 1)
        case .foam: .impact(flexibility: .soft, intensity: 0.4)
        }
    }

    /// 임시 효과음. 효과음 파일이 준비되면 Resources의 파일로 바꾼다.
    var systemSoundID: UInt32 {
        switch self {
        case .fluffy: 1104
        case .beads: 1103
        case .jelly: 1105
        case .foam: 1306
        }
    }
}

enum DanceMove: String, CaseIterable {
    case bounce, sway, spin, nod, jump, squish

    var label: String {
        switch self {
        case .bounce: "통통"
        case .sway: "흔들흔들"
        case .spin: "빙글빙글"
        case .nod: "까딱까딱"
        case .jump: "폴짝"
        case .squish: "말랑말랑"
        }
    }

    var symbol: String {
        switch self {
        case .bounce: "arrow.up.and.down"
        case .sway: "metronome"
        case .spin: "arrow.trianglehead.2.clockwise.rotate.90"
        case .nod: "arrow.uturn.down"
        case .jump: "figure.jumprope"
        case .squish: "arrow.down.right.and.arrow.up.left"
        }
    }
}

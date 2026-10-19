import AVFoundation
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

/// 인형 모양. 커스텀(pillow)은 사진 누끼 모양 그대로 시접을 두른 인형이다.
enum DollShape: String, CaseIterable {
    case pillow, bear, star, cat

    var label: String {
        switch self {
        case .pillow: "커스텀"
        case .bear: "곰인형"
        case .star: "별인형"
        case .cat: "고양이"
        }
    }
}

/// 속재료. 만질 때 나는 소리만 달라진다.
enum Filling: String, CaseIterable {
    case fluffy, beads, jelly, foam

    var label: String {
        switch self {
        case .fluffy: "샤베트"
        case .beads: "왁스"
        case .jelly: "슬라임"
        case .foam: "크런치"
        }
    }

    /// Resources의 효과음 파일 이름
    private var soundName: String {
        switch self {
        case .fluffy: "shabet"
        case .beads: "wax"
        case .jelly: "slime"
        case .foam: "crunch"
        }
    }

    func playSound() {
        let player = Self.players[self] ?? Bundle.main.url(forResource: soundName, withExtension: "mp3")
            .flatMap { try? AVAudioPlayer(contentsOf: $0) }
        Self.players[self] = player
        player?.currentTime = 0
        player?.play()
    }

    private static var players: [Filling: AVAudioPlayer] = [:]
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

import Foundation

enum FurnitureCategory: String, CaseIterable {
    case furniture, wallpaper, flooring, rug, decor

    var label: String {
        switch self {
        case .furniture: "가구"
        case .wallpaper: "벽지"
        case .flooring: "바닥재"
        case .rug: "러그"
        case .decor: "장식"
        }
    }
}

enum FurnitureKind: String, CaseIterable {
    case wall, floor
    case bed, desk, shelf, chair, sofa
    case rugRound, rugSquare
    case plant, frame, lamp

    var label: String {
        switch self {
        case .wall: "벽지"
        case .floor: "바닥재"
        case .bed: "침대"
        case .desk: "책상"
        case .shelf: "선반"
        case .chair: "의자"
        case .sofa: "소파"
        case .rugRound: "원형 러그"
        case .rugSquare: "사각 러그"
        case .plant: "화분"
        case .frame: "액자"
        case .lamp: "조명"
        }
    }

    var category: FurnitureCategory {
        switch self {
        case .wall: .wallpaper
        case .floor: .flooring
        case .bed, .desk, .shelf, .chair, .sofa: .furniture
        case .rugRound, .rugSquare: .rug
        case .plant, .frame, .lamp: .decor
        }
    }

    var symbol: String {
        switch self {
        case .wall: "square.split.bottomrightquarter"
        case .floor: "square.grid.3x3"
        case .bed: "bed.double"
        case .desk: "table.furniture"
        case .shelf: "books.vertical"
        case .chair: "chair"
        case .sofa: "sofa"
        case .rugRound: "circle.dashed"
        case .rugSquare: "rectangle.dashed"
        case .plant: "leaf"
        case .frame: "photo.artframe"
        case .lamp: "lamp.floor"
        }
    }

    /// 나중에 넣을 USDZ 파일 이름. Resources에 이 이름의 모델이 있으면 내장 3D 모델 대신 쓴다.
    var assetName: String { rawValue }

    var defaultColorName: String {
        switch self {
        case .wall: "#FFF4F1"
        case .floor: "#FCDCE2"
        case .bed: "#F7B9C8"
        case .sofa: "#F7B9C8"
        case .desk, .shelf: "#E7C3A2"
        case .chair: "#F7B9C8"
        case .frame: "#FFFFFF"
        case .rugRound, .rugSquare: "#F7B9C8"
        case .plant: "#A9D49A"
        case .lamp: "#FFF0B8"
        }
    }

    /// 가로(x), 높이(y), 깊이(z). 단위는 m.
    var size: SIMD3<Float> {
        switch self {
        case .wall: [2, 1.55, 2]
        case .floor: [2, 0.145, 2]
        case .bed: [0.802, 0.577, 0.922]
        case .desk: [0.662, 0.705, 0.441]
        case .shelf: [0.602, 0.217, 0.142]
        case .chair: [0.362, 0.516, 0.362]
        case .sofa: [0.9, 0.6, 0.4]
        case .rugRound: [0.801, 0.01, 0.801]
        case .rugSquare: [0.9, 0.011, 0.6]
        case .plant: [0.208, 0.528, 0.208]
        case .frame: [0.32, 0.351, 0.025]
        case .lamp: [0.113, 0.268, 0.138]
        }
    }

    /// 사진이 붙는 면의 가로 / 세로 비율. 사진을 프레임에 맞출 때 쓴다.
    var photoAspect: Float {
        switch self {
        case .wall: size.z / size.y
        case .floor, .desk, .sofa, .rugRound, .rugSquare: size.x / size.z
        case .bed: 0.44 / 0.922
        case .chair: 1.5
        case .shelf, .plant, .frame, .lamp: size.x / size.y
        }
    }

    /// 인형을 올려둘 수 있는 윗면 높이. nil이면 올려둘 수 없다.
    var seatHeight: Float? {
        switch self {
        case .bed: 0.299
        case .desk: 0.437
        case .shelf: nil
        case .chair: 0.227
        case .sofa: 0.32
        case .rugRound, .rugSquare: 0.01
        default: nil
        }
    }

    var isMovable: Bool { self != .wall && self != .floor }

    /// 벽에 걸리는 가구(액자·선반). 바닥이 아니라 벽면을 따라 옮긴다.
    var hangsOnWall: Bool { self == .frame || self == .shelf }

    /// 벽에 걸릴 때 아래쪽 끝의 높이
    var hangingHeight: Float { self == .shelf ? 1.038 : 0.866 }

    /// 러그는 다른 가구와 겹쳐 놓을 수 있다.
    var blocksFloor: Bool { isMovable && category != .rug && !hangsOnWall }
}

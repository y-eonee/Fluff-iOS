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

    /// 나중에 넣을 USDZ 파일 이름. Resources에 이 이름의 모델이 있으면 임시 도형 대신 쓴다.
    var assetName: String { rawValue }

    var defaultColorName: String {
        switch self {
        case .wall: "background"
        case .floor: "pastelYellow"
        case .bed, .sofa: "pastelSky"
        case .desk, .shelf, .chair, .frame: "surface"
        case .rugRound, .rugSquare: "brandAccent"
        case .plant: "pastelMint"
        case .lamp: "pastelYellow"
        }
    }

    /// 가로(x), 높이(y), 깊이(z). 단위는 m.
    var size: SIMD3<Float> {
        switch self {
        case .wall, .floor: [2, 1.4, 2]
        case .bed: [0.7, 0.45, 1.0]
        case .desk: [0.7, 0.55, 0.45]
        case .shelf: [0.3, 0.9, 0.6]
        case .chair: [0.35, 0.7, 0.35]
        case .sofa: [0.9, 0.6, 0.4]
        case .rugRound: [0.9, 0.01, 0.9]
        case .rugSquare: [0.9, 0.01, 0.6]
        case .plant: [0.25, 0.5, 0.25]
        case .frame: [0.3, 0.4, 0.06]
        case .lamp: [0.25, 0.9, 0.25]
        }
    }

    /// 인형을 올려둘 수 있는 윗면 높이. nil이면 올려둘 수 없다.
    var seatHeight: Float? {
        switch self {
        case .bed: 0.3
        case .desk: 0.55
        case .shelf: 0.9
        case .chair, .sofa: 0.32
        case .rugRound, .rugSquare: 0.01
        default: nil
        }
    }

    var isMovable: Bool { self != .wall && self != .floor }

    /// 벽에 걸리는 가구(액자). 바닥이 아니라 벽면을 따라 옮긴다.
    var hangsOnWall: Bool { self == .frame }

    /// 벽에 걸릴 때 아래쪽 끝의 높이
    static let hangHeight: Float = 0.7

    /// 러그는 다른 가구와 겹쳐 놓을 수 있다.
    var blocksFloor: Bool { isMovable && category != .rug && !hangsOnWall }
}

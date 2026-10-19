import Foundation

/// B안 원목 가구. A안과 같은 바닥 크기와 앉는 높이를 써서 저장된 배치를 공유한다.
enum FurnitureModelB {
    static func visualSize(for kind: FurnitureKind) -> SIMD3<Float> {
        var size = kind.size
        if kind == .chair { size.y = 0.227 }
        return size
    }
    static func photoAspect(for kind: FurnitureKind) -> Float {
        guard let surface = parts(for: kind).first(where: \.photo) else { return kind.photoAspect }
        switch kind {
        case .floor, .bed, .desk, .sofa, .chair, .rugRound, .rugSquare: return surface.size.x / surface.size.z
        case .frame: return surface.size.x / surface.size.y
        default: return kind.photoAspect
        }
    }
    static func defaultColor(for kind: FurnitureKind) -> String {
        switch kind {
        case .wall: "#FFF9DB"
        case .floor: "#E6AF73"
        case .bed, .desk, .lamp, .plant: "#F5A45D"
        case .shelf: "#DCA06A"
        case .chair, .sofa: "#FFF4D8"
        case .rugRound, .rugSquare: "#FFF7D7"
        case .frame: "#F7CA8A"
        }
    }
    enum Shape: String, Codable { case box, sphere, cylinder, cone }
    struct Part: Codable {
        var shape = Shape.box
        var size: SIMD3<Float>
        var position: SIMD3<Float>
        var color: String
        var custom = false
        var photo = false
        var pattern = false
        var glow = false
        var radius: Float = 0.012
    }

    static func parts(for kind: FurnitureKind) -> [Part] {
        let s = kind.size
        let wood = "#DCA06A", cream = "#FFF4D8", orange = "#F5A45D", green = "#A7C67B"
        var parts: [Part] = []
        func add(_ shape: Shape, _ size: SIMD3<Float>, _ point: SIMD3<Float>, _ color: String,
                 custom: Bool = false, photo: Bool = false, pattern: Bool = false, glow: Bool = false, radius: Float = 0.012) {
            parts.append(Part(shape: shape, size: size, position: point, color: color,
                              custom: custom, photo: photo, pattern: pattern, glow: glow, radius: radius))
        }
        func legs(_ width: Float, _ depth: Float, _ height: Float, x: Float = 0) {
            for dx: Float in [-1, 1] {
                for dz: Float in [-1, 1] {
                    add(.box, [0.038, height, 0.038], [x + dx * (width / 2 - 0.035), height / 2, dz * (depth / 2 - 0.035)], wood)
                }
            }
        }
        func lamp(_ origin: SIMD3<Float>, scale: Float = 1) {
            add(.cylinder, [0.09, 0.014, 0.09] * scale, origin + [0, 0.007 * scale, 0], orange)
            add(.cylinder, [0.015, 0.13, 0.015] * scale, origin + [0, 0.07 * scale, 0], wood)
            add(.cone, [0.113, 0.14, 0.113] * scale, origin + [0, 0.198 * scale, 0], "#FFFBE8", custom: kind == .lamp, photo: kind == .lamp, glow: true)
        }
        switch kind {
        case .wall:
            add(.box, [0.04, s.y, 2], [-1.02, s.y / 2, 0], "#FFF9DB", custom: true, photo: true)
            add(.box, [2, s.y, 0.04], [0, s.y / 2, -1.02], "#F2D9A5", custom: true, photo: true)
            for y: Float in [0.035, s.y] {
                add(.box, [0.055, 0.05, 2.06], [-1.02, y, 0], "#B8824D")
                add(.box, [2.06, 0.05, 0.055], [0, y, -1.02], "#B8824D")
            }
        case .floor:
            add(.box, [2, s.y, 2], [0, -s.y / 2 - 0.006, 0], "#B98350", custom: true)
            add(.box, [1.99, 0.003, 1.99], [0, -0.002, 0], wood, custom: true, photo: true)
            for row in 0..<12 {
                let joint: Float = row.isMultiple(of: 2) ? -0.3 : 0.35
                for (col, ends) in [(-1 as Float, joint), (joint, 1 as Float)].enumerated() {
                    add(.box, [ends.1 - ends.0 - 0.006, 0.006, 0.161], [(ends.0 + ends.1) / 2, -0.001, -0.913 + Float(row) * 0.166],
                        ["#E6AF73", "#EFB77C", "#DFA36C"][(row + col) % 3], custom: true, pattern: true, radius: 0.001)
                }
            }
        case .bed:
            let center: Float = -0.095
            legs(0.6, 0.89, 0.13, x: center)
            add(.box, [0.61, 0.13, 0.9], [center, 0.18, 0], wood, custom: true)
            add(.box, [0.61, 0.41, 0.045], [center, 0.32, -0.43], orange)
            for x: Float in [-0.376, 0.187] {
                add(.cylinder, [0.032, 0.51, 0.032], [x, 0.27, -0.43], wood)
                add(.sphere, [0.046, 0.046, 0.046], [x, 0.553, -0.43], orange)
            }
            add(.box, [0.58, 0.08, 0.84], [center, 0.247, 0.01], cream, radius: 0.025)
            add(.box, [0.58, 0.014, 0.57], [center, 0.290, 0.144], orange, custom: true, photo: true)
            for row in 0..<9 {
                for col in 0..<9 where (row + col).isMultiple(of: 2) {
                    add(.box, [0.064, 0.002, 0.063], [center - 0.258 + Float(col) * 0.0645, 0.298, -0.109 + Float(row) * 0.0633], cream, pattern: true, radius: 0.001)
                }
            }
            for x: Float in [-0.245, 0.055] {
                add(.box, [0.255, 0.055, 0.16], [x, 0.313, -0.302], x < 0 ? "#FFFDF2" : "#FFF1BE", radius: 0.026)
            }
            add(.box, [0.195, 0.28, 0.235], [0.30, 0.14, -0.32], wood)
            add(.box, [0.20, 0.025, 0.24], [0.30, 0.292, -0.32], cream)
            add(.box, [0.17, 0.11, 0.012], [0.30, 0.20, -0.196], orange)
            add(.sphere, [0.018, 0.018, 0.01], [0.30, 0.20, -0.186], "#B77D48")
            lamp([0.30, 0.305, -0.32], scale: 0.72)
        case .desk:
            legs(s.x, s.z, 0.404)
            add(.box, [s.x, 0.036, s.z], [0, 0.419, 0], orange, custom: true, photo: true)
            add(.box, [0.15, 0.012, 0.105], [-0.12, 0.446, -0.025], "#F5A15C", pattern: true)
            lamp([0.20, 0.437, -0.04])
        case .shelf:
            add(.box, [s.x, 0.027, s.z], [0, 0.014, 0], wood, custom: true, photo: true)
            for (i, color) in ["#F0914E", "#FFD5AA", "#EBC598"].enumerated() {
                add(.box, [0.042, 0.16 - Float(i) * 0.012, 0.075], [-0.17 + Float(i) * 0.048, 0.107 - Float(i) * 0.006, -0.01], color)
            }
            add(.cylinder, [0.08, 0.06, 0.08], [0.20, 0.057, 0], orange)
            add(.sphere, [0.10, 0.10, 0.10], [0.20, 0.13, 0], green)
        case .chair:
            add(.cylinder, [0.30, 0.17, 0.30], [0, 0.085, 0], "#ECC297", custom: true)
            add(.cylinder, [0.34, 0.057, 0.34], [0, 0.1985, 0], cream, custom: true, photo: true)
        case .sofa:
            legs(s.x, s.z, 0.08)
            add(.box, [s.x, 0.17, s.z], [0, 0.16, 0], wood)
            add(.box, [s.x - 0.12, 0.075, s.z - 0.025], [0, 0.2825, 0.01], cream, custom: true, photo: true, radius: 0.03)
            add(.box, [s.x, 0.34, 0.07], [0, 0.42, -0.165], "#F2D3AB", custom: true, radius: 0.03)
            for x: Float in [-0.415, 0.415] { add(.box, [0.07, 0.28, s.z], [x, 0.31, 0], "#F2D3AB", custom: true, radius: 0.03) }
            add(.box, [0.18, 0.17, 0.06], [-0.22, 0.40, -0.07], orange, radius: 0.025)
            add(.box, [0.18, 0.17, 0.06], [0.22, 0.40, -0.07], cream, radius: 0.025)
        case .rugRound:
            add(.cylinder, [s.x, 0.006, s.z], [0, 0.003, 0], "#F7DFAD", custom: true)
            add(.cylinder, [s.x - 0.12, 0.004, s.z - 0.12], [0, 0.008, 0], "#FFF7D7", custom: true, photo: true)
        case .rugSquare:
            add(.box, [s.x, 0.009, s.z], [0, 0.0045, 0], "#F7DFAD", custom: true, radius: 0.005)
            add(.box, [s.x - 0.09, 0.002, s.z - 0.09], [0, 0.010, 0], "#FFF7D7", custom: true, photo: true)
        case .plant:
            add(.cylinder, [0.15, 0.17, 0.15], [0, 0.085, 0], orange, custom: true, photo: true)
            add(.sphere, [0.19, 0.23, 0.18], [0, 0.28, 0], green)
            add(.sphere, [0.15, 0.17, 0.15], [-0.025, 0.41, -0.01], "#B9D58B")
            add(.sphere, [0.14, 0.17, 0.13], [0.03, 0.26, 0.038], "#A8CA79")
        case .frame:
            for (x, color) in [(Float(-0.087), "#F7CA8A"), (Float(0.087), "#B6C47F")] {
                add(.box, [0.13, 0.20, 0.018], [x, 0.19, 0], cream)
                add(.box, [0.104, 0.172, 0.007], [x, 0.19, 0.010], color, custom: true, photo: true)
            }
        case .lamp: lamp(.zero)
        }
        if kind == .bed {
            // 피그마처럼 머리판이 왼쪽 벽을 향하도록 배치하되 공용 배치 영역 안에 맞춘다.
            for index in parts.indices {
                let point = parts[index].position, size = parts[index].size
                parts[index].position = [point.z * s.x / s.z, point.y, -point.x * s.z / s.x]
                parts[index].size = [size.z * s.x / s.z, size.y, size.x * s.z / s.x]
            }
        }
        return parts
    }
}

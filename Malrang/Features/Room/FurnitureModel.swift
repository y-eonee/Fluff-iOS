import UIKit

/// 장면과 목록 미리보기가 함께 쓰는 입체 가구. 원점은 바닥 중심이다.
enum FurnitureModel {
    enum Shape { case box, sphere, cylinder }
    enum Finish { case main, plain, wood, cream, pink, blue, green, yellow }
    struct Part {
        var shape = Shape.box
        var size: SIMD3<Float>
        var position: SIMD3<Float>
        var finish: Finish
        var tilt: Float = 0
        var isPattern = false
    }

    static func color(for finish: Finish, kind: FurnitureKind) -> UIColor {
        switch finish {
        case .main, .plain: Palette.uiColor(kind.defaultColorName)
        case .wood: Palette.uiColor("#C59B79")
        case .cream: Palette.uiColor("#FFF6EE")
        case .pink: Palette.uiColor("#F7B9C8")
        case .blue: Palette.uiColor("#A6C5E2")
        case .green: Palette.uiColor("#9FC58B")
        case .yellow: Palette.uiColor("#FDE9A0")
        }
    }

    static func parts(for kind: FurnitureKind) -> [Part] {
        let s = kind.size
        var parts: [Part] = []
        func box(_ size: SIMD3<Float>, _ position: SIMD3<Float>, _ finish: Finish) {
            parts.append(Part(size: size, position: position, finish: finish))
        }
        func round(_ shape: Shape, _ size: SIMD3<Float>, _ position: SIMD3<Float>, _ finish: Finish) {
            parts.append(Part(shape: shape, size: size, position: position, finish: finish))
        }
        func legs(height: Float, inset: Float = 0.04) {
            for x: Float in [-1, 1] {
                for z: Float in [-1, 1] {
                    box([0.045, height, 0.045], [x * (s.x / 2 - inset), height / 2, z * (s.z / 2 - inset)], .wood)
                }
            }
        }
        func checks(width: Float, depth: Float, y: Float, z: Float = 0, count: Int = 6) {
            for row in 0..<count {
                for col in 0..<count where (row + col).isMultiple(of: 2) {
                    box([width / Float(count), 0.002, depth / Float(count)],
                        [-width / 2 + (Float(col) + 0.5) * width / Float(count), y,
                         z - depth / 2 + (Float(row) + 0.5) * depth / Float(count)], .cream)
                    parts[parts.count - 1].isPattern = true
                }
            }
        }
        switch kind {
        case .wall:
            box([0.04, s.y, s.z], [-1.02, s.y / 2, 0], .main)
            box([s.x, s.y, 0.04], [0, s.y / 2, -1.02], .main)
            box([0.025, 0.06, s.z], [-0.99, 0.03, 0], .wood)
            box([s.x, 0.06, 0.025], [0, 0.03, -0.99], .wood)
            for index in 0..<10 {
                box([0.003, s.y - 0.06, 0.1], [-0.998, 0.73, -0.9 + Float(index) * 0.2], .pink)
                parts[parts.count - 1].isPattern = true
            }
            for row in 0..<7 {
                for col in 0..<10 {
                    box([0.2, 0.2, 0.003], [-0.9 + Float(col) * 0.2, 0.1 + Float(row) * 0.2, -0.998], .yellow)
                    parts[parts.count - 1].isPattern = true
                    if (row + col).isMultiple(of: 2) {
                        box([0.2, 0.2, 0.002], [-0.9 + Float(col) * 0.2, 0.1 + Float(row) * 0.2, -0.995], .cream)
                        parts[parts.count - 1].isPattern = true
                    }
                }
            }
            box([0.025, 0.62, 0.62], [-0.976, 0.91, -0.22], .wood)
            box([0.008, 0.55, 0.55], [-0.959, 0.91, -0.22], .blue)
            box([0.008, 0.2, 0.55], [-0.953, 0.735, -0.22], .green)
            box([0.012, 0.025, 0.58], [-0.947, 0.91, -0.22], .cream)
            box([0.012, 0.58, 0.025], [-0.947, 0.91, -0.22], .cream)
        case .floor:
            box([s.x, 0.04, s.z], [0, -0.02, 0], .main)
            checks(width: s.x, depth: s.z, y: 0.001, count: 8)
        case .bed:
            legs(height: 0.1)
            box([s.x, 0.13, s.z], [0, 0.145, 0], .wood)
            box([s.x, s.y, 0.055], [0, s.y / 2, -s.z / 2 + 0.028], .wood)
            box([s.x - 0.025, 0.09, s.z - 0.065], [0, 0.255, 0.02], .cream)
            box([s.x - 0.03, 0.018, 0.64], [0, 0.292, 0.16], .main)
            checks(width: s.x - 0.035, depth: 0.64, y: 0.302, z: 0.16)
            box([s.x - 0.15, 0.06, 0.19], [0, 0.33, -0.29], .cream)
        case .desk:
            legs(height: s.y - 0.045)
            box([s.x, 0.045, s.z], [0, s.y - 0.0225, 0], .main)
            box([0.23, 0.12, s.z - 0.06], [-0.19, s.y - 0.105, 0], .wood)
            box([0.08, 0.018, 0.018], [-0.19, s.y - 0.105, s.z / 2 - 0.02], .cream)
        case .shelf:
            for x: Float in [-1, 1] {
                box([0.025, s.y, s.z], [x * (s.x / 2 - 0.0125), s.y / 2, 0], .wood)
            }
            box([s.x, s.y, 0.02], [0, s.y / 2, -s.z / 2 + 0.01], .plain)
            for y: Float in [0.025, 0.31, 0.6, 0.885] {
                box([s.x, 0.025, s.z], [0, y, 0], .main)
            }
            for (i, finish) in [Finish.pink, .blue, .yellow].enumerated() {
                box([0.045, 0.17 + Float(i) * 0.015, 0.18], [-0.07 + Float(i) * 0.06, 0.41, 0.09], finish)
            }
            box([0.18, 0.14, 0.24], [0, 0.68, 0.09], .pink)
        case .chair:
            legs(height: 0.29)
            box([s.x, 0.06, s.z], [0, 0.25, 0], .main)
            box([s.x, 0.4, 0.045], [0, 0.5, -s.z / 2 + 0.023], .wood)
            box([s.x - 0.045, 0.29, 0.03], [0, 0.51, -s.z / 2 + 0.05], .plain)
            box([0.24, 0.045, 0.23], [0, 0.3, 0.02], .blue)
        case .sofa:
            legs(height: 0.09, inset: 0.07)
            box([s.x, 0.18, s.z], [0, 0.18, 0], .wood)
            box([s.x - 0.15, 0.08, s.z - 0.08], [0, 0.28, 0.025], .main)
            box([s.x, 0.35, 0.075], [0, 0.425, -s.z / 2 + 0.038], .plain)
            for x: Float in [-1, 1] {
                box([0.075, 0.28, s.z], [x * (s.x / 2 - 0.038), 0.29, 0], .plain)
            }
            box([0.18, 0.17, 0.075], [-0.23, 0.41, -0.04], .pink)
            box([0.18, 0.17, 0.075], [0.23, 0.41, -0.04], .cream)
        case .rugRound:
            round(.cylinder, [s.x, 0.007, s.z], [0, 0.0035, 0], .cream)
            round(.cylinder, [s.x - 0.045, 0.003, s.z - 0.045], [0, 0.0085, 0], .main)
            // 체크를 원 안에만 넣어 러그 가장자리 밖으로 나오지 않게 한다.
            for x in -3...3 {
                for z in -3...3 where (x + z).isMultiple(of: 2) && x * x + z * z <= 8 {
                    box([0.09, 0.001, 0.09], [Float(x) * 0.1, 0.010, Float(z) * 0.1], .cream)
                    parts[parts.count - 1].isPattern = true
                }
            }
        case .rugSquare:
            box(s, [0, 0.005, 0], .main)
            checks(width: s.x - 0.035, depth: s.z - 0.035, y: 0.0105)
        case .plant:
            round(.cylinder, [0.17, 0.16, 0.17], [0, 0.08, 0], .wood)
            round(.cylinder, [0.19, 0.025, 0.19], [0, 0.155, 0], .cream)
            round(.cylinder, [0.025, 0.22, 0.025], [0, 0.26, 0], .wood)
            round(.sphere, [0.14, 0.2, 0.12], [-0.055, 0.3, 0], .green)
            round(.sphere, [0.14, 0.19, 0.13], [0.055, 0.32, 0.015], .green)
            round(.sphere, [0.14, 0.19, 0.14], [0, 0.405, -0.02], .green)
        case .frame:
            box(s, [0, s.y / 2, 0], .wood)
            box([s.x - 0.045, s.y - 0.045, 0.008], [0, s.y / 2, s.z / 2], .main)
            round(.sphere, [0.08, 0.08, 0.005], [-0.035, 0.23, s.z / 2 + 0.005], .pink)
            parts[parts.count - 1].isPattern = true
            round(.sphere, [0.08, 0.08, 0.005], [0.02, 0.23, s.z / 2 + 0.005], .pink)
            parts[parts.count - 1].isPattern = true
            box([0.075, 0.075, 0.005], [-0.0075, 0.193, s.z / 2 + 0.005], .pink)
            parts[parts.count - 1].tilt = .pi / 4
            parts[parts.count - 1].isPattern = true
        case .lamp:
            round(.cylinder, [0.21, 0.025, 0.21], [0, 0.0125, 0], .wood)
            round(.cylinder, [0.022, 0.7, 0.022], [0, 0.37, 0], .wood)
            round(.cylinder, [0.25, 0.16, 0.25], [0, 0.79, 0], .main)
            round(.sphere, [0.16, 0.12, 0.16], [0, 0.84, 0], .plain)
        }
        return parts
    }
}

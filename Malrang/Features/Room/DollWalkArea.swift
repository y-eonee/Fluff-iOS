import Foundation
import simd

/// Walking uses inset support surfaces and inflated obstacles, including rotated furniture.
nonisolated struct DollWalkArea {
    struct Box {
        var center: SIMD2<Float>
        var half: SIMD2<Float>
        var yaw: Float = 0

        func local(_ point: SIMD2<Float>) -> SIMD2<Float> {
            let p = point - center
            return [cos(yaw) * p.x - sin(yaw) * p.y, sin(yaw) * p.x + cos(yaw) * p.y]
        }

        func contains(_ point: SIMD2<Float>, margin: Float) -> Bool {
            let p = abs(local(point)), extent = half + SIMD2(repeating: margin)
            return p.x <= extent.x && p.y <= extent.y
        }
    }

    var boundary: Box
    var obstacles: [Box]
    var radius: Float = 0.14

    func contains(_ point: SIMD2<Float>) -> Bool {
        boundary.contains(point, margin: -radius)
            && !obstacles.contains { $0.contains(point, margin: radius) }
    }

    func canTravel(from start: SIMD2<Float>, to end: SIMD2<Float>) -> Bool {
        guard contains(start), contains(end) else { return false }
        // A slab intersection checks the whole segment, even a tiny corner crossing.
        return !obstacles.contains { box in
            let a = box.local(start), direction = box.local(end) - a
            let extent = box.half + SIMD2(repeating: radius)
            var low: Float = 0, high: Float = 1
            for axis in 0..<2 {
                if abs(direction[axis]) < 0.000001 {
                    if abs(a[axis]) > extent[axis] { return false }
                } else {
                    let t1 = (-extent[axis] - a[axis]) / direction[axis]
                    let t2 = (extent[axis] - a[axis]) / direction[axis]
                    low = max(low, min(t1, t2)); high = min(high, max(t1, t2))
                    if low > high { return false }
                }
            }
            return true
        }
    }
}

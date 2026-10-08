import Foundation
import simd

/// 방 바닥(x, z: -1...1) 위의 배치 규칙
enum RoomLayout {
    static let half: Float = 1
    static let grid: Float = 0.1

    static func footprint(_ item: RoomItemState) -> (min: SIMD2<Float>, max: SIMD2<Float>) {
        let half = SIMD2(item.kind.size.x, item.kind.size.z) / 2
        // 돌려 놓은 가구는 돌린 모양을 감싸는 네모로 본다.
        let size = SIMD2(abs(cos(item.yaw)) * half.x + abs(sin(item.yaw)) * half.y,
                         abs(sin(item.yaw)) * half.x + abs(cos(item.yaw)) * half.y)
        let center = SIMD2(item.x, item.z)
        return (center - size, center + size)
    }

    static func overlaps(_ item: RoomItemState, in items: [RoomItemState]) -> Bool {
        guard item.kind.blocksFloor else { return false }
        let a = footprint(item)
        return items.contains { other in
            guard other.id != item.id, other.kind.blocksFloor else { return false }
            let b = footprint(other)
            return a.min.x < b.max.x && b.min.x < a.max.x && a.min.y < b.max.y && b.min.y < a.max.y
        }
    }

    /// 가구가 방 밖으로 나가지 않게 중심 위치를 제한하고 격자에 맞춘다.
    static func snapped(_ point: SIMD2<Float>, for kind: FurnitureKind) -> SIMD2<Float> {
        let limit = SIMD2(half - kind.size.x / 2, half - kind.size.z / 2)
        let snapped = (point / grid).rounded(.toNearestOrAwayFromZero) * grid
        return simd_clamp(snapped, -limit, limit)
    }

    static func clampedToFloor(_ point: SIMD2<Float>) -> SIMD2<Float> {
        simd_clamp(point, SIMD2(repeating: -half + 0.1), SIMD2(repeating: half - 0.1))
    }

    /// 그 자리에서 인형이 올라설 높이와, 올라선 가구
    static func seat(at point: SIMD2<Float>, in items: [RoomItemState]) -> (height: Float, item: RoomItemState?) {
        let candidates = items.filter { item in
            guard item.kind.seatHeight != nil else { return false }
            let box = footprint(item)
            return point.x >= box.min.x && point.x <= box.max.x && point.y >= box.min.y && point.y <= box.max.y
        }
        let top = candidates.max { ($0.kind.seatHeight ?? 0) < ($1.kind.seatHeight ?? 0) }
        return (top?.kind.seatHeight ?? 0, top)
    }

    /// 새 가구를 겹치지 않게 놓을 첫 빈자리
    static func freeSpot(for kind: FurnitureKind, among items: [RoomItemState]) -> SIMD2<Float>? {
        let steps = stride(from: -half, through: half, by: grid * 2)
        for z in steps.reversed() {
            for x in steps {
                let point = snapped([x, z], for: kind)
                let candidate = RoomItemState(id: UUID(), kind: kind, x: point.x, z: point.y)
                if !overlaps(candidate, in: items) { return point }
            }
        }
        return nil
    }

    /// 새 인형을 둘 기본 위치: 가구와 다른 인형에서 떨어진 앞쪽 바닥의 빈 곳
    static func dollSpot(avoiding items: [RoomItemState], dolls: [SIMD3<Float>]) -> SIMD3<Float> {
        for z in stride(from: Float(0.75), through: -0.5, by: -0.25) {
            for x in stride(from: Float(-0.5), through: 0.5, by: 0.25) {
                let point = SIMD2(x, z)
                let isBlocked = items.contains { item in
                    guard item.kind.blocksFloor else { return false }
                    let box = footprint(item)
                    return point.x > box.min.x - 0.1 && point.x < box.max.x + 0.1 && point.y > box.min.y - 0.1 && point.y < box.max.y + 0.1
                }
                let isCrowded = dolls.contains { simd_distance(SIMD2($0.x, $0.z), point) < 0.25 }
                if !isBlocked && !isCrowded { return [x, 0, z] }
            }
        }
        return [0, 0, 0.75]
    }
}

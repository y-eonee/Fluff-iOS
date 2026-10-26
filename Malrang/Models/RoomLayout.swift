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

    /// 조명 바닥 전체가 책상 상판 안에 있을 때만 책상 위에 올린다.
    static func lampSupport(for item: RoomItemState, in items: [RoomItemState]) -> RoomItemState? {
        guard item.kind == .lamp else { return nil }
        return items.first { desk in
            guard desk.kind == .desk else { return false }
            let relative = SIMD2(item.x - desk.x, item.z - desk.z)
            let center = SIMD2(cos(desk.yaw) * relative.x - sin(desk.yaw) * relative.y,
                               sin(desk.yaw) * relative.x + cos(desk.yaw) * relative.y)
            let angle = item.yaw - desk.yaw
            let half = SIMD2(item.kind.size.x, item.kind.size.z) / 2
            let extent = SIMD2(abs(cos(angle)) * half.x + abs(sin(angle)) * half.y,
                               abs(sin(angle)) * half.x + abs(cos(angle)) * half.y)
            return abs(center.x) + extent.x <= desk.kind.size.x / 2 + 0.001
                && abs(center.y) + extent.y <= desk.kind.size.z / 2 + 0.001
        }
    }

    static func furnitureHeight(_ item: RoomItemState, in items: [RoomItemState]) -> Float {
        lampSupport(for: item, in: items)?.kind.seatHeight ?? 0
    }

    /// 상판 아래의 빈 공간까지 막지 않도록 실제 가구 부위별로 검사한다.
    private static func collisionParts(_ kind: FurnitureKind) -> [(size: SIMD3<Float>, center: SIMD3<Float>)] {
        let s = kind.size
        switch kind {
        case .desk:
            let top = kind.seatHeight ?? 0.47
            var parts: [(SIMD3<Float>, SIMD3<Float>)] = [([s.x, 0.075, s.z], [0, top - 0.0375, 0])]
            for x: Float in [-s.x * 0.39, s.x * 0.39] {
                for z: Float in [-s.z * 0.32, s.z * 0.32] {
                    parts.append(([0.064, top - 0.06, 0.064], [x, (top - 0.06) / 2, z]))
                }
            }
            return parts
        case .bed:
            return [([s.x, 0.39, s.z], [0, 0.195, 0]),
                    ([s.x, 0.55, 0.10], [0, 0.395, -s.z / 2 + 0.04]),
                    ([s.x * 0.83, 0.15, 0.26], [0, 0.43, -s.z * 0.30]),
                    ([s.x * 1.02, 0.10, 0.20], [0, 0.375, -s.z * 0.14])]
        case .chair:
            return [([s.x, 0.227, s.z * 0.94], [0, 0.1135, 0]),
                    ([s.x * 0.95, s.y - 0.227, 0.085], [0, (s.y + 0.227) / 2, -s.z * 0.36])]
        default:
            return [(s, [0, s.y / 2, 0])]
        }
    }

    private static func collisionBounds(_ item: RoomItemState, in items: [RoomItemState]) -> [(min: SIMD3<Float>, max: SIMD3<Float>)] {
        collisionParts(item.kind).map { part in
            let c = cos(item.yaw), s = sin(item.yaw)
            let half = part.size / 2
            let extent = SIMD3(abs(c) * half.x + abs(s) * half.z, half.y, abs(s) * half.x + abs(c) * half.z)
            let center = SIMD3(item.x + c * part.center.x + s * part.center.z,
                               furnitureHeight(item, in: items) + part.center.y,
                               item.z - s * part.center.x + c * part.center.z)
            return (center - extent, center + extent)
        }
    }

    static func overlaps(_ item: RoomItemState, in items: [RoomItemState]) -> Bool {
        guard item.kind.blocksFloor else { return false }
        let parts = collisionBounds(item, in: items)
        return items.contains { other in
            guard other.id != item.id, other.kind.blocksFloor else { return false }
            if lampSupport(for: item, in: items)?.id == other.id
                || lampSupport(for: other, in: items)?.id == item.id { return false }
            return collisionBounds(other, in: items).contains { b in
                parts.contains { a in
                    a.min.x < b.max.x && b.min.x < a.max.x
                        && a.min.y < b.max.y && b.min.y < a.max.y
                        && a.min.z < b.max.z && b.min.z < a.max.z
                }
            }
        }
    }

    /// 가구가 방 밖으로 나가지 않게 중심 위치를 제한하고 격자에 맞춘다. 돌려 놓은 가구는 돌린 크기로 계산한다.
    /// 벽에 거는 가구는 가까운 벽면에 붙인다.
    static func snapped(_ point: SIMD2<Float>, for kind: FurnitureKind, yaw: Float = 0) -> SIMD2<Float> {
        if kind.hangsOnWall {
            let width = abs(cos(yaw)) * kind.size.x + abs(sin(yaw)) * kind.size.y
            return wallSpot(near: point, width: width, depth: kind.size.z)
        }
        let size = SIMD2(abs(cos(yaw)) * kind.size.x + abs(sin(yaw)) * kind.size.z,
                         abs(sin(yaw)) * kind.size.x + abs(cos(yaw)) * kind.size.z)
        let limit = SIMD2(half - size.x / 2, half - size.y / 2)
        let snapped = (point / grid).rounded(.toNearestOrAwayFromZero) * grid
        // 러그는 벽을 넘지 않되, 앞쪽으로 이어지는 열린 바닥까지 놓을 수 있다.
        let front = kind.category == .rug ? SIMD2<Float>(repeating: 0.3) : .zero
        return simd_clamp(snapped, -limit, limit + front)
    }

    enum Wall {
        case left, back

        /// 벽에서 나오는 쪽으로 가구 앞면을 돌리는 각도
        var yaw: Float { self == .left ? .pi / 2 : 0 }
    }

    /// 벽에 걸린 가구가 붙어 있는 벽. 왼쪽 벽은 x가 작고, 뒤쪽 벽은 z가 작다.
    static func wall(of item: RoomItemState) -> Wall { item.x < item.z ? .left : .back }

    /// 가까운 벽면 위의 자리(벽을 따라 격자에 맞춘다)
    static func wallSpot(near point: SIMD2<Float>, width: Float, depth: Float = 0.06) -> SIMD2<Float> {
        let gap = depth / 2 + 0.01
        let limit = half - width / 2 - 0.05
        let along = { (value: Float) in simd_clamp((value / grid).rounded() * grid, -limit, limit) }
        if point.x - -half < point.y - -half {
            return [-half + gap, along(point.y)]
        }
        return [along(point.x), -half + gap]
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
        if kind.hangsOnWall {
            let hung = items.filter { $0.kind.hangsOnWall }
            let gap = kind.size.z / 2 + 0.01
            let spots = stride(from: -0.7 as Float, through: 0.7, by: 0.35).flatMap { along in
                [SIMD2<Float>(along, -half + gap), SIMD2<Float>(-half + gap, along)]
            }
            return spots.first { spot in hung.allSatisfy { simd_distance(SIMD2($0.x, $0.z), spot) > kind.size.x } }
                ?? spots.first
        }
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

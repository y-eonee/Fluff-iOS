import Foundation
import simd

/// 방 바닥(x, z: -1...1) 위의 배치 규칙
enum RoomLayout {
    static let half: Float = 1
    static let grid: Float = 0.1
    // The interior camera also shows the open floor in front of the furniture.
    static let dollFloorCenter = SIMD2<Float>(repeating: 0.55)
    static let dollFloorHalf = SIMD2<Float>(repeating: 1.55)

    // Measured from the shared furniture mesh, excluding the soft contact shadow.
    private static var measured: [String: (min: SIMD3<Float>, max: SIMD3<Float>)] = [:]
    static func registerBounds(for kind: FurnitureKind, mirrored: Bool, min: SIMD3<Float>, max: SIMD3<Float>) {
        measured[kind.rawValue + (mirrored ? ":mirror" : "")] = (min, max)
    }
    private static func bounds(for kind: FurnitureKind, mirrored: Bool = false) -> (min: SIMD3<Float>, max: SIMD3<Float>) {
        if let bounds = measured[kind.rawValue + (mirrored ? ":mirror" : "")] { return bounds }
        if mirrored, let bounds = measured[kind.rawValue] {
            return ([-bounds.max.x, bounds.min.y, bounds.min.z], [-bounds.min.x, bounds.max.y, bounds.max.z])
        }
        return ([-kind.size.x / 2, 0, -kind.size.z / 2], [kind.size.x / 2, kind.size.y, kind.size.z / 2])
    }
    static func placementFootprint(_ item: RoomItemState) -> (min: SIMD2<Float>, max: SIMD2<Float>) {
        let b = bounds(for: item.kind, mirrored: item.isMirrored)
        if item.kind == .rugRound {
            let radius = SIMD2((b.max.x - b.min.x) / 2, (b.max.z - b.min.z) / 2)
            let c = cos(item.yaw), s = sin(item.yaw)
            let extent = SIMD2(sqrt(c * c * radius.x * radius.x + s * s * radius.y * radius.y),
                               sqrt(s * s * radius.x * radius.x + c * c * radius.y * radius.y))
            let center = SIMD2(item.x, item.z)
            return (center - extent, center + extent)
        }
        let corners = [SIMD2(b.min.x, b.min.z), SIMD2(b.min.x, b.max.z), SIMD2(b.max.x, b.min.z), SIMD2(b.max.x, b.max.z)]
        let points = corners.map { SIMD2(cos(item.yaw) * $0.x + sin(item.yaw) * $0.y,
                                        -sin(item.yaw) * $0.x + cos(item.yaw) * $0.y) + SIMD2(item.x, item.z) }
        return (points.reduce(SIMD2(repeating: Float.infinity), simd_min),
                points.reduce(SIMD2(repeating: -Float.infinity), simd_max))
    }
    /// Preserve valid saved positions; constrain the entire rotated mesh, not only its pivot.
    static func constrained(_ item: RoomItemState, snap: Bool = false) -> SIMD2<Float> {
        let point = SIMD2(item.x, item.z)
        if item.kind.hangsOnWall {
            let b = bounds(for: item.kind, mirrored: item.isMirrored)
            // Rotate around the same centered pivot as SceneFactory. A shelf's
            // hanging vine and a scaled frame are not symmetric about that pivot.
            let scale: SIMD2<Float> = item.kind == .frame ? [1.4, 1.55] : [1, 1]
            let pivotY = item.kind.size.y / 2 * scale.y
            let xs = [b.min.x, b.max.x].flatMap { x in
                [b.min.y, b.max.y].map { y in cos(item.yaw) * x - sin(item.yaw) * (y - pivotY) * scale.x / scale.y }
            }
            let left = wall(of: item) == .left
            let lo = left ? -xs.max()! : xs.min()!
            let hi = left ? -xs.min()! : xs.max()!
            let along = left ? point.y : point.x
            let lower = -half + 0.05 - lo, upper = half - 0.05 - hi
            let target = snap ? (along / grid).rounded() * grid : along
            let value = simd_clamp(target, min(lower, upper), max(lower, upper))
            let normal = -half - b.min.z + 0.01
            return left ? [normal, value] : [value, normal]
        }
        var local = item; local.x = 0; local.z = 0
        let b = placementFootprint(local)
        let lower = SIMD2<Float>(repeating: -half + 0.015) - b.min
        let upper = SIMD2<Float>(repeating: half - 0.015) - b.max
        let target = snap ? (point / grid).rounded(.toNearestOrAwayFromZero) * grid : point
        return simd_clamp(target, simd_min(lower, upper), simd_max(lower, upper))
    }
    /// Repair old out-of-room placements when opening the editor; the editor owns undo/save.
    static func repaired(_ items: [RoomItemState]) -> [RoomItemState] {
        var result = items
        var placed: [RoomItemState] = []
        let ordered = items.indices.sorted { a, b in
            func priority(_ kind: FurnitureKind) -> Int { kind == .lamp ? 1 : kind.hangsOnWall || kind.category == .rug ? 2 : 0 }
            return priority(items[a].kind) < priority(items[b].kind)
        }
        for index in ordered {
            var item = result[index]
            guard item.kind.isMovable else { placed.append(item); continue }
            let point = constrained(item); item.x = point.x; item.z = point.y
            if overlaps(item, in: placed) {
                var candidates: [RoomItemState] = []
                for x in stride(from: -half, through: half, by: grid) {
                    for z in stride(from: -half, through: half, by: grid) {
                        var candidate = item; candidate.x = x; candidate.z = z
                        let p = constrained(candidate); candidate.x = p.x; candidate.z = p.y
                        if !overlaps(candidate, in: placed) { candidates.append(candidate) }
                    }
                }
                if let closest = candidates.min(by: { simd_distance_squared(SIMD2($0.x, $0.z), point) < simd_distance_squared(SIMD2($1.x, $1.z), point) }) { item = closest }
            }
            result[index] = item; placed.append(item)
        }
        return result
    }

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

    /// Preserve the local coordinates of objects carried by a desk, even on a
    /// long drag where the old and new desktop no longer overlap.
    static func carriedItems(from original: RoomItemState, to moved: RoomItemState, in items: [RoomItemState]) -> [RoomItemState] {
        guard original.kind == .desk else { return [] }
        let oldRotation = simd_quatf(angle: original.yaw, axis: [0, 1, 0])
        let newRotation = simd_quatf(angle: moved.yaw, axis: [0, 1, 0])
        return items.filter { lampSupport(for: $0, in: items)?.id == original.id }.map { source in
            var local = oldRotation.inverse.act(SIMD3(source.x - original.x, 0, source.z - original.z))
            if original.isMirrored != moved.isMirrored { local.x = -local.x }
            let offset = newRotation.act(local)
            var result = source; result.x = moved.x + offset.x; result.z = moved.z + offset.z
            result.yaw += moved.yaw - original.yaw
            return result
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
            for x: Float in [-s.x * 0.43, s.x * 0.43] {
                parts.append(([s.x * 0.10, top - 0.055, s.z * 0.90], [x, (top - 0.055) / 2, 0]))
            }
            return parts
        case .bed:
            return [([s.x, 0.39, s.z], [0, 0.195, 0]),
                    ([s.x * 0.83, 0.15, 0.26], [0, 0.43, -s.z * 0.30]),
                    ([s.x * 1.02, 0.10, 0.20], [0, 0.375, -s.z * 0.14])]
        case .chair:
            return [([s.x, 0.227, s.z * 0.94], [0, 0.1135, 0]),
                    ([s.x * 0.95, s.y - 0.227, 0.085], [0, (s.y + 0.227) / 2 + 0.04, -s.z * 0.36])]
        default:
            let b = bounds(for: kind)
            return [(b.max - b.min, (b.max + b.min) / 2)]
        }
    }

    private static func collisionBounds(_ item: RoomItemState, in items: [RoomItemState]) -> [(min: SIMD3<Float>, max: SIMD3<Float>)] {
        collisionParts(item.kind).map { part in
            let c = cos(item.yaw), s = sin(item.yaw)
            let half = part.size / 2
            let extent = SIMD3(abs(c) * half.x + abs(s) * half.z, half.y, abs(s) * half.x + abs(c) * half.z)
            let centerX = item.isMirrored ? -part.center.x : part.center.x
            let center = SIMD3(item.x + c * centerX + s * part.center.z,
                               furnitureHeight(item, in: items) + part.center.y,
                               item.z - s * centerX + c * part.center.z)
            return (center - extent, center + extent)
        }
    }

    static func overlaps(_ item: RoomItemState, in items: [RoomItemState]) -> Bool {
        guard item.kind.blocksFloor else { return false }
        let items = items.map { $0.id == item.id ? item : $0 }
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
    static func snapped(_ point: SIMD2<Float>, for kind: FurnitureKind, yaw: Float = 0, isMirrored: Bool = false) -> SIMD2<Float> {
        constrained(RoomItemState(id: UUID(), kind: kind, x: point.x, z: point.y, yaw: yaw, isMirrored: isMirrored), snap: true)
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
        let limit = max(0, half - width / 2 - 0.05)
        let along = { (value: Float) in simd_clamp((value / grid).rounded() * grid, -limit, limit) }
        if point.x - -half < point.y - -half {
            return [-half + gap, along(point.y)]
        }
        return [along(point.x), -half + gap]
    }

    static func clampedToFloor(_ point: SIMD2<Float>) -> SIMD2<Float> {
        simd_clamp(point, dollFloorCenter - dollFloorHalf + 0.1, dollFloorCenter + dollFloorHalf - 0.1)
    }

    /// 그 자리에서 인형이 올라설 높이와, 올라선 가구
    static func seat(at point: SIMD2<Float>, in items: [RoomItemState], sleepingBeds: Set<UUID> = [], includingActivitySeats: Bool = false) -> (height: Float, item: RoomItemState?) {
        let candidates = items.filter { item in
            guard item.kind.allowsDollPlacement || (includingActivitySeats && item.kind == .sofa) else { return false }
            if item.kind == .bed { return isBedSeat(point, on: item) }
            let box = footprint(item)
            return point.x >= box.min.x && point.x <= box.max.x && point.y >= box.min.y && point.y <= box.max.y
        }
        let top = candidates.max { ($0.kind.seatHeight ?? 0) < ($1.kind.seatHeight ?? 0) }
        return (top?.kind == .bed ? bedSeatHeight(covered: sleepingBeds.contains(top!.id)) : (top?.kind.seatHeight ?? 0), top)
    }

    /// Awake dolls sit on top of the blanket, including while it covers a sleeper.
    static func bedSeatHeight(covered: Bool) -> Float { covered ? 0.53 : 0.40 }

    /// 침대 발치만 앉는 자리로 사용한다. 잠든 인형의 머리·몸통 영역은 항상 비워 둔다.
    static func isBedSeat(_ point: SIMD2<Float>, on bed: RoomItemState) -> Bool {
        let offset = point - SIMD2(bed.x, bed.z)
        let local = SIMD2(cos(bed.yaw) * offset.x - sin(bed.yaw) * offset.y,
                          sin(bed.yaw) * offset.x + cos(bed.yaw) * offset.y)
        return abs(local.x) <= 0.32 && local.y >= 0.28 && local.y <= 0.39
    }

    static func blockingDollPlacement(at point: SIMD2<Float>, in items: [RoomItemState]) -> RoomItemState? {
        items.first { item in
            guard item.kind.blocksFloor else { return false }
            let offset = point - SIMD2(item.x, item.z)
            let local = SIMD2(cos(item.yaw) * offset.x - sin(item.yaw) * offset.y,
                              sin(item.yaw) * offset.x + cos(item.yaw) * offset.y)
            let inside = abs(local.x) <= item.kind.size.x / 2 + 0.08 && abs(local.y) <= item.kind.size.z / 2 + 0.08
            if item.kind == .bed { return inside && !isBedSeat(point, on: item) }
            return inside && !item.kind.allowsDollPlacement
        }
    }

    static func canPlaceDoll(at point: SIMD2<Float>, in items: [RoomItemState]) -> Bool {
        blockingDollPlacement(at: point, in: items) == nil
    }

    /// Manual placement always uses the floor. Activity seating (sleep/focus/
    /// couch) remains separate and cannot turn a drag into a furniture snap.
    static func blockingFloorDollPlacement(at point: SIMD2<Float>, in items: [RoomItemState]) -> RoomItemState? {
        items.first { item in
            guard item.kind.blocksFloor else { return false }
            let delta = point - SIMD2(item.x, item.z)
            let local = SIMD2(cos(item.yaw) * delta.x - sin(item.yaw) * delta.y,
                              sin(item.yaw) * delta.x + cos(item.yaw) * delta.y)
            let b = bounds(for: item.kind, mirrored: item.isMirrored)
            let nearest = simd_clamp(local, SIMD2(b.min.x, b.min.z), SIMD2(b.max.x, b.max.z))
            return simd_distance_squared(local, nearest) < 0.08 * 0.08
        }
    }

    /// New pieces appear in visible free space, including rugs and nearby dolls.
    static func freeSpot(for kind: FurnitureKind, among items: [RoomItemState], yaw: Float = 0, dolls: [SIMD3<Float>] = []) -> SIMD2<Float>? {
        var candidates: [SIMD2<Float>] = []
        for z in stride(from: -half, through: half, by: grid) {
            for x in stride(from: -half, through: half, by: grid) {
                let point = snapped([x, z], for: kind, yaw: yaw)
                let candidate = RoomItemState(id: UUID(), kind: kind, x: point.x, z: point.y, yaw: yaw)
                guard !overlaps(candidate, in: items) else { continue }
                if kind.hangsOnWall {
                    let wall = wall(of: candidate)
                    let width = kind.size.x * (kind == .frame ? 1.4 : 1)
                    guard items.filter({ $0.kind.hangsOnWall && self.wall(of: $0) == wall }).allSatisfy({ other in
                        let spacing = wall == .left ? abs(point.y - other.z) : abs(point.x - other.x)
                        return spacing >= (width + other.kind.size.x * (other.kind == .frame ? 1.4 : 1)) / 2 + 0.04
                    }) else { continue }
                } else {
                    let b = placementFootprint(candidate)
                    guard items.filter({ $0.kind.isMovable && !$0.kind.hangsOnWall }).allSatisfy({ other in
                        let a = placementFootprint(other)
                        return b.max.x <= a.min.x || b.min.x >= a.max.x || b.max.y <= a.min.y || b.min.y >= a.max.y
                    }), dolls.allSatisfy({ p in
                        p.x < b.min.x - 0.1 || p.x > b.max.x + 0.1 || p.z < b.min.y - 0.1 || p.z > b.max.y + 0.1
                    }) else { continue }
                }
                candidates.append(point)
            }
        }
        return candidates.min { simd_distance_squared($0, [0, 0.4]) < simd_distance_squared($1, [0, 0.4]) }
    }

    /// Saved rooms may already overlap. Allow a drag to reduce that overlap so
    /// the user can separate existing furniture instead of being trapped.
    static func canMove(_ from: RoomItemState, to candidate: RoomItemState, among items: [RoomItemState]) -> Bool {
        if !overlaps(candidate, in: items) { return true }
        func volumes(_ item: RoomItemState) -> [UUID: Float] {
            let current = items.map { $0.id == item.id ? item : $0 }
            var result: [UUID: Float] = [:]
            for other in current where other.id != item.id && other.kind.blocksFloor {
                if lampSupport(for: item, in: current)?.id == other.id || lampSupport(for: other, in: current)?.id == item.id { continue }
                var total: Float = 0
                for a in collisionBounds(item, in: current) { for b in collisionBounds(other, in: current) {
                    let size = simd_max(.zero, simd_min(a.max, b.max) - simd_max(a.min, b.min))
                    total += size.x * size.y * size.z
                } }
                result[other.id] = total
            }
            return result
        }
        let old = volumes(from), next = volumes(candidate)
        // Escaping an old overlap must not push into a different piece.
        return old.values.contains { $0 > 0.000001 }
            && next.allSatisfy { $0.value <= old[$0.key, default: 0] + 0.000001 }
    }

    /// 새 인형을 둘 기본 위치: 가구와 다른 인형에서 떨어진 앞쪽 바닥의 빈 곳
    static func dollSpot(avoiding items: [RoomItemState], dolls: [SIMD3<Float>]) -> SIMD3<Float>? {
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
        return nil
    }
}

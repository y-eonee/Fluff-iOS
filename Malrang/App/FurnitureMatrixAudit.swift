#if DEBUG
import RealityKit
import SwiftData
import UIKit

/// Enumerates supported discrete edits plus continuous-control boundaries.
@MainActor enum FurnitureMatrixAudit {
    static func run() async {
        var counts: [String: Int] = [:], failures: [String] = []
        func check(_ group: String, _ key: String, _ result: Bool) {
            counts[group, default: 0] += 1
            if !result { failures.append(group + ":" + key) }
        }
        for kind in FurnitureKind.catalog {
            for ratio: Float in [0.25, 1, 4] { for turn in [-1, 0, 1, 2, 3, 4] {
                for fit in [0, 1] { for zoom: Float in [0, 1, 2, 3] {
                    for x: Float in [-1, 0, 1] { for y: Float in [-1, 0, 1] {
                        var item = RoomItemState(id: UUID(), kind: kind, x: 0, z: 0)
                        item.photoTurns = turn; item.photoFit = fit; item.photoScale = zoom
                        item.photoOffsetX = x; item.photoOffsetY = y
                        let t = FurniturePhotoTransform.make(item, imageAspect: ratio)
                        let corners: [SIMD2<Float>] = [[0, 0], [0, 1], [1, 0], [1, 1]]
                        let uv = corners.map { p -> SIMD2<Float> in
                            let p = p * t.scale
                            return SIMD2(cos(t.rotation) * p.x - sin(t.rotation) * p.y,
                                         sin(t.rotation) * p.x + cos(t.rotation) * p.y) + t.offset
                        }
                        let lo = uv.reduce(SIMD2<Float>(repeating: .infinity), simd_min)
                        let hi = uv.reduce(SIMD2<Float>(repeating: -.infinity), simd_max)
                        let center = (lo + hi) / 2
                        let finite = uv.allSatisfy { $0.x.isFinite && $0.y.isFinite }
                        let covers = lo.min() >= -0.0001 && hi.max() <= 1.0001
                        // Fit mode may contain intentional borders, but cannot pan the image away.
                        let intersects = lo.max() < 1 && hi.min() > 0 && center.min() >= -0.0001 && center.max() <= 1.0001
                        let aspect = kind == .rugRound ? 1 : kind == .bed ? 0.85 / 0.923 : kind.photoAspect
                        let odd = abs(turn % 2) == 1
                        let expectedRatio = aspect * (odd ? ratio : 1 / ratio)
                        let undistorted = abs(t.scale.x / t.scale.y - expectedRatio) < 0.001
                        check("photoUV", "\(kind)-\(ratio)-\(turn)-\(fit)-\(zoom)-\(x)-\(y)", finite && intersects && undistorted && ((fit == 1 && kind.category != .rug) || covers))
                    } }
                } }
            } }
        }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let photo = UIGraphicsImageRenderer(size: CGSize(width: 180, height: 120), format: format).image { c in
            UIColor.magenta.setFill(); c.fill(CGRect(x: 0, y: 0, width: 180, height: 120))
        }.pngData()!
        let paintParts: [FurnitureKind: String] = [.wall: "wall.left", .floor: "floor", .bed: "duvet", .desk: "desktop", .shelf: "shelf", .chair: "seat", .sofa: "seat", .rugRound: "rug", .rugSquare: "rug", .plant: "leaf", .frame: "frame", .lamp: "shade"]
        func tint(_ model: Entity, kind: FurnitureKind) -> UIColor? {
            guard let material = model.findEntity(named: paintParts[kind]!)?.components[ModelComponent.self]?.materials.first else { return nil }
            if let value = material as? CustomMaterial { return value.baseColor.tint }
            if let value = material as? UnlitMaterial { return value.color.tint }
            if let value = material as? PhysicallyBasedMaterial { return value.baseColor.tint }
            return nil
        }
        func close(_ a: UIColor?, _ b: UIColor?) -> Bool {
            guard let a, let b else { return false }
            var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
            var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
            a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa); b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
            return abs(ar-br) + abs(ag-bg) + abs(ab-bb) < 0.01
        }
        for kind in FurnitureKind.catalog {
            var item = RoomItemState(id: UUID(), kind: kind, x: 0, z: 0)
            let baseline = tint(await SceneFactory.furniture(item, cozy: true, cutaway: true), kind: kind)
            item.photoData = photo
            _ = await SceneFactory.furniture(item, cozy: true, cutaway: true)
            item.photoData = nil
            for hex in ["#FBF5EE", "#8FB8AE", "#E3EEEA", "#FFEFD6", "#F6D5BE", "#C3B7E0", "#000000", "#FFFFFF", "#123456"] {
                item.colorName = hex
                let model = await SceneFactory.furniture(item, cozy: true, cutaway: true)
                check("paintAfterPhoto", "\(kind)-\(hex)", close(tint(model, kind: kind), Palette.uiColor(hex)))
                check("photoRemoved", "\(kind)-\(hex)", model.findEntity(named: "custom-photo") == nil)
            }
            item.colorName = nil
            let restored = await SceneFactory.furniture(item, cozy: true, cutaway: true)
            check("defaultFinishRestored", kind.rawValue, close(tint(restored, kind: kind), baseline))
        }
        // Load every real model before checking placement (bounds include accessories).
        for kind in FurnitureKind.catalog where kind.isMovable {
            for mirror in [false, true] {
                var item = RoomItemState(id: UUID(), kind: kind, x: 0, z: -0.96)
                item.isMirrored = mirror
                _ = await SceneFactory.furniture(item, cozy: true, cutaway: true)
            }
        }
        for kind in FurnitureKind.catalog where kind.isMovable {
            for mirror in [false, true] { for turn in 0..<8 {
                var item = RoomItemState(id: UUID(), kind: kind, x: 0, z: -0.96)
                item.yaw = Float(turn) * .pi / 4; item.isMirrored = mirror; item.photoData = photo
                let model = await SceneFactory.furniture(item, cozy: true, cutaway: true)
                model.findEntity(named: "contact-shadow")?.removeFromParent()
                for x: Float in [-2, 0, 2] { for z: Float in [-2, 0, 2] {
                    var state = item; state.x = x; state.z = z
                    let p = RoomLayout.constrained(state); state.x = p.x; state.z = p.y
                    model.position.x = p.x; model.position.z = p.y
                    model.orientation = simd_quatf(angle: kind.hangsOnWall ? RoomLayout.wall(of: state).yaw : state.yaw, axis: [0, 1, 0])
                    var b = model.visualBounds(relativeTo: nil)
                    if kind == .rugRound {
                        // RealityKit rotates a mesh's enclosing box, whose empty
                        // corners overestimate a round rug at diagonal angles.
                        var lo = SIMD3<Float>(repeating: .infinity), hi = SIMD3<Float>(repeating: -.infinity)
                        func visit(_ node: Entity) {
                            if let mesh = node.components[ModelComponent.self]?.mesh {
                                let content = mesh.contents
                                for instance in content.instances {
                                    guard let source = content.models.first(where: { $0.id == instance.model }) else { continue }
                                    let matrix = node.transformMatrix(relativeTo: nil) * instance.transform
                                    for part in source.parts { for p in part.positions.elements {
                                        let v = matrix * SIMD4(p, 1)
                                        let point = SIMD3(v.x, v.y, v.z)
                                        lo = simd_min(lo, point); hi = simd_max(hi, point)
                                    } }
                                }
                            }
                            for child in node.children { visit(child) }
                        }
                        visit(model); b = BoundingBox(min: lo, max: hi)
                    }
                    let valid = b.min.x >= -1.001 && b.min.z >= -1.001 && b.max.x <= 1.001 && b.max.z <= 1.001
                    check("actualMeshBounds", "\(kind)-\(mirror)-\(turn)-\(x)-\(z) [\(b.min),\(b.max)]", valid)
                    let p2 = RoomLayout.constrained(state)
                    check("placementIdempotent", "\(kind)-\(mirror)-\(turn)-\(x)-\(z)", simd_distance(p, p2) < 0.0001)
                } }
            } }
        }
        // Every pair, all quarter-turns and a dense grid around the first item.
        let blocking = FurnitureKind.catalog.filter(\.blocksFloor)
        for aKind in blocking { for bKind in blocking { for turn in 0..<4 {
            let a = RoomItemState(id: UUID(), kind: aKind, x: 0, z: 0)
            for x: Float in [-0.8, -0.4, 0, 0.4, 0.8] { for z: Float in [-0.8, -0.4, 0, 0.4, 0.8] {
                var b = RoomItemState(id: UUID(), kind: bKind, x: x, z: z)
                b.yaw = Float(turn) * .pi / 2
                let items = [a, b]
                check("collisionSymmetry", "\(aKind)-\(bKind)-\(turn)-\(x)-\(z)", RoomLayout.overlaps(a, in: items) == RoomLayout.overlaps(b, in: items))
            } }
        } } }
        for turn in 0..<4 {
            var desk = RoomItemState(id: UUID(), kind: .desk, x: 0, z: 0)
            desk.yaw = Float(turn) * .pi / 2
            let lamp = RoomItemState(id: UUID(), kind: .lamp, x: 0, z: 0)
            check("deskSupport", "\(turn)", RoomLayout.lampSupport(for: lamp, in: [desk])?.id == desk.id && !RoomLayout.overlaps(lamp, in: [desk, lamp]))
        }
        let bed = RoomItemState(id: UUID(), kind: .bed, x: 0, z: 0)
        let plant = RoomItemState(id: UUID(), kind: .plant, x: 0, z: 0)
        let neighbor = RoomItemState(id: UUID(), kind: .plant, x: 0.7, z: 0)
        var escaping = plant; escaping.x = -0.5
        check("overlapEscape", "can_leave_old_overlap", RoomLayout.canMove(plant, to: escaping, among: [bed, plant]))
        escaping.x = 0.6
        check("overlapEscape", "cannot_enter_new_neighbor", !RoomLayout.canMove(plant, to: escaping, among: [bed, plant, neighbor]))
        // Persist every kind and independently restore all finish fields, transforms and wall sides.
        let store = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: store, withIntermediateDirectories: true)
            let url = store.appending(path: "matrix.store")
            var expected: [UUID: RoomItemState] = [:]
            do {
                let container = try ModelContainer(for: RoomItem.self, configurations: ModelConfiguration(url: url))
                for kind in FurnitureKind.catalog { for mirror in [false, true] { for turn in 0..<4 {
                    let item = RoomItem(kind: kind, x: 0.25, z: -0.5)
                    item.isMirrored = mirror; item.yaw = Double(turn) * .pi / 2
                    item.photoData = photo; item.colorName = "#EE00EE"; item.photoScale = 3
                    item.photoTurns = turn; item.photoFlipped = mirror; item.photoFit = turn % 2
                    item.photoOffsetX = 1; item.photoOffsetY = -1
                    item.rightWallPhotoData = Data(photo.reversed()); item.rightWallColorName = "#123456"
                    let original = item.state
                    var edited = original; edited.photoData = nil; edited.rightWallPhotoData = nil
                    edited.colorName = "#000000"; edited.isMirrored.toggle(); edited.yaw += .pi / 2
                    item.restore(edited); item.restore(original)
                    check("undo", "\(kind)-\(mirror)-\(turn)", item.state == original)
                    item.restore(edited)
                    check("redo", "\(kind)-\(mirror)-\(turn)", item.state == edited)
                    item.restore(original); expected[item.id] = original; container.mainContext.insert(item)
                } } }
                try container.mainContext.save()
            }
            let container = try ModelContainer(for: RoomItem.self, configurations: ModelConfiguration(url: url))
            let items = try container.mainContext.fetch(FetchDescriptor<RoomItem>())
            check("persistence", "count", items.count == expected.count)
            for item in items { check("persistence", item.id.uuidString, expected[item.id] == item.state) }
        } catch { check("persistence", String(describing: error), false) }
        try? FileManager.default.removeItem(at: store)
        let result: [String: Any] = ["passed": failures.isEmpty, "counts": counts, "failures": failures]
        let data = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        try? data?.write(to: URL.documentsDirectory.appending(path: "furniture-matrix-audit.json"), options: .atomic)
    }
}
#endif

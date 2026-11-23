import RealityKit
import UIKit

/// Animates the existing entities in camera space. Snapshots are visual transforms,
/// never Doll/RoomItem positions, so landing, history and persistence stay unchanged.
@MainActor
final class RoomSceneEntrance {
    private struct Snapshot {
        let entity: Entity
        let transform: Transform
        let opacity: OpacityComponent?
        let node: String
    }
    private let entrance: RoomEntrance
    private var snapshots: [Snapshot] = []
    private var prepared = false
    private var restored = false
    #if DEBUG
    private var audited = false
    private var projectionError: Double?
    #endif

    init(entrance: RoomEntrance, content: Entity, items: [RoomItemState]) {
        self.entrance = entrance
        let hero = entrance.loadingDoll.flatMap { doll in content.children.first { $0.name == "doll|\(doll.id)" } }
        for entity in content.children {
            let node: String
            if entrance.kind == .home {
                node = entity === hero ? "6457" : "6434"
            } else if entity.name.hasPrefix("doll|") {
                node = "8510"
            } else if items.contains(where: { $0.kind == .chair && entity.name == "item|\($0.id)" }) {
                node = "8452"
            } else { node = "8444" }
            snapshots.append(Snapshot(entity: entity, transform: entity.transform,
                                      opacity: entity.components[OpacityComponent.self], node: node))
            // Do not expose an unanimated first frame while waiting for splash/navigation.
            entity.components.set(OpacityComponent(opacity: 0))
        }
    }

    func update(in view: RoomRenderView, camera: PerspectiveCamera) {
        guard !restored, view.bounds.width > 0, view.bounds.height > 0 else { return }
        if !prepared {
            prepared = true
            entrance.useSceneDoll(entrance.kind == .home && !UIAccessibility.isReduceMotionEnabled && snapshots.contains { $0.node == "6457" })
            entrance.prepareScene()
        }
        entrance.finishIfNeeded()
        if entrance.finished {
            restore()
            view.isUserInteractionEnabled = true
            if entrance.kind == .home { view.sceneBackground = Palette.uiColor("#FFFFF4") }
            return
        }
        view.isUserInteractionEnabled = false
        view.markInteraction()
        if entrance.kind == .home {
            let node = entrance.loadingDoll == nil ? "1932:6465" : "1904:6845"
            let opacity = 1 - entrance.timeline.value(node, "opacity", at: entrance.time, fallback: 1)
            for snapshot in snapshots {
                snapshot.entity.transform = snapshot.transform
                let isHero = snapshot.node == "6457"
                snapshot.entity.components.set(OpacityComponent(opacity: Float(isHero && !UIAccessibility.isReduceMotionEnabled ? 1 : opacity) * (snapshot.opacity?.opacity ?? 1)))
                if isHero && !UIAccessibility.isReduceMotionEnabled {
                    animateHomeDoll(snapshot.entity, in: view, camera: camera)
                }
            }
            #if DEBUG
            auditLanding()
            #endif
            return
        }
        let time = entrance.time
        let motion = entrance.timeline
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        let pointsScale = view.bounds.width / 390
        for snapshot in snapshots {
            let entity = snapshot.entity
            entity.transform = snapshot.transform
            let baseOpacity = snapshot.opacity?.opacity ?? 1
            let opacity = entrance.kind == .home && snapshot.node == "6434"
                ? 1 - motion.value("6438", "opacity", at: time, fallback: 1)
                : motion.value(snapshot.node, "opacity", at: time, fallback: 1)
            entity.components.set(OpacityComponent(opacity: Float(opacity) * baseOpacity))
            guard !reduceMotion else { continue }
            if entrance.kind == .editor {
                // Origin is the base of each model: the source doll squashes at its feet.
                entity.scale *= SIMD3(Float(motion.value(snapshot.node, "--motion-scale-x", at: time, fallback: 1)),
                                      Float(motion.value(snapshot.node, "--motion-scale-y", at: time, fallback: 1)), 1)
                let origin = entity.position(relativeTo: nil)
                if let screen = view.project(origin) {
                    let y = motion.value(snapshot.node, "--motion-translate-y", at: time) * pointsScale
                    move(entity, center: origin, to: CGPoint(x: screen.x, y: screen.y + y), in: view, camera: camera)
                }
            }
        }
    }

    /// Animate the same rendered entity that stays in the room. At the end its
    /// original transform is restored exactly, so there is no sprite/3D handoff.
    private func animateHomeDoll(_ entity: Entity, in view: RoomRenderView, camera: PerspectiveCamera) {
        let time = entrance.time
        guard time < 2.95 else { return }
        let motion = entrance.timeline
        let ratio = 390.0 / 334.831
        let screen = view.window?.bounds.size ?? view.bounds.size
        let pointsScale = min(screen.width / 390, screen.height / 844)
        let layoutOrigin = CGPoint(x: (screen.width - 390 * pointsScale) / 2,
                                   y: (screen.height - 844 * pointsScale) / 2)
        let tx = motion.value("1904:6939", "--motion-translate-x", at: time, fallback: 80.131523)
        let ty = motion.value("1904:6939", "--motion-translate-y", at: time, fallback: 29.270287)
        let progress = time < 1.95 ? 0 : min(1, max(0, 1 - tx / 81.13221))
        let bounds = entity.visualBounds(relativeTo: nil)
        let center = bounds.center
        guard let landing = view.project(center) else { return }
        var projected: [CGPoint] = []
        for x in [bounds.min.x, bounds.max.x] {
            for y in [bounds.min.y, bounds.max.y] {
                for z in [bounds.min.z, bounds.max.z] {
                    if let point = view.project([x, y, z]) { projected.append(point) }
                }
            }
        }
        let height = max(1, (projected.map(\.y).max() ?? 1) - (projected.map(\.y).min() ?? 0))
        let initialScale = Float(270 * pointsScale / height)
        let size = initialScale + (1 - initialScale) * Float(progress)
        let squashX = time < 2.55 ? 1 : motion.value("1904:6939", "--motion-scale-x", at: time, fallback: 1)
        let squashY = time < 2.55 ? 1 : motion.value("1904:6939", "--motion-scale-y", at: time, fallback: 1)
        entity.scale *= SIMD3(size * Float(squashX), size * Float(squashY), size)
        let initial = view.convert(CGPoint(x: layoutOrigin.x + 195 * pointsScale,
                                          y: layoutOrigin.y + (285.49 + 57.9515 + ty) * ratio * pointsScale), from: nil)
        let target = CGPoint(x: initial.x + (landing.x - initial.x) * progress,
                             y: initial.y + (landing.y - initial.y) * progress)
        move(entity, center: entity.visualBounds(relativeTo: nil).center, to: target, in: view, camera: camera)
        #if DEBUG
        if let actual = view.project(entity.visualBounds(relativeTo: nil).center) {
            projectionError = hypot(actual.x - target.x, actual.y - target.y)
        }
        #endif
    }

    #if DEBUG
    private func auditLanding() {
        guard !audited, entrance.previewTime != nil,
              ProcessInfo.processInfo.arguments.contains("--loading-landing-audit") else { return }
        let heroes = snapshots.filter { $0.node == "6457" }
        var checks: [String: Bool] = [:]
        checks["exactly_selected_home_entity"] = heroes.count == 1 && heroes.first?.entity.name == entrance.loadingDoll.map { "doll|\($0.id)" }
        checks["single_scene_character"] = entrance.presentsSceneDoll
        if entrance.time >= 2.95 {
            checks["exact_original_transform_on_arrival"] = heroes.first.map { $0.entity.transform == $0.transform } ?? false
        } else {
            checks["screen_path_matches_within_one_point"] = (projectionError ?? .infinity) < 1
        }
        checks["other_entities_keep_placement"] = snapshots.filter { $0.node != "6457" }.allSatisfy { $0.entity.transform == $0.transform }
        let report: [String: Any] = ["time": entrance.time, "doll": entrance.loadingDoll?.name ?? "", "passed": checks.values.allSatisfy { $0 }, "checks": checks]
        if let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL.documentsDirectory.appending(path: "loading-landing-audit.json"))
            audited = true
        }
    }
    #endif

    private func move(_ entity: Entity, center: SIMD3<Float>, to point: CGPoint,
                      in view: RoomRenderView, camera: PerspectiveCamera) {
        guard let ray = view.ray(through: point) else { return }
        let normal = camera.orientation(relativeTo: nil).act([0, 0, -1])
        let denominator = simd_dot(ray.direction, normal)
        guard abs(denominator) > 0.0001 else { return }
        let distance = simd_dot(center - ray.origin, normal) / denominator
        let offset = ray.origin + ray.direction * distance - center
        entity.setPosition(entity.position(relativeTo: nil) + offset, relativeTo: nil)
    }

    func restore() {
        guard !restored else { return }
        for snapshot in snapshots {
            snapshot.entity.transform = snapshot.transform
            if let opacity = snapshot.opacity { snapshot.entity.components.set(opacity) }
            else { snapshot.entity.components.remove(OpacityComponent.self) }
        }
        restored = true
        snapshots.removeAll()
    }
}

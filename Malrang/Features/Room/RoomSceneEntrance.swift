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

    init(entrance: RoomEntrance, content: Entity, items: [RoomItemState]) {
        self.entrance = entrance
        let hero = content.children.first { $0.name.hasPrefix("doll|") }
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
        if !prepared { prepared = true; entrance.prepareScene() }
        entrance.finishIfNeeded()
        if entrance.finished {
            restore()
            view.isUserInteractionEnabled = true
            if entrance.kind == .home { view.sceneBackground = Palette.uiColor("#FFFFF4") }
            return
        }
        view.isUserInteractionEnabled = false
        view.markInteraction()
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
            if entrance.kind == .home && snapshot.node == "6457" {
                let bounds = entity.visualBounds(relativeTo: nil)
                let center = bounds.center
                guard let landing = view.project(center) else { continue }
                let remaining = min(1, max(0, motion.value("6457", "--motion-translate-x", at: time) / 94.5))
                let top = view.project(center + camera.orientation(relativeTo: nil).act([0, bounds.extents.y / 2, 0]))
                let bottom = view.project(center - camera.orientation(relativeTo: nil).act([0, bounds.extents.y / 2, 0]))
                let height = max(1, abs((bottom?.y ?? landing.y) - (top?.y ?? landing.y)))
                let initialScale = Float(135 * pointsScale / height)
                let size = 1 + (initialScale - 1) * Float(remaining)
                let sx = Float(motion.value("6457", "--motion-scale-x", at: time, fallback: 1))
                let sy = Float(motion.value("6457", "--motion-scale-y", at: time, fallback: 1))
                entity.scale *= SIMD3(size * sx, size * sy, size * sx)
                // Use the actual current camera projection as the destination, including
                // raised furniture seats and custom/photo dolls; no fixed image location.
                let initial = CGPoint(x: view.bounds.midX, y: view.bounds.height * 384.5 / 844)
                let target = CGPoint(x: landing.x + (initial.x - landing.x) * remaining,
                                     y: landing.y + (initial.y - landing.y) * remaining
                                        + motion.value("6457", "--motion-translate-y", at: time) * pointsScale)
                move(entity, center: entity.visualBounds(relativeTo: nil).center, to: target, in: view, camera: camera)
            } else if entrance.kind == .editor {
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

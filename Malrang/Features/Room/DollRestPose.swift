import RealityKit
import UIKit

/// All poses use the same editable meshes and the user's saved materials.
enum DollRestPose {
  static func sitting(_ model: Entity) {
    for part in [DollPart.leftLeg, .rightLeg] {
      model.findEntity(named: part.rawValue)?.orientation = simd_quatf(
        angle: -.pi / 2, axis: [1, 0, 0])
    }
    model.findEntity(named: DollPart.torso.rawValue)?.orientation = simd_quatf(
      angle: -0.08, axis: [1, 0, 0])
  }

  static func sleeping(_ entity: Entity, bed: RoomItemState, animated: Bool) {
    guard let body = entity.findEntity(named: "body") else { return }
    let duration: TimeInterval = animated && !UIAccessibility.isReduceMotionEnabled ? 0.8 : 0
    var placement = entity.transform
    placement.translation = bedPosition(bed)
    placement.rotation = simd_quatf(angle: bed.yaw, axis: [0, 1, 0])
    set(entity, placement, duration)
    var pose = body.transform
    pose.rotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
    pose.translation.y = 0.12
    set(body, pose, duration)
    if let head = entity.findEntity(named: DollPart.head.rawValue), head.findEntity(named: "sleep.closed-eyes") == nil {
      let closed = Entity(); closed.name = "sleep.closed-eyes"
      var thread = PhysicallyBasedMaterial()
      thread.baseColor.tint = Palette.uiColor("#523221"); thread.roughness = 1.0
      for eye in head.children.filter({ $0.name == "eye" }) {
        eye.isEnabled = false
        let points = (0...16).map { i -> SIMD3<Float> in
          let x = Float(i) / 16 * 0.018 - 0.009
          return eye.position + SIMD3(x, -cos(Float(i) / 16 * .pi * 2) * 0.0015, 0.003)
        }
        closed.addChild(PresetEmbroidery.line(points, radius: 0.0014, material: thread, name: "sleep.eye-stitch"))
      }
      head.addChild(closed)
    }
    for (part, angle) in [
      (DollPart.leftArm, Float(-0.8)), (.rightArm, -1.0), (.leftLeg, -0.7), (.rightLeg, -0.55),
      (.head, 0.12), (.ears, 0.12),
    ] {
      guard let node = entity.findEntity(named: part.rawValue) else { continue }
      var pose = node.transform
      pose.rotation = simd_quatf(angle: angle, axis: [1, 0, 0])
      set(node, pose, duration)
    }
  }

  static func bedPosition(_ bed: RoomItemState) -> SIMD3<Float> {
    let offset = simd_act(
      simd_quatf(angle: bed.yaw, axis: [0, 1, 0]), SIMD3<Float>(0, 0, -0.18))
    return SIMD3<Float>(bed.x, bed.kind.seatHeight ?? 0.32, bed.z) + offset
  }

  private static func set(_ entity: Entity, _ transform: Transform, _ duration: TimeInterval) {
    if duration == 0 {
      entity.transform = transform
    } else {
      entity.move(
        to: transform, relativeTo: entity.parent, duration: duration, timingFunction: .easeInOut)
    }
  }

  static func quilt(color: String? = nil) -> ModelEntity {
    var material = PhysicallyBasedMaterial()
    material.baseColor = .init(tint: Palette.uiColor(color ?? "#F0C9BD"))
    material.roughness = 1.0
    // A softly curved cover with real thickness, leaving the head visible.
    let cover = ModelEntity(
      mesh: .generateBox(size: [0.30, 0.05, 0.24], cornerRadius: 0.025), materials: [material])
    cover.name = "sleep.quilt"
    cover.position = [0, 0.145, 0.20]
    return cover
  }
}

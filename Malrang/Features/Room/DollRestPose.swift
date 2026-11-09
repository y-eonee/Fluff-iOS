import RealityKit
import UIKit

/// All poses use the same editable meshes and the user's saved materials.
enum DollRestPose {
  /// Face the chair's front (towards the desk in the starter room), and fit
  /// the actual posed mesh in front of the backrest and above the cushion.
  static func chairSeat(_ model: Entity, on chair: RoomItemState) {
    sitting(model)
    let bounds = model.visualBounds(relativeTo: model)
    let scale = min(Float(1), chair.kind.size.x * 0.85 / max(bounds.extents.x, 0.001))
    model.scale = SIMD3(repeating: scale)
    model.orientation = simd_quatf(angle: chair.yaw, axis: [0, 1, 0])
    let backrestFront = -chair.kind.size.z * 0.36 + 0.085 / 2
    let forward = max(0.035, backrestFront + 0.012 - bounds.min.z * scale)
    let local = SIMD3<Float>(0, (chair.kind.seatHeight ?? 0.227) + 0.008 - bounds.min.y * scale, forward)
    model.position = SIMD3(chair.x, 0, chair.z) + model.orientation.act(local)
  }

  static func sitting(_ model: Entity, animated: Bool = false) {
    let duration: TimeInterval = animated && !UIAccessibility.isReduceMotionEnabled ? 0.45 : 0
    for part in [DollPart.leftLeg, .rightLeg] {
      if let limb = model.findEntity(named: part.rawValue) {
        var pose = limb.transform
        pose.rotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        set(limb, pose, duration)
      }
    }
    if let torso = model.findEntity(named: DollPart.torso.rawValue) {
      var pose = torso.transform
      pose.rotation = simd_quatf(angle: -0.08, axis: [1, 0, 0])
      set(torso, pose, duration)
    }
  }

  static func sleeping(_ entity: Entity, bed: RoomItemState, animated: Bool) {
    guard let body = entity.findEntity(named: "body") else { return }
    let duration: TimeInterval = animated && !UIAccessibility.isReduceMotionEnabled ? 0.8 : 0
    var placement = entity.transform
    placement.translation = bedPosition(bed)
    placement.rotation = simd_quatf(angle: bed.yaw, axis: [0, 1, 0])
    set(entity, placement, duration)
    var pose = body.transform
    let isPhotoDoll = entity.findEntity(named: DollPart.head.rawValue) == nil
    // A photo doll has one continuous mesh: incline it onto the pillow instead
    // of lifting a separate head, keeping its lower half beneath the duvet.
    pose.rotation = simd_quatf(angle: -.pi / 2 + (isPhotoDoll ? 0.4 : 0), axis: [1, 0, 0])
    pose.translation.y = isPhotoDoll ? 0.12 : 0.08
    pose.translation.z = isPhotoDoll ? 0.09 : 0
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
      let original = node.components[SleepingOrigin.self]?.transform ?? node.transform
      node.components.set(SleepingOrigin(transform: original))
      var pose = original
      // Raise the head and ears together onto the pillow; the torso stays under the duvet.
      if part == .head || part == .ears { pose.translation.z += 0.15 }
      pose.rotation = simd_quatf(angle: angle, axis: [1, 0, 0])
      set(node, pose, duration)
    }
  }

  static func bedPosition(_ bed: RoomItemState) -> SIMD3<Float> {
    let offset = simd_act(
      simd_quatf(angle: bed.yaw, axis: [0, 1, 0]), SIMD3<Float>(0, 0, -0.22))
    return SIMD3<Float>(bed.x, 0.32, bed.z) + offset
  }

  private static func set(_ entity: Entity, _ transform: Transform, _ duration: TimeInterval) {
    if duration == 0 {
      entity.transform = transform
    } else {
      entity.move(
        to: transform, relativeTo: entity.parent, duration: duration, timingFunction: .easeInOut)
    }
  }

  private struct SleepingOrigin: Component { let transform: Transform }

  enum BeddingPose { case made, open, covered }

  private struct BeddingOrigin: Component {
    let transform: Transform
  }

  /// Move the bed's own duvet (including its fold and fibers), retaining its materials.
  static func bedding(_ bed: Entity?, pose: BeddingPose, animated: Bool) {
    guard let bed else { return }
    func visit(_ node: Entity) {
      if node.name.hasPrefix("duvet") || node.name == "custom-photo" {
        let original = node.components[BeddingOrigin.self]?.transform ?? node.transform
        node.components.set(BeddingOrigin(transform: original))
        var target = original
        switch pose {
        case .made: break
        case .open:
          // Gather the full-length blanket while the doll gets into bed.
          if node.name == "custom-photo" { target.scale.y *= 0.55 }
          else { target.scale.z *= 0.55 }
          target.translation.z = original.translation.z * 0.55 + 0.03
          target.translation.y += 0.06
        case .covered:
          target.translation.y += 0.13
        }
        node.stopAllAnimations()
        set(node, target, animated && !UIAccessibility.isReduceMotionEnabled ? 0.75 : 0)
        return // Child meshes follow their parent's movement.
      }
      for child in node.children { visit(child) }
    }
    visit(bed)
  }
}

import RealityKit
import UIKit

/// Embroidered rear seams follow the existing closed head and torso instead of a rear-view picture.
enum DollBackSeams {
  static func add(to model: Entity) {
    guard model.findEntity(named: "rear.seam") == nil else { return }
    var thread = PhysicallyBasedMaterial()
    thread.baseColor.tint = Palette.uiColor("#CEBFB2")
    thread.roughness = 1.0
    if let head = model.findEntity(named: DollPart.head.rawValue) {
      for i in 0..<17 {
        let t = Float(i) / 16 * 1.7 - 0.85
        let stitch = ModelEntity(mesh: .generateSphere(radius: 0.0010), materials: [thread])
        stitch.name = "rear.seam"
        stitch.scale = [1, 2.4, 1]
        let surface = PresetHeadSurface.point(latitude: t, angle: -.pi / 2, width: 0.128)
        stitch.position = [0, surface.y, surface.z - 0.0012]
        head.addChild(stitch)
      }
    }
    if let torso = model.findEntity(named: DollPart.torso.rawValue) {
      for i in 0..<14 {
        let t = Float(i) / 13 * 1.6 - 0.8
        let stitch = ModelEntity(mesh: .generateSphere(radius: 0.0009), materials: [thread])
        stitch.name = "rear.seam"
        stitch.scale = [1, 2.2, 1]
        let y = t * 0.05
        let apronRow = (0.046 - y) / 0.111
        stitch.position = [0, y, 0.005 - (0.059 + 0.006 * apronRow) - 0.001]
        torso.addChild(stitch)
      }
    }
  }
}

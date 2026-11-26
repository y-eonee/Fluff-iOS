import RealityKit
import UIKit

/// Closed, inflated front/back meshes retain the user's cutout silhouette at every angle.
enum PlushCutoutModel {
  static func make(_ data: Data) async -> Entity {
    let root = Entity()
    guard let image = ImageDownsampling.image(data, maxPixel: 2048), let cg = image.cgImage else {
      return root
    }
    let aspect = Float(cg.width) / Float(cg.height)
    let w = max(32, Int(320 * min(1, aspect))) + 1
    let h = max(32, Int(320 / max(1, aspect))) + 1
    var rgba = [UInt8](repeating: 0, count: w * h * 4)
    rgba.withUnsafeMutableBytes { bytes in
      guard let context = CGContext(data: bytes.baseAddress, width: w, height: h,
        bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
      context.interpolationQuality = .high
      context.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
    }
    let alpha = (0..<w * h).map { index -> Float in
      let x = index % w, y = index / w
      guard x > 0, x < w - 1, y > 0, y < h - 1 else { return 0 }
      return Float(rgba[((h - 1 - y) * w + x) * 4 + 3]) / 255
    }
    let geometry = CutoutSurface.make(alpha: alpha, columns: w, rows: h,
                                      aspect: aspect, height: SceneFactory.dollHeight)
    var cloth = PhysicallyBasedMaterial()
    cloth.baseColor.tint = Palette.uiColor("#F7EEE1")
    cloth.roughness = 1.0
    cloth.faceCulling = .none
    if let texture = try? await TextureResource(named: "CozyFabricColor") {
      cloth.baseColor.texture = .init(texture)
    }
    var photo = PhysicallyBasedMaterial()
    photo.roughness = 1.0
    photo.faceCulling = .none
    if let texture = try? await TextureResource(image: cg, options: .init(semantic: .color)) {
      photo.baseColor = .init(tint: .white, texture: .init(texture))
    }
    let surfaces: [(String, CutoutSurface.Mesh, PhysicallyBasedMaterial)] = [
      ("front", geometry.front, photo), ("back", geometry.back, cloth), ("seam", geometry.seam, cloth)
    ]
    for (name, surface, material) in surfaces {
      guard !surface.indices.isEmpty else { continue }
      var descriptor = MeshDescriptor(name: "cutout.\(name)")
      descriptor.positions = .init(surface.positions)
      descriptor.normals = .init(surface.normals)
      descriptor.primitives = .triangles(surface.indices)
      descriptor.textureCoordinates = .init(surface.uv)
      if let mesh = try? MeshResource.generate(from: [descriptor]) {
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.name = "cutout.\(name)"
        root.addChild(model)
      }
    }
    return root
  }
}

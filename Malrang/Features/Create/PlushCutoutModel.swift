import RealityKit
import UIKit

/// Closed, inflated front/back meshes retain the user's cutout silhouette at every angle.
enum PlushCutoutModel {
  static func make(_ data: Data) async -> Entity {
    let root = Entity()
    guard let image = ImageDownsampling.image(data, maxPixel: 512), let cg = image.cgImage else {
      return root
    }
    let w = 64
    let h = 64
    var rgba = [UInt8](repeating: 0, count: w * h * 4)
    rgba.withUnsafeMutableBytes { bytes in
      guard
        let context = CGContext(
          data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
      else { return }
      context.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
    }
    // Bitmap alpha rows start at the top; model vertices rise from the feet.
    let active = (0..<w * h).map { index in
      let x = index % w, y = index / w
      return rgba[((h - 1 - y) * w + x) * 4 + 3] > 50
    }
    var distance = active.map { $0 ? Float(64) : 0 }
    for y in 0..<h {
      for x in 0..<w {
        let i = y * w + x
        if x == 0 || y == 0 { distance[i] = min(distance[i], 1) }
        if x > 0 { distance[i] = min(distance[i], distance[i - 1] + 1) }
        if y > 0 { distance[i] = min(distance[i], distance[i - w] + 1) }
      }
    }
    for y in (0..<h).reversed() {
      for x in (0..<w).reversed() {
        let i = y * w + x
        if x == w - 1 || y == h - 1 { distance[i] = min(distance[i], 1) }
        if x < w - 1 { distance[i] = min(distance[i], distance[i + 1] + 1) }
        if y < h - 1 { distance[i] = min(distance[i], distance[i + w] + 1) }
      }
    }
    let aspect = Float(cg.width) / Float(cg.height)
    let height = SceneFactory.dollHeight
    func point(_ x: Int, _ y: Int, _ side: Float) -> SIMD3<Float> {
      let d = distance[min(h - 1, y) * w + min(w - 1, x)]
      return [
        (Float(x) / Float(w) - 0.5) * height * aspect, Float(y) / Float(h) * height,
        side * (0.015 + sqrt(d / 64) * 0.11),
      ]
    }
    var front = [SIMD3<Float>]()
    var back = [SIMD3<Float>]()
    var uv = [SIMD2<Float>]()
    var faces = [UInt32]()
    var edge = [SIMD3<Float>]()
    var edgeIndices = [UInt32]()
    for y in 0..<h {
      for x in 0..<w where active[y * w + x] {
        let corners = [(x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1)]
        let start = UInt32(front.count)
        for (a, b) in corners {
          front.append(point(a, b, 1))
          back.append(point(a, b, -1))
          // The CGImage texture uses bottom-to-top UVs; keep it aligned with the silhouette.
          uv.append([Float(a) / Float(w), Float(b) / Float(h)])
        }
        faces += [start, start + 1, start + 2, start, start + 2, start + 3]
        for (dx, dy, a, b) in [(-1, 0, 0, 3), (1, 0, 1, 2), (0, -1, 0, 1), (0, 1, 3, 2)] {
          let xx = x + dx
          let yy = y + dy
          if xx < 0 || xx >= w || yy < 0 || yy >= h || !active[yy * w + xx] {
            let k = UInt32(edge.count)
            let c = corners[a]
            let d = corners[b]
            edge += [
              point(c.0, c.1, 1), point(d.0, d.1, 1), point(d.0, d.1, -1), point(c.0, c.1, -1),
            ]
            edgeIndices += [k, k + 1, k + 2, k, k + 2, k + 3]
          }
        }
      }
    }
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
    var reverseFaces: [UInt32] = []
    for i in stride(from: 0, to: faces.count, by: 3) {
      reverseFaces.append(contentsOf: [faces[i], faces[i + 2], faces[i + 1]])
    }
    let surfaces: [(String, [SIMD3<Float>], [UInt32], PhysicallyBasedMaterial)] = [
      ("front", front, faces, photo), ("back", back, reverseFaces, cloth), ("seam", edge, edgeIndices, cloth)
    ]
    for (name, vertices, indices, material) in surfaces {
      var descriptor = MeshDescriptor(name: "cutout.\(name)")
      descriptor.positions = .init(vertices)
      descriptor.primitives = .triangles(indices)
      if name != "seam" { descriptor.textureCoordinates = .init(uv) }
      if let mesh = try? MeshResource.generate(from: [descriptor]) {
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.name = "cutout.\(name)"
        root.addChild(model)
      }
    }
    return root
  }
}

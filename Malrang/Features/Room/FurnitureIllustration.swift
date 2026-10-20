import RealityKit
import UIKit

/// 피그마 원본 SVG의 색과 질감 필터를 그대로 그린 텍스처를 입체 면에 붙인다.
enum FurnitureIllustration {
    private struct Part {
        var mesh: MeshResource
        var color: String
        var custom: Bool
        var photo: Bool
        var hiddenByPhoto: Bool
        var texture: String?
        var photoMesh: MeshResource?
    }
    private struct Artwork {
        var color: TextureResource
        var opacity: TextureResource
        var source: CGImage
    }
    private static var parts: [FurnitureKind: [Part]] = [:]
    private static var artwork: [String: Artwork] = [:]
    private static var floorColors: [String: (name: String, texture: TextureResource)] = [:]
    private struct AtlasEntry: Decodable {
        let texture: String
        let rect: [Float]
    }
    private static let atlas: [String: AtlasEntry] = {
        guard let url = Bundle.main.url(forResource: "RoomIllustrationAtlas", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([String: AtlasEntry].self, from: data) else { return [:] }
        return entries
    }()
    private static let source: [String: [IllustrationFace]] = {
        guard let url = Bundle.main.url(forResource: "RoomIllustration", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let faces = try? JSONDecoder().decode([String: [IllustrationFace]].self, from: data) else { return [:] }
        return faces
    }()

    static func make(_ item: RoomItemState, photoMaterial: RealityKit.Material) async throws -> Entity? {
        guard let original = source[item.kind.rawValue] else { return nil }
        let faces = original.map { face in
            var face = face
            if let name = face.texture, let entry = atlas[name] {
                face.texture = entry.texture
                face.textureRegion = entry.rect
            }
            return face
        }
        if parts[item.kind] == nil {
            var photoMeshes: [String: MeshResource] = [:]
            for buffer in IllustrationMesh.build(faces.filter(\.photo), usesArtwork: false) {
                if let name = buffer.texture { photoMeshes[name] = try mesh(buffer) }
            }
            parts[item.kind] = try IllustrationMesh.build(faces).map { buffer in
                Part(mesh: try mesh(buffer), color: buffer.color, custom: buffer.custom,
                     photo: buffer.photo, hiddenByPhoto: buffer.hiddenByPhoto, texture: buffer.texture,
                     photoMesh: buffer.texture.flatMap { photoMeshes[$0] })
            }
        }
        let root = Entity()
        for part in parts[item.kind] ?? [] {
            if part.hiddenByPhoto && item.photoData != nil { continue }
            let finish: RealityKit.Material
            if part.photo && item.photoData != nil {
                finish = photoMaterial
            } else {
                // 자동 톤 매핑이 피그마의 밝은 파스텔 색을 어둡게 누르지 않게 한다.
                var material = UnlitMaterial(applyPostProcessToneMap: false)
                material.faceCulling = .none
                if let name = part.texture {
                    if artwork[name] == nil {
                        let url = Bundle.main.url(forResource: name, withExtension: "png")
                            ?? Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "IllustrationAtlases")
                            ?? Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "IllustrationTextures")
                        if let url, let image = UIImage(contentsOfFile: url.path), let cgImage = image.cgImage,
                           let mask = opacityImage(named: name, fallback: image) {
                            let color = try await TextureResource(image: cgImage, options: .init(semantic: .color))
                            let opacity = try await TextureResource(image: mask, options: .init(semantic: .raw))
                            artwork[name] = Artwork(color: color, opacity: opacity, source: cgImage)
                        }
                    }
                    if let image = artwork[name] {
                        if item.kind == .floor, let colorName = item.colorName {
                            if floorColors[name]?.name != colorName {
                                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, alpha: CGFloat = 0
                                Palette.uiColor(colorName).getRed(&r, green: &g, blue: &b, alpha: &alpha)
                                let rgb = SIMD3<Float>(Float(r), Float(g), Float(b))
                                let source = image.source
                                let recolored = await Task.detached(priority: .userInitiated) {
                                    FloorArtwork.recolored(source, tint: rgb)
                                }.value
                                try Task.checkCancellation()
                                if let recolored {
                                    let texture = try await TextureResource(image: recolored, options: .init(semantic: .color))
                                    try Task.checkCancellation()
                                    floorColors[name] = (colorName, texture)
                                }
                            }
                            material.color = .init(tint: .white, texture: .init(floorColors[name]?.texture ?? image.color))
                        } else {
                            let tint = part.custom ? item.colorName.map(Palette.uiColor) ?? .white : .white
                            material.color = .init(tint: tint, texture: .init(image.color))
                        }
                        material.blending = .transparent(opacity: .init(scale: 1, texture: .init(image.opacity)))
                        material.opacityThreshold = 0.1
                    } else {
                        material.color = .init(tint: Palette.uiColor(part.color))
                    }
                } else {
                    material.color = .init(tint: Palette.uiColor(part.custom ? (item.colorName ?? part.color) : part.color))
                }
                finish = material
            }
            let displayedMesh = part.photo && item.photoData != nil ? (part.photoMesh ?? part.mesh) : part.mesh
            root.addChild(ModelEntity(mesh: displayedMesh, materials: [finish]))
        }
        return root
    }

    private static func opacityImage(named name: String, fallback image: UIImage) -> CGImage? {
        let url = Bundle.main.url(forResource: name + "_opacity", withExtension: "png")
            ?? Bundle.main.url(forResource: name + "_opacity", withExtension: "png", subdirectory: "IllustrationAtlases")
        if let url, let mask = UIImage(contentsOfFile: url.path)?.cgImage { return mask }
        return SceneFactory.opacityMask(of: image)
    }

    private static func mesh(_ buffer: IllustrationMesh) throws -> MeshResource {
        var descriptor = MeshDescriptor(name: "illustration")
        descriptor.positions = MeshBuffers.Positions(buffer.positions)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(buffer.uv)
        descriptor.primitives = .triangles(buffer.triangles)
        return try MeshResource.generate(from: [descriptor])
    }
}

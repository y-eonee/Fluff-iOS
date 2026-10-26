import RealityKit
import UIKit

/// Figma creation preset: white plush suit, broad inset face panel, short flared body.
enum PhotoSuitModel {
    static func make(_ configuration: PresetConfiguration) async -> Entity {
        let root = Entity()
        let fabric = try? await TextureResource(named: "CozyFabricColor")
        func material(_ color: String) -> PhysicallyBasedMaterial {
            var value = PhysicallyBasedMaterial()
            value.baseColor = .init(tint: Palette.uiColor(color), texture: fabric.map { .init($0) })
            value.roughness = 0.97; value.metallic = .init(floatLiteral: 0)
            value.textureCoordinateTransform.scale = [7, 7]
            return value
        }
        let origins: [DollPart: SIMD3<Float>] = [
            .head: [0, 0.265, 0], .ears: [0, 0.265, 0], .torso: [0, 0.131, 0],
            .leftArm: [-0.093, 0.149, 0], .rightArm: [0.093, 0.149, 0],
            .leftLeg: [-0.040, 0.044, 0], .rightLeg: [0.040, 0.044, 0]
        ]
        var groups: [DollPart: Entity] = [:]
        for part in DollPart.allCases {
            let edit = configuration.part(part)
            let group = Entity(); group.name = part.rawValue
            group.position = origins[part]! + [0, edit.offset * 0.05, 0]
            group.scale = [edit.size * edit.width, edit.size * edit.length, edit.size]
            groups[part] = group; root.addChild(group)
        }
        func color(_ part: DollPart) -> String { configuration.part(part).color ?? "#F7F5F4" }
        func oval(_ name: String, part: DollPart, size: SIMD3<Float>, at: SIMD3<Float> = .zero, tint: String? = nil) -> ModelEntity {
            let entity = ModelEntity(mesh: .generateSphere(radius: 0.5), materials: [material(tint ?? color(part))])
            entity.name = name; entity.scale = size; entity.position = at; groups[part]!.addChild(entity)
            return entity
        }
        _ = oval("hood", part: .head, size: [0.291, 0.202, 0.185])
        // A broad lower belly and narrower shoulders match the reference's dress-shaped torso.
        let torso = ModelEntity(mesh: torsoMesh(), materials: [material(color(.torso))])
        torso.scale.x = 1.12; torso.name = "body.fur"; groups[.torso]!.addChild(torso)
        for side: Float in [-1, 1] {
            let armPart: DollPart = side < 0 ? .leftArm : .rightArm
            let arm = oval("sleeve", part: armPart, size: [0.044, 0.114, 0.050])
            arm.orientation = simd_quatf(angle: side * 0.60, axis: [0, 0, 1])
            _ = oval("mitten", part: armPart, size: [0.047, 0.043, 0.050], at: [side * 0.022, -0.038, 0.004])
            let legPart: DollPart = side < 0 ? .leftLeg : .rightLeg
            let leg = ModelEntity(mesh: torsoMesh(), materials: [material(color(legPart))])
            leg.name = "soft-leg-and-foot"; leg.scale = [0.54, 0.90, 0.85]
            leg.position.z = 0.008; groups[legPart]!.addChild(leg)
            if configuration.shape == .cat {
                let ear = ModelEntity(mesh: PresetDollModel.roundedEar(width: 0.088, height: 0.125, depth: 0.055), materials: [material(color(.ears))])
                ear.position = [side * 0.102, 0.091, -0.017]
                ear.orientation = simd_quatf(angle: -side * 0.44, axis: [0, 0, 1]); groups[.ears]!.addChild(ear)
                let inner = ModelEntity(mesh: PresetDollModel.roundedEar(width: 0.052, height: 0.080, depth: 0.013), materials: [material("#DDC9C2")])
                inner.position = [side * 0.108, 0.097, 0.013]; inner.orientation = ear.orientation; groups[.ears]!.addChild(inner)
            } else if configuration.shape == .bear {
                _ = oval("round-ear", part: .ears, size: [0.090, 0.090, 0.055], at: [side * 0.11, 0.083, -0.015])
                _ = oval("ear-lining", part: .ears, size: [0.054, 0.055, 0.014], at: [side * 0.11, 0.083, 0.015], tint: "#DDC9C2")
            } else {
                let ear = oval("floppy-ear", part: .ears, size: [0.072, 0.208, 0.055], at: [side * 0.132, 0.010, -0.015])
                ear.orientation = simd_quatf(angle: side * 0.27, axis: [0, 0, 1])
                let inner = oval("ear-lining", part: .ears, size: [0.043, 0.157, 0.013], at: [side * 0.136, 0.001, 0.014], tint: "#DDC9C2")
                inner.orientation = ear.orientation
            }
        }
        // The seam is a shallow inset oval, not the thick circular rim of the earlier model.
        _ = oval("face.seam", part: .head, size: [0.247, 0.122, 0.018], at: [0, -0.032, 0.092], tint: "#D8D2CE")
        _ = oval("face.lining", part: .head, size: [0.242, 0.117, 0.021], at: [0, -0.031, 0.095], tint: "#F8F5F2")
        if let data = configuration.face, let image = UIImage(data: data), let cg = image.cgImage,
           let texture = try? await TextureResource(image: cg, options: .init(semantic: .color)) {
            var photoMaterial = UnlitMaterial(); photoMaterial.color = .init(tint: .white, texture: .init(texture))
            if let mask = SceneFactory.opacityMask(of: image), let opacity = try? await TextureResource(image: mask, options: .init(semantic: .raw)) {
                photoMaterial.blending = .transparent(opacity: .init(scale: 1, texture: .init(opacity)))
            }
            let panel = ModelEntity(mesh: PresetFaceMesh.photo(aspect: Float(cg.width) / Float(cg.height), zoom: configuration.faceScale, offsetX: configuration.faceOffsetX ?? 0, offsetY: configuration.faceOffsetY ?? 0, radiusX: 0.119, radiusY: 0.056), materials: [photoMaterial])
            panel.position = [0, -0.023, 0.010]; panel.name = "face.user-photo"; groups[.head]!.addChild(panel)
        }
        root.generateCollisionShapes(recursive: true)
        return root
    }

    private static func torsoMesh() -> MeshResource {
        var points: [SIMD3<Float>] = []
        var uv: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        let rows = 32, segments = 48
        for row in 0...rows {
            let v = Float(row) / Float(rows), a = v * Float.pi
            let y = cos(a), r = pow(max(0, sin(a)), 0.45)
            for column in 0...segments {
                let u = Float(column) / Float(segments), b = u * 2 * Float.pi
                points.append([cos(b) * r * (0.061 - y * 0.016), y * 0.056, sin(b) * r * 0.045])
                uv.append([u, v])
                if row < rows && column < segments {
                    let i = UInt32(row * (segments + 1) + column), j = i + UInt32(segments + 1)
                    indices += [i, i + 1, j, i + 1, j + 1, j]
                }
            }
        }
        var mesh = MeshDescriptor(name: "soft-flared-suit-body")
        mesh.positions = .init(points); mesh.textureCoordinates = .init(uv); mesh.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [mesh])
    }
}

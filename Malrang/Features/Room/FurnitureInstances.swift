import RealityKit
import UIKit

/// Merge repeated fixed parts into cached ordinary meshes. Low-level instance
/// components can lose their shadow bounds across renderer changes on iOS 26.4.
/// Beds keep their articulated bedding; no geometry is rebuilt per frame.
enum FurnitureInstances {
    struct Counts: Component {
        var originalModels: Int
        var batchedModels: Int
        var instances: Int
    }
    private struct Geometry: Hashable {
        var positions: [SIMD3<Float>]
        var normals: [SIMD3<Float>]
        var tangents: [SIMD3<Float>]
        var bitangents: [SIMD3<Float>]
        var uv: [SIMD2<Float>]
        var indices: [UInt32]
    }
    private struct Key: Hashable {
        var mesh: Geometry
        var color: String
        var parameters: SIMD4<Float>
        var culling: String
        var castsShadow: Bool
    }

    static func batch(_ root: Entity, kind: FurnitureKind) {
        guard kind != .bed, !ProcessInfo.processInfo.arguments.contains("--unbatched-furniture") else { return }
        var groups: [Key: [Entity]] = [:]
        func collect(_ entity: Entity) {
            if entity.children.isEmpty, entity.name != "window.sky",
               let model = entity.components[ModelComponent.self], model.materials.count == 1,
               let material = model.materials[0] as? CustomMaterial,
               model.mesh.contents.models.count == 1,
               let meshModel = model.mesh.contents.models.first, meshModel.parts.count == 1,
               let part = meshModel.parts.first, part.positions.count <= 20_000,
               model.mesh.contents.instances.allSatisfy({ $0.transform == matrix_identity_float4x4 }),
               let indices = part.triangleIndices?.elements {
                // mesh getters can return temporary wrappers; pointer identities
                // can be reused for DIFFERENT meshes. Compare geometry instead.
                let geometry = Geometry(positions: part.positions.elements, normals: part.normals?.elements ?? [],
                    tangents: part.tangents?.elements ?? [], bitangents: part.bitangents?.elements ?? [],
                    uv: part.textureCoordinates?.elements ?? [], indices: indices)
                let key = Key(mesh: geometry, color: material.baseColor.tint.description,
                              parameters: material.custom.value, culling: String(describing: material.faceCulling),
                              castsShadow: entity.components[DynamicLightShadowComponent.self]?.castsShadow ?? true)
                groups[key, default: []].append(entity)
            }
            for child in entity.children { collect(child) }
        }
        collect(root)
        var counts = Counts(originalModels: groups.values.reduce(0) { $0 + $1.count }, batchedModels: 0, instances: 0)
        for (key, entities) in groups where entities.count > 1 {
            guard let first = entities.first, let model = first.components[ModelComponent.self],
                  key.mesh.positions.count * entities.count <= 200_000 else { continue }
            let transforms = entities.map { entity in
                // Compose local transforms while the template is detached.
                var matrix = matrix_identity_float4x4
                var node: Entity? = entity
                while let current = node, current !== root {
                    matrix = current.transform.matrix * matrix
                    node = current.parent
                }
                return matrix
            }
            var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = []
            var tangents: [SIMD3<Float>] = [], bitangents: [SIMD3<Float>] = []
            var uv: [SIMD2<Float>] = [], indices: [UInt32] = []
            for transform in transforms {
                let offset = UInt32(positions.count)
                let linear = simd_float3x3(SIMD3(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z),
                                          SIMD3(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z),
                                          SIMD3(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z))
                let normalTransform = linear.inverse.transpose
                for point in key.mesh.positions {
                    let p = transform * SIMD4(point, 1)
                    positions.append([p.x, p.y, p.z])
                }
                normals += key.mesh.normals.map { simd_normalize(normalTransform * $0) }
                tangents += key.mesh.tangents.map { simd_normalize(linear * $0) }
                bitangents += key.mesh.bitangents.map { simd_normalize(linear * $0) }
                uv += key.mesh.uv
                for triangle in stride(from: 0, to: key.mesh.indices.count, by: 3) {
                    let a = key.mesh.indices[triangle] + offset
                    let b = key.mesh.indices[triangle + 1] + offset
                    let c = key.mesh.indices[triangle + 2] + offset
                    indices += linear.determinant < 0 ? [a, c, b] : [a, b, c]
                }
            }
            var descriptor = MeshDescriptor(name: "fixed-furniture-parts")
            descriptor.positions = .init(positions)
            if normals.count == positions.count { descriptor.normals = .init(normals) }
            if tangents.count == positions.count { descriptor.tangents = .init(tangents) }
            if bitangents.count == positions.count { descriptor.bitangents = .init(bitangents) }
            if uv.count == positions.count { descriptor.textureCoordinates = .init(uv) }
            descriptor.primitives = .triangles(indices)
            guard let mesh = try? MeshResource.generate(from: [descriptor]) else { continue }
            let combined = ModelEntity(mesh: mesh, materials: model.materials)
            combined.name = "fixed-furniture-parts"
            combined.components.set(DynamicLightShadowComponent(castsShadow: key.castsShadow))
            root.addChild(combined)
            for entity in entities { entity.components.remove(ModelComponent.self) }
            counts.batchedModels += entities.count - 1
            counts.instances += entities.count
        }
        root.components.set(counts)
    }
}

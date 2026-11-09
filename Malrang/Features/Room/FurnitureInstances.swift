import RealityKit
import UIKit

/// Batch repeated fixed geometry without copying vertex buffers or changing
/// model-space fleece coordinates. Beds keep their articulated bedding.
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
                  let data = try? LowLevelInstanceData(instanceCount: entities.count) else { continue }
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
            var bounds = BoundingBox()
            for transform in transforms {
                let box = model.mesh.bounds
                for x in [box.min.x, box.max.x] {
                    for y in [box.min.y, box.max.y] {
                        for z in [box.min.z, box.max.z] {
                            let p = transform * SIMD4<Float>(x, y, z, 1)
                            bounds.formUnion(BoundingBox(min: [p.x, p.y, p.z], max: [p.x, p.y, p.z]))
                        }
                    }
                }
            }
            guard let instances = try? MeshInstancesComponent(mesh: model.mesh, instances: data, bounds: bounds) else { continue }
            data.withMutableTransforms { buffer in
                for index in transforms.indices { buffer[index] = transforms[index] }
            }
            let combined = ModelEntity(mesh: model.mesh, materials: model.materials)
            combined.name = "fixed-instances"
            combined.components.set(instances)
            combined.components.set(DynamicLightShadowComponent(castsShadow: key.castsShadow))
            root.addChild(combined)
            for entity in entities { entity.components.remove(ModelComponent.self) }
            counts.batchedModels += entities.count - 1
            counts.instances += entities.count
        }
        root.components.set(counts)
    }
}

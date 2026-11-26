import RealityKit
import simd

/// Rebuilds geometry with positive transforms: reflected faces keep their winding,
/// normals and tangent basis, and photos follow the actual rounded surface.
@MainActor
enum FurnitureSurfaceGeometry {
    static func mesh(_ source: MeshResource, reflected: Bool = false, planarPhoto: Bool = false, verticalPhoto: Bool = false, singleMaterial: Bool = false) -> MeshResource {
        let content = source.contents
        var descriptors: [MeshDescriptor] = []
        let instances = Array(content.instances)
        for instance in instances {
            guard let model = content.models.first(where: { $0.id == instance.model }) else { continue }
            let transform = instance.transform
            let linear = simd_float3x3(SIMD3(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z),
                SIMD3(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z),
                SIMD3(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z))
            func direction(_ v: SIMD3<Float>, normal: Bool) -> SIMD3<Float> {
                var v = (normal ? linear.inverse.transpose : linear) * v
                if reflected { v.x = -v.x }
                return simd_normalize(v)
            }
            for part in model.parts {
                guard let triangles = part.triangleIndices?.elements else { continue }
                let points = part.positions.elements.map { p -> SIMD3<Float> in
                    let v = transform * SIMD4(p, 1)
                    return [reflected ? -v.x : v.x, v.y, v.z]
                }
                guard !points.isEmpty else { continue }
                var descriptor = MeshDescriptor(name: part.id)
                descriptor.positions = .init(points)
                if let normals = part.normals { descriptor.normals = .init(normals.elements.map { direction($0, normal: true) }) }
                if !planarPhoto && !verticalPhoto {
                    if let tangents = part.tangents { descriptor.tangents = .init(tangents.elements.map { direction($0, normal: false) }) }
                    if let bitangents = part.bitangents { descriptor.bitangents = .init(bitangents.elements.map { direction($0, normal: false) }) }
                    if let uv = part.textureCoordinates { descriptor.textureCoordinates = uv }
                } else {
                    let lo = points.reduce(SIMD3<Float>(repeating: .infinity), simd_min)
                    let hi = points.reduce(SIMD3<Float>(repeating: -.infinity), simd_max)
                    descriptor.textureCoordinates = .init(points.map { [( $0.x - lo.x) / max(0.0001, hi.x - lo.x), verticalPhoto ? 1 - ($0.y - lo.y) / max(0.0001, hi.y - lo.y) : ($0.z - lo.z) / max(0.0001, hi.z - lo.z)] })
                }
                var indices = triangles
                if reflected != (linear.determinant < 0) {
                    for i in stride(from: 0, to: indices.count, by: 3) { indices.swapAt(i + 1, i + 2) }
                }
                descriptor.primitives = .triangles(indices)
                descriptor.materials = .allFaces(singleMaterial ? 0 : UInt32(part.materialIndex))
                descriptors.append(descriptor)
            }
        }
        return (try? MeshResource.generate(from: descriptors)) ?? source
    }

    static func reflect(_ root: Entity) {
        // Retain each source while using its identity as a key. Otherwise a
        // released mesh wrapper's address can be reused by an unrelated part.
        var meshes: [ObjectIdentifier: (source: MeshResource, reflected: MeshResource)] = [:]
        func visit(_ entity: Entity) {
            entity.position.x = -entity.position.x
            let q = entity.orientation.vector
            entity.orientation = simd_quatf(vector: [q.x, -q.y, -q.z, q.w])
            if var model = entity.components[ModelComponent.self] {
                let source = model.mesh
                let key = ObjectIdentifier(source)
                let reflected = meshes[key]?.reflected ?? mesh(source, reflected: true)
                meshes[key] = (source, reflected); model.mesh = reflected
                entity.components.set(model)
            }
            for child in entity.children { visit(child) }
        }
        for child in root.children { visit(child) }
    }
}

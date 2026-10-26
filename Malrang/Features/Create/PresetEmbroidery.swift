import RealityKit

/// Continuous embroidery follows the stuffed face instead of floating in front of it.
enum PresetEmbroidery {
    static func surfaceZ(x: Float, y: Float, width: Float) -> Float {
        PresetHeadSurface.front(x: x, y: y, width: width)
    }

    static func line(_ path: [SIMD3<Float>], radius: Float, material: any Material, name: String) -> ModelEntity {
        var points: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], indices: [UInt32] = []
        let sides = 10
        for i in path.indices {
            let tangent = simd_normalize(path[min(i + 1, path.count - 1)] - path[max(0, i - 1)])
            let across = simd_normalize(simd_cross(tangent, SIMD3<Float>(0, 0, 1)))
            let outward = simd_cross(across, tangent)
            for j in 0...sides {
                let a = Float(j) / Float(sides) * 2 * .pi
                let n = across * cos(a) + outward * sin(a)
                points.append(path[i] + n * radius); normals.append(n)
                if i < path.count - 1 && j < sides {
                    let a = UInt32(i * (sides + 1) + j), b = a + UInt32(sides + 1)
                    indices += [a, b, a+1, a+1, b, b+1]
                }
            }
        }
        var mesh = MeshDescriptor(name: name)
        mesh.positions = .init(points); mesh.normals = .init(normals); mesh.primitives = .triangles(indices)
        let model = ModelEntity(mesh: try! MeshResource.generate(from: [mesh]), materials: [material]); model.name = name
        model.components.set(DynamicLightShadowComponent(castsShadow: false))
        return model
    }
}

import RealityKit

/// Opening size changes the hood and rim together; photo zoom only changes UVs.
enum PresetFaceMesh {
    static func insideOpening(_ point: SIMD3<Float>, scale: Float = 1) -> Bool {
        point.z > 0 && pow(point.x / (0.082 * scale), 2) + pow((point.y + 0.008) / (0.073 * scale), 2) < 1
    }

    static func photo(aspect: Float, zoom: Float, offsetX: Float, offsetY: Float, radiusX: Float = 0.081, radiusY: Float = 0.072) -> MeshResource {
        var points: [SIMD3<Float>] = []
        var uv: [SIMD2<Float>] = []
        var triangles: [UInt32] = []
        let rings = 16, segments = 96
        let panelAspect = radiusX / radiusY
        let visible = SIMD2<Float>(min(1, panelAspect / aspect), min(1, aspect / panelAspect)) / max(1, zoom)
        let center = SIMD2<Float>(0.5 + offsetX * (1 - visible.x), 0.5 + offsetY * (1 - visible.y))
        for ring in 0...rings {
            let r = Float(ring) / Float(rings)
            for segment in 0...segments {
                let a = Float(segment) / Float(segments) * 2 * Float.pi
                let x = cos(a) * r, y = sin(a) * r
                points.append([x * radiusX, -0.008 + y * radiusY, 0.095 + 0.004 * (1 - r * r)])
                uv.append(center + SIMD2<Float>(x * 0.5, y * 0.5) * visible)
                if ring < rings && segment < segments {
                    let i = UInt32(ring * (segments + 1) + segment), j = i + UInt32(segments + 1)
                    triangles += [i, j, i + 1, i + 1, j, j + 1]
                }
            }
        }
        var mesh = MeshDescriptor(name: "recessed-oval-photo")
        mesh.positions = .init(points); mesh.textureCoordinates = .init(uv); mesh.primitives = .triangles(triangles)
        return try! MeshResource.generate(from: [mesh])
    }

    static func rim(scale: Float = 1) -> MeshResource {
        var points: [SIMD3<Float>] = []
        var uv: [SIMD2<Float>] = []
        var triangles: [UInt32] = []
        let segments = 96, sides = 16
        for segment in 0...segments {
            let u = Float(segment) / Float(segments), a = u * 2 * Float.pi
            for side in 0...sides {
                let v = Float(side) / Float(sides), b = v * 2 * Float.pi
                points.append([cos(a) * (0.085 * scale + cos(b) * 0.009),
                               -0.008 + sin(a) * (0.076 * scale + cos(b) * 0.009),
                               0.094 + sin(b) * 0.010])
                uv.append([u, v])
                if segment < segments && side < sides {
                    let i = UInt32(segment * (sides + 1) + side), j = i + UInt32(sides + 1)
                    triangles += [i, j, i + 1, i + 1, j, j + 1]
                }
            }
        }
        var mesh = MeshDescriptor(name: "plush-hood-rim")
        mesh.positions = .init(points); mesh.textureCoordinates = .init(uv); mesh.primitives = .triangles(triangles)
        return try! MeshResource.generate(from: [mesh])
    }
}

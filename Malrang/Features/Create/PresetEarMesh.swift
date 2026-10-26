import RealityKit

/// A sewn front and back share one contour. The pink panel sits inside the padded rim.
enum PresetEarMesh {
    static func make(shape: DollShape, side: Float, fur: any Material, lining: any Material) -> [ModelEntity] {
        var contour: [SIMD2<Float>] = []
        if shape == .rabbit {
            for i in 0..<80 {
                let angle = Float(i) / 80 * 2 * Float.pi
                let t = (1 - cos(angle)) * 0.5
                let spine = 0.067 + 0.089 * t + 0.009 * sin(t * .pi)
                contour.append([spine + sin(angle) * 0.046, 0.088 - 0.208 * t])
            }
        } else {
            func curve(_ a: SIMD2<Float>, _ b: SIMD2<Float>, _ c: SIMD2<Float>, _ d: SIMD2<Float>) {
                for i in 0..<20 {
                    let t = Float(i) / 20, u = 1 - t
                    contour.append(u * u * u * a + 3 * u * u * t * b + 3 * u * t * t * c + t * t * t * d)
                }
            }
            curve([0.106, 0.130], [0.122, 0.145], [0.139, 0.143], [0.136, 0.120])
            curve([0.136, 0.120], [0.137, 0.092], [0.144, 0.064], [0.130, 0.048])
            curve([0.130, 0.048], [0.113, 0.031], [0.077, 0.030], [0.060, 0.047])
            curve([0.060, 0.047], [0.062, 0.076], [0.082, 0.110], [0.106, 0.130])
        }
        if shape == .cat { contour = contour.map { [($0.x - 0.015 * max(0, (0.13 - $0.y) / 0.09)) * 0.92, $0.y * 0.85 - 0.001] } }
        var center = contour.reduce(SIMD2<Float>.zero, +) / Float(contour.count)
        if shape == .rabbit { center.y -= 0.012 }
        if shape == .cat {
            contour = contour.map { [center.x + ($0.x - center.x) * 1.20, $0.y] }
        }
        let rings = 20, count = contour.count
        var front: [SIMD3<Float>] = [], back: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = []
        var outer: [UInt32] = [], inner: [UInt32] = [], rear: [UInt32] = []
        for ring in 0...rings {
            let r = Float(ring) / Float(rings)
            for p in contour {
                var point = center + (p - center) * r
                if shape == .rabbit {
                    let t = max(0, min(1, (r - 0.65) / 0.35))
                    point.x = center.x + (point.x - center.x) * (0.78 + 0.22 * t * t * (3 - 2 * t))
                }
                let bend = shape == .rabbit ? 0.009 * sin((0.1 - point.y) / 0.23 * .pi) : 0
                let padding: Float = (shape == .cat ? 0.032 : 0.026) * sqrt(max(0, 1 - r * r))
                let inset = 0.010 * exp(-pow(r / 0.55, 4))
                let z = 0.006 + padding - inset + bend
                front.append([side * point.x, point.y, z])
                back.append([side * point.x, point.y, 0.006 - 0.030 * sqrt(max(0, 1 - r * r)) + bend])
                uv.append([(point.x - center.x) / 0.1 + 0.5, (point.y - center.y) / (shape == .rabbit ? 0.23 : 0.1) + 0.5])
            }
        }
        for ring in 0..<rings {
            for i in 0..<count {
                let a = UInt32(ring * count + i), b = UInt32(ring * count + (i + 1) % count)
                let c = a + UInt32(count), d = b + UInt32(count)
                for triangle in [[a, b, c], [b, d, c]] {
                    var t = triangle
                    let n = simd_cross(front[Int(t[1])] - front[Int(t[0])], front[Int(t[2])] - front[Int(t[0])])
                    if n.z < 0 { t.swapAt(1, 2) }
                    if ring < (shape == .rabbit ? 13 : 9) { inner += t } else { outer += t }
                    rear += [t[0], t[2], t[1]]
                }
            }
        }
        func normals(_ points: [SIMD3<Float>], _ indices: [UInt32], fallback: SIMD3<Float>) -> [SIMD3<Float>] {
            var values = Array(repeating: SIMD3<Float>.zero, count: points.count)
            for i in stride(from: 0, to: indices.count, by: 3) {
                let a = Int(indices[i]), b = Int(indices[i + 1]), c = Int(indices[i + 2])
                let n = simd_cross(points[b] - points[a], points[c] - points[a])
                values[a] += n; values[b] += n; values[c] += n
            }
            return values.map { simd_length_squared($0) > 1e-16 ? simd_normalize($0) : fallback }
        }
        let frontNormals = normals(front, outer + inner, fallback: [0, 0, 1])
        let backNormals = normals(back, rear, fallback: [0, 0, -1])
        func entity(_ name: String, _ points: [SIMD3<Float>], _ normals: [SIMD3<Float>], _ triangles: [UInt32], _ material: any Material) -> ModelEntity {
            var descriptor = MeshDescriptor(name: name)
            descriptor.positions = .init(points); descriptor.normals = .init(normals)
            descriptor.textureCoordinates = .init(uv); descriptor.primitives = .triangles(triangles)
            let model = ModelEntity(mesh: try! MeshResource.generate(from: [descriptor]), materials: [material])
            model.name = name
            if name == "ear.padded-rim" {
                var fibers: [SIMD3<Float>] = [], fiberNormals: [SIMD3<Float>] = [], fiberIndices: [UInt32] = []
                for i in stride(from: 0, to: triangles.count, by: 3) {
                    let a = Int(triangles[i]), b = Int(triangles[i + 1]), c = Int(triangles[i + 2])
                    let area = simd_length(simd_cross(points[b] - points[a], points[c] - points[a])) * 0.5
                    let samples = max(1, Int(area * 350_000))
                    for j in 0..<samples {
                        let seed = i * 71 + j * 137
                        let u = sqrt(Float((seed * 37 + 19) % 997) / 997)
                        let v = Float((seed * 53 + 41) % 991) / 991
                        let w = SIMD3<Float>(1 - u, u * (1 - v), u * v)
                        let p = points[a] * w.x + points[b] * w.y + points[c] * w.z
                        let n = simd_normalize(normals[a] * w.x + normals[b] * w.y + normals[c] * w.z)
                        let tangent = simd_normalize(simd_cross(n, abs(n.y) > 0.9 ? SIMD3<Float>(1,0,0) : SIMD3<Float>(0,1,0)))
                        let length: Float = 0.0007 + Float(seed % 97) / 97 * 0.0008
                        let base = UInt32(fibers.count)
                        fibers += [p - tangent * 0.00015, p + tangent * 0.00015, p + n * length + tangent * 0.0002]
                        let fn = simd_normalize(n + tangent * (Float(seed % 31) / 30 - 0.5) * 0.5)
                        fiberNormals += [fn, fn, fn]
                        fiberIndices += [base, base+1, base+2, base+2, base+1, base]
                    }
                }
                var pile = MeshDescriptor(name: "ear-soft-pile")
                pile.positions = .init(fibers); pile.normals = .init(fiberNormals); pile.primitives = .triangles(fiberIndices)
                let fur = ModelEntity(mesh: try! MeshResource.generate(from: [pile]), materials: [material])
                fur.name = "ear.short-pile"; fur.components.set(DynamicLightShadowComponent(castsShadow: false))
                model.addChild(fur)
            }
            return model
        }
        return [entity("ear.padded-rim", front, frontNormals, outer, fur),
                entity("ear.inset-lining", front, frontNormals, inner, lining),
                entity("ear.sewn-back", back, backNormals, rear, fur)]
    }
}

import RealityKit

/// Smoothly joined stuffed panels keep the shoulder and paw one editable surface.
enum PresetArmMesh {
    private static var cached: [Int: (MeshResource, MeshResource?)] = [:]

    static func clearCache() { cached.removeAll() }

    static func make(side: Float, material: any Material, includePile: Bool = true) -> ModelEntity {
        let key = (side < 0 ? -1 : 1) * (includePile ? 1 : 2)
        let meshes: (MeshResource, MeshResource?)
        if let value = cached[key] {
            meshes = value
        } else {
            func ellipsoid(_ p: SIMD3<Float>, _ radii: SIMD3<Float>) -> Float {
                let k0 = simd_length(p / radii), k1 = simd_length(p / (radii * radii))
                return k1 > 0.00001 ? k0 * (k0 - 1) / k1 : -radii.min()
            }
            func field(_ p: SIMD3<Float>) -> Float {
                let paw = ellipsoid(p - SIMD3<Float>(0, 0.005, 0.012), [0.029, 0.031, 0.034])
                let q = p - SIMD3<Float>(-side * 0.013, 0.028, -0.020)
                let a = side * 0.45
                let local = SIMD3<Float>(cos(a) * q.x + sin(a) * q.y, -sin(a) * q.x + cos(a) * q.y, q.z)
                let shoulder = ellipsoid(local, [0.0235, 0.032, 0.028])
                let h = max(0, 0.014 - abs(paw - shoulder)) / 0.014
                return min(paw, shoulder) - h * h * 0.0035
            }
            func normal(_ p: SIMD3<Float>) -> SIMD3<Float> {
                let e: Float = 0.0001
                return simd_normalize(SIMD3<Float>(
                    field(p + [e, 0, 0]) - field(p - [e, 0, 0]),
                    field(p + [0, e, 0]) - field(p - [0, e, 0]),
                    field(p + [0, 0, e]) - field(p - [0, 0, e])))
            }
            let nx = 28, ny = 36, nz = 32
            let lower = SIMD3<Float>(-0.052, -0.035, -0.060)
            let step = SIMD3<Float>(0.104 / Float(nx), 0.105 / Float(ny), 0.112 / Float(nz))
            func index(_ x: Int, _ y: Int, _ z: Int) -> Int { (z * (ny + 1) + y) * (nx + 1) + x }
            var grid: [SIMD3<Float>] = [], values: [Float] = []
            for z in 0...nz { for y in 0...ny { for x in 0...nx {
                let p = lower + SIMD3<Float>(Float(x), Float(y), Float(z)) * step
                grid.append(p); values.append(field(p))
            } } }
            var points: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = [], indices: [UInt32] = []
            func triangle(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) {
                guard simd_length_squared(simd_cross(b - a, c - a)) > 1e-18 else { return }
                var vertices = [a, b, c]
                if simd_dot(simd_cross(b - a, c - a), normal((a + b + c) / 3)) < 0 { vertices.swapAt(1, 2) }
                for p in vertices {
                    indices.append(UInt32(points.count)); points.append(p); normals.append(normal(p))
                    uv.append([atan2(p.z, p.x) / (2 * .pi) + 0.5, (p.y + 0.035) / 0.105])
                }
            }
            let tetrahedra = [[0, 5, 1, 6], [0, 1, 2, 6], [0, 2, 3, 6], [0, 3, 7, 6], [0, 7, 4, 6], [0, 4, 5, 6]]
            for z in 0..<nz { for y in 0..<ny { for x in 0..<nx {
                let cube = [index(x,y,z), index(x+1,y,z), index(x+1,y+1,z), index(x,y+1,z),
                            index(x,y,z+1), index(x+1,y,z+1), index(x+1,y+1,z+1), index(x,y+1,z+1)]
                for tetrahedron in tetrahedra {
                    let nodes = tetrahedron.map { cube[$0] }
                    let inside = nodes.filter { values[$0] < 0 }, outside = nodes.filter { values[$0] >= 0 }
                    func edge(_ a: Int, _ b: Int) -> SIMD3<Float> {
                        grid[a] + (grid[b] - grid[a]) * (values[a] / (values[a] - values[b]))
                    }
                    if inside.count == 1 {
                        triangle(edge(inside[0], outside[0]), edge(inside[0], outside[1]), edge(inside[0], outside[2]))
                    } else if inside.count == 3 {
                        triangle(edge(outside[0], inside[0]), edge(outside[0], inside[1]), edge(outside[0], inside[2]))
                    } else if inside.count == 2 {
                        let a = edge(inside[0], outside[0]), b = edge(inside[0], outside[1])
                        let c = edge(inside[1], outside[0]), d = edge(inside[1], outside[1])
                        triangle(a, b, c); triangle(b, d, c)
                    }
                }
            } } }
            var mesh = MeshDescriptor(name: "continuous-stuffed-arm")
            mesh.positions = .init(points); mesh.normals = .init(normals)
            mesh.textureCoordinates = .init(uv); mesh.primitives = .triangles(indices)
            let surface = try! MeshResource.generate(from: [mesh])
            var fibers: [SIMD3<Float>] = [], fiberNormals: [SIMD3<Float>] = [], triangles: [UInt32] = []
            for i in stride(from: 0, to: includePile ? points.count : 0, by: 3) {
                let p = (points[i] + points[i+1] + points[i+2]) / 3, n = normal(p)
                let tangent = simd_normalize(simd_cross(n, abs(n.y) > 0.9 ? SIMD3<Float>(1,0,0) : SIMD3<Float>(0,1,0)))
                let length: Float = 0.0007 + Float((i * 37) % 97) / 97 * 0.0007
                let first = UInt32(fibers.count)
                fibers += [p - tangent * 0.00013, p + tangent * 0.00013, p + n * length + tangent * 0.0002]
                fiberNormals += [n, n, n]; triangles += [first, first+1, first+2, first+2, first+1, first]
            }
            var pile = MeshDescriptor(name: "arm-pile")
            pile.positions = .init(fibers); pile.normals = .init(fiberNormals); pile.primitives = .triangles(triangles)
            meshes = (surface, includePile ? try! MeshResource.generate(from: [pile]) : nil); cached[key] = meshes
        }
        let arm = ModelEntity(mesh: meshes.0, materials: [material]); arm.name = "paw"
        if let pile = meshes.1 {
            let fur = ModelEntity(mesh: pile, materials: [material]); fur.name = "arm.short-pile"
            fur.components.set(DynamicLightShadowComponent(castsShadow: false)); arm.addChild(fur)
        }
        return arm
    }
}

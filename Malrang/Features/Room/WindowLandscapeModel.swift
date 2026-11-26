import RealityKit
import UIKit

/// Continuous terrain, depth-tinted woodland and a real timber sill frame the sky.
enum WindowLandscapeModel {
    static func make(hour: Double, weather: Int, frameColor: String?) async -> Entity {
        let root = Entity(); root.name = "window.landscape"
        let overcast = weather >= 3
        let surfaces = await WindowLandscapeSurface.textures()
        func material(_ color: String, glow: Float = 0, detailScale: Float = 2) -> PhysicallyBasedMaterial {
            var value = PhysicallyBasedMaterial()
            value.baseColor.tint = Palette.uiColor(color)
            if let surfaces {
                value.baseColor.texture = .init(surfaces.color)
                value.normal = .init(texture: .init(surfaces.normal))
            }
            value.textureCoordinateTransform.scale = SIMD2(repeating: detailScale)
            value.sheen = .init(tint: UIColor(white: 0.12, alpha: 1))
            value.roughness = 0.88
            value.emissiveColor = .init(color: Palette.uiColor(color))
            value.emissiveIntensity = glow
            return value
        }
        let palette = overcast ? ["#B3CBD5", "#92B5B1", "#779C88"] : ["#B3CEDC", "#90B6AD", "#7CA184"]
        for layer in 0..<3 {
            let hill = ModelEntity(mesh: terrain(layer: layer), materials: [material(palette[layer], glow: 0.06, detailScale: 12)])
            hill.name = "landscape.ridge.\(layer)"
            hill.components.set(DynamicLightShadowComponent(castsShadow: false))
            root.addChild(hill)
        }
        let leafColors = ["#71976A", "#91AD80", "#6B9478"]
        let textile = await PresetTextile.textures()
        var bark = material("#A38A6E")
        if let grain = await RoomWoodMaterial.timberTexture() { bark.baseColor.texture = .init(grain) }
        bark.textureCoordinateTransform.scale = [2, 3]
        func foliage(_ hex: String) -> PhysicallyBasedMaterial {
            var value = material(hex)
            if let textile {
                value.baseColor.texture = .init(textile.color)
                value.normal = .init(texture: .init(textile.normal))
            }
            value.textureCoordinateTransform.scale = [3, 3]
            value.sheen = .init(tint: UIColor(white: 0.22, alpha: 1))
            return value
        }
        for i in 0..<20 {
            let x = Float(i) * 0.45 - 4.3 + sin(Float(i) * 3.1) * 0.17
            let z = -3.7 - Float((i * 5) % 7) * 0.31
            let height: Float = 0.34 + Float((i * 13) % 7) * 0.045
            // Ridges overlap in depth: root each tree on the visible upper surface.
            let y = (0..<3).filter { layer in
                let front: Float = [-6.4, -4.8, -0.3][layer]
                return z <= front && z >= front - 5
            }.map { terrainHeight(x: x, z: z, layer: $0) }.max() ?? terrainHeight(x: x, z: z, layer: 2)
            let tree = Entity(); tree.name = "landscape.tree.\(i)"; tree.position = [x, y, z]
            tree.scale = [height * (i % 3 == 0 ? 0.90 : 1.08), height, height]
            tree.orientation = simd_quatf(angle: Float(i) * 1.73, axis: [0, 1, 0])
                * simd_quatf(angle: sin(Float(i) * 2.7) * 0.055, axis: [0, 0, 1])
            let trunk = ModelEntity(mesh: WindowOrganicModels.branches, materials: [bark])
            tree.addChild(trunk)
            let parts = await WindowOrganicModels.canopy(i)
            let crown = ModelEntity(mesh: parts.body, materials: [foliage(leafColors[i % 3])])
            crown.position = [0.02, 0.66, 0]; tree.addChild(crown)
            for (tone, mesh) in parts.detail.enumerated() {
                var leafMaterial = foliage(leafColors[i % 3])
                let tint = Palette.uiColor(leafColors[i % 3])
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                tint.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                let light: CGFloat = [0.92, 1.04, 1.10][tone]
                leafMaterial.baseColor.tint = UIColor(red: min(1, red * light), green: min(1, green * light), blue: min(1, blue * light), alpha: 1)
                let leaves = ModelEntity(mesh: mesh, materials: [leafMaterial])
                leaves.position = crown.position
                leaves.components.set(DynamicLightShadowComponent(castsShadow: false))
                tree.addChild(leaves)
            }
            root.addChild(tree)
        }
        for (tone, mesh) in grass().enumerated() {
            let clump = ModelEntity(mesh: mesh, materials: [foliage(["#82A68A", "#8BAE90", "#80A486"][tone])])
            clump.name = "landscape.fine-grass.\(tone)"
            clump.components.set(DynamicLightShadowComponent(castsShadow: false))
            root.addChild(clump)
        }
        var timber = PhysicallyBasedMaterial()
        timber.baseColor.tint = Palette.uiColor(frameColor ?? "#C5AB88")
        timber.roughness = 0.68
        if let grain = await RoomWoodMaterial.timberTexture() { timber.baseColor.texture = .init(grain) }
        timber.textureCoordinateTransform.scale = [2, 1]
        let sill = ModelEntity(mesh: .generateBox(size: [2.5, 0.12, 0.70], cornerRadius: 0.035), materials: [timber])
        sill.name = "window.sill"; sill.position = [0, 0.015, -0.05]
        root.addChild(sill)
        // Side jambs remain at the edges so the landscape stays open and readable.
        for x: Float in [-1.10, 1.10] {
            let jamb = ModelEntity(mesh: .generateBox(size: [0.10, 2.8, 0.14], cornerRadius: 0.018), materials: [timber])
            jamb.position = [x, 1.42, -0.30]; root.addChild(jamb)
        }
        return root
    }

    private static func terrainHeight(x: Float, z: Float, layer: Int) -> Float {
        let phase = Float(layer) * 1.7
        let ridge = 0.25 + 0.20 * sin(x * 0.63 + phase) + 0.11 * cos(x * 1.16 - phase)
        let foregroundSlope: Float = layer == 2 ? max(0, (z + 2) / 1.7) * 0.55 : 0
        return ridge + 0.025 * sin(x*3.2+z*1.7) * cos(z*2.1-x*0.6) + 0.08 * sin(z * 0.6 + x * 0.4) - Float(2 - layer) * 0.04 - foregroundSlope
    }
    private static var grassMeshes: [MeshResource]?
    static func clearCache() { grassMeshes = nil }
    private static func grass() -> [MeshResource] {
        if let grassMeshes { return grassMeshes }
        var positions = Array(repeating: [SIMD3<Float>](), count: 3)
        var normals = positions, uv = Array(repeating: [SIMD2<Float>](), count: 3)
        var indices = Array(repeating: [UInt32](), count: 3)
        func random(_ i: Int, _ seed: Int) -> Float {
            let value = sin(Float(i)*127.1+Float(seed)*311.7)*43758.5453
            return value-floor(value)
        }
        for i in 0..<12000 {
            let x = random(i,1)*9-4.5, z = -0.8-random(i,2)*4
            // Small patches leave breathable areas of meadow, rather than a uniform carpet.
            guard sin(x*3.4+z*2.3)+cos(z*4.1-x*1.9) > -0.7 else { continue }
            let base = SIMD3<Float>(x,terrainHeight(x:x,z:z,layer:2),z), tone = i%3
            for blade in 0..<3 {
                let angle = random(i,blade+11)*2 * Float.pi
                let side = SIMD3<Float>(cos(angle),0,sin(angle))
                let lean = SIMD3<Float>(sin(angle),0,cos(angle))*(0.008+random(i,5)*0.014)
                let height: Float = 0.012+random(i,blade+21)*0.018, width: Float = 0.0015+random(i,8)*0.001
                let start = UInt32(positions[tone].count)
                for row in 0...4 {
                    let t = Float(row)/4, center = base + [0,height*t,0] + lean*t*t
                    let normal = simd_normalize(simd_cross(side,SIMD3<Float>(0,height,0)+lean*2*t))
                    for sign: Float in [-1,1] {
                        positions[tone].append(center + side*width*(1-t)*sign)
                        normals[tone].append(normal); uv[tone].append([(sign+1)*0.5,t])
                    }
                    if row < 4 {
                        let a = start+UInt32(row*2)
                        indices[tone] += [a,a+2,a+1,a+1,a+2,a+3,a+1,a+2,a,a+3,a+2,a+1]
                    }
                }
            }
        }
        grassMeshes = (0..<3).map { tone in
            var mesh = MeshDescriptor(name:"curved-meadow-blades-\(tone)")
            mesh.positions = .init(positions[tone]); mesh.normals = .init(normals[tone])
            mesh.textureCoordinates = .init(uv[tone]); mesh.primitives = .triangles(indices[tone])
            return try! MeshResource.generate(from:[mesh])
        }
        return grassMeshes!
    }

    private static func terrain(layer: Int) -> MeshResource {
        let columns = 256, rows = 96
        let front: Float = [-6.4, -4.8, -0.3][layer]
        var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for row in 0...rows {
            let v = Float(row) / Float(rows), z = front - v * 5
            for column in 0...columns {
                let u = Float(column) / Float(columns), x = (u - 0.5) * 16
                let height = terrainHeight(x: x, z: z, layer: layer)
                let dx = (terrainHeight(x: x + 0.01, z: z, layer: layer) - terrainHeight(x: x - 0.01, z: z, layer: layer)) / 0.02
                let dz = (terrainHeight(x: x, z: z + 0.01, layer: layer) - terrainHeight(x: x, z: z - 0.01, layer: layer)) / 0.02
                positions.append([x, height, z]); normals.append(simd_normalize([-dx, 1, -dz])); uv.append([u, v])
                if row < rows && column < columns {
                    let a = UInt32(row * (columns + 1) + column), b = a + UInt32(columns + 1)
                    indices += [a, a + 1, b, a + 1, b + 1, b]
                }
            }
        }
        // Close the perimeter below the horizon; no sky may show beneath a hill.
        let perimeter = Array(0...columns)
            + (1...rows).map { $0 * (columns + 1) + columns }
            + (0..<columns).reversed().map { rows * (columns + 1) + $0 }
            + (1..<rows).reversed().map { $0 * (columns + 1) }
        for i in perimeter.indices {
            let a = positions[perimeter[i]], b = positions[perimeter[(i + 1) % perimeter.count]]
            let start = UInt32(positions.count)
            let normal = simd_normalize(simd_cross(SIMD3<Float>(0, -1, 0), b - a))
            positions += [a, b, [b.x, -3, b.z], [a.x, -3, a.z]]
            normals += Array(repeating: normal, count: 4)
            uv += [[0, 0], [1, 0], [1, 1], [0, 1]]
            indices += [start, start + 2, start + 1, start, start + 3, start + 2]
        }
        var descriptor = MeshDescriptor(name: "continuous-landscape-ridge")
        descriptor.positions = .init(positions); descriptor.normals = .init(normals)
        descriptor.textureCoordinates = .init(uv); descriptor.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [descriptor])
    }
}

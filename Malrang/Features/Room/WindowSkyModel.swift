import RealityKit
import UIKit

/// Closed 3D clouds and celestial bodies sit behind the real doll models.
enum WindowSkyModel {
    struct Scene {
        let root: Entity
        let clouds: [Entity]
    }

    /// A shared smooth mesh prevents angular silhouettes on large clouds and tree crowns.
    static let smoothSphere: MeshResource = {
        let rows = 32, columns = 64
        var points: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for row in 0...rows {
            let v = Float(row) / Float(rows), latitude = v * .pi
            for column in 0...columns {
                let u = Float(column) / Float(columns), longitude = u * 2 * .pi
                let n = SIMD3<Float>(sin(latitude) * cos(longitude), cos(latitude), sin(latitude) * sin(longitude))
                points.append(n * 0.5); normals.append(n); uv.append([u, v])
                if row < rows && column < columns {
                    let a = UInt32(row * (columns + 1) + column), b = a + UInt32(columns + 1)
                    indices += [a, a + 1, b, a + 1, b + 1, b]
                }
            }
        }
        var mesh = MeshDescriptor(name: "smooth-landscape-volume")
        mesh.positions = .init(points); mesh.normals = .init(normals)
        mesh.textureCoordinates = .init(uv); mesh.primitives = .triangles(indices)
        return (try? MeshResource.generate(from: [mesh])) ?? .generateSphere(radius: 0.5)
    }()

    static func make(hour: Double, weather: Int = 0) async -> Scene {
        let root = Entity(); root.name = "window.sky"
        root.addChild(await WindowAtmosphere.dome(hour: hour, weather: weather))

        func soft(_ hex: String, glow: Float = 0) -> PhysicallyBasedMaterial {
            var material = PhysicallyBasedMaterial()
            material.baseColor.tint = Palette.uiColor(hex)
            material.roughness = 1.0
            material.emissiveColor = .init(color: Palette.uiColor(hex))
            material.emissiveIntensity = glow
            return material
        }
        func sphere(_ name: String, size: SIMD3<Float>, position: SIMD3<Float>, material: any Material, parent: Entity) {
            let node = ModelEntity(mesh: smoothSphere, materials: [material])
            node.name = name; node.scale = size; node.position = position
            node.components.set(DynamicLightShadowComponent(castsShadow: false)); parent.addChild(node)
        }
        var clouds: [Entity] = []
        let textile = await PresetTextile.textures()
        var cloudMaterial = soft("#FFFFFF", glow: 0.025)
        if let textile {
            cloudMaterial.baseColor.texture = .init(textile.color)
            cloudMaterial.normal = .init(texture: .init(textile.normal))
        }
        cloudMaterial.textureCoordinateTransform.scale = [5, 3]
        cloudMaterial.sheen = .init(tint: UIColor(white: 0.35, alpha: 1))
        let fiberMaterial = soft("#FFFFFF", glow: 0.025)
        for i in 0..<6 {
            let cloud = Entity(); cloud.name = "sky.cloud.\(i)"
            let scale: Float = [0.82, 0.60, 0.93, 0.54, 0.76, 0.65][i]
            cloud.scale = [scale, scale * (i % 2 == 0 ? 1 : 0.86), scale]
            cloud.position = [Float(i % 3) * 1.25 - 1.35, [Float(1.42), 0.82, 1.94, 1.10, 2.35, 1.60][i], -3.6 - Float(i % 2) * 0.8]
            cloud.orientation = simd_quatf(angle: Float(i - 2) * 0.07, axis: [0, 1, 0])
            let parts = await WindowOrganicModels.cloud(i)
            let body = ModelEntity(mesh: parts.body, materials: [cloudMaterial])
            body.name = "cloud.continuous-cotton"; cloud.addChild(body)
            for mesh in parts.detail {
                let fiber = ModelEntity(mesh: mesh, materials: [fiberMaterial])
                fiber.components.set(DynamicLightShadowComponent(castsShadow: false)); cloud.addChild(fiber)
            }
            root.addChild(cloud); clouds.append(cloud)
        }
        do {
            var moonMaterial = soft("#FFF0CD", glow: 0.16)
            if let textile {
                moonMaterial.baseColor.texture = .init(textile.color)
                moonMaterial.normal = .init(texture: .init(textile.normal))
            }
            moonMaterial.sheen = .init(tint: UIColor(white: 0.4, alpha: 1))
            let moon = ModelEntity(mesh: WindowAtmosphere.moon, materials: [moonMaterial])
            moon.name = "sky.crescent"
            moon.position = SIMD3<Float>(0, 0.68, 2.15) + (SIMD3<Float>(-0.64, 1.88, -3.2) - [0, 0.68, 2.15]) * 2
            moon.scale = SIMD3(repeating: 2)
            moon.orientation = simd_quatf(angle: -0.25, axis: [0, 0, 1]); root.addChild(moon)
            let starRoot = Entity(); starRoot.name = "sky.stars"; root.addChild(starRoot)
            let starMesh = sparkle()
            for i in 0..<43 {
                let star = ModelEntity(mesh: starMesh, materials: [soft(i % 4 == 0 ? "#FFE6B6" : "#EDF3FF", glow: 0.8)])
                star.name = "sky.star.\(i)"
                star.position = [Float((i * 47 + 13) % 101) / 100 * 4.8 - 2.4,
                                 Float((i * 31 + 7) % 97) / 96 * 2.7 + 0.48, -4.8]
                star.scale = SIMD3(repeating: i % 7 == 0 ? 0.030 : 0.012)
                star.position = SIMD3<Float>(0, 0.68, 2.15) + (star.position - [0, 0.68, 2.15]) * 2
                star.scale *= 2
                starRoot.addChild(star)
            }
        }
        do {
            var sunMaterial = soft("#FFF2CE", glow: 0.18)
            if let textile {
                sunMaterial.baseColor.texture = .init(textile.color)
                sunMaterial.normal = .init(texture: .init(textile.normal))
            }
            sunMaterial.textureCoordinateTransform.scale = [2, 2]
            let distantSun = SIMD3<Float>(0, 0.68, 2.15) + (WindowAtmosphere.sunPosition(hour: hour) - [0, 0.68, 2.15]) * 2
            sphere("sky.sun", size: [0.68, 0.68, 0.60], position: distantSun,
                   material: sunMaterial, parent: root)
        }
        return Scene(root: root, clouds: clouds)
    }

    static func addBirds(to root: Entity) -> [Entity] {
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = Palette.uiColor("#52648C")
        material.roughness = 1.0
        return (0..<3).map { i in
            let bird = Entity(); bird.name = "sky.bird.\(i)"
            bird.position = [-1.6 - Float(i) * 0.30, 1.38 + Float(i) * 0.11, -3.0 - Float(i) * 0.25]
            let body = ModelEntity(mesh: smoothSphere, materials: [material])
            body.scale = [0.06, 0.025, 0.025]; bird.addChild(body)
            for (side, name) in [(Float(-1), "wing.left"), (Float(1), "wing.right")] {
                let wing = Entity(); wing.name = name
                let feather = ModelEntity(mesh: smoothSphere, materials: [material])
                feather.scale = [0.03, 0.012, 0.095]; feather.position.z = side * 0.035
                wing.addChild(feather); bird.addChild(wing)
            }
            root.addChild(bird)
            return bird
        }
    }

    private static func sparkle() -> MeshResource {
        let points: [SIMD3<Float>] = [[0, 0, 0.10], [0, 0, -0.10], [0, 1, 0], [0.22, 0.22, 0],
                                     [0.7, 0, 0], [0.22, -0.22, 0], [0, -1, 0], [-0.22, -0.22, 0], [-0.7, 0, 0], [-0.22, 0.22, 0]]
        var indices: [UInt32] = []
        for i: UInt32 in 2..<10 {
            let next: UInt32 = i == 9 ? 2 : i + 1
            indices += [0, next, i, 1, i, next]
        }
        var mesh = MeshDescriptor(name: "four-point-star")
        mesh.positions = .init(points); mesh.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [mesh])
    }
}

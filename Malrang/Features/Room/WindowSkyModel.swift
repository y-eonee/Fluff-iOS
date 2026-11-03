import RealityKit
import UIKit

/// Closed 3D clouds and celestial bodies sit behind the real doll models.
enum WindowSkyModel {
    struct Scene {
        let root: Entity
        let clouds: [Entity]
    }

    static func make(hour: Int) async -> Scene {
        let root = Entity(); root.name = "window.sky"
        let night = hour < 6 || hour >= 20
        let sunset = (17..<20).contains(hour)
        let colors = night ? ["#192B50", "#52648C", "#A1A0BA"]
            : sunset ? ["#8797CA", "#EDB8BA", "#F6D4B3"] : ["#87BDD9", "#BBDDE8", "#E4EBDF"]
        let image = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 512)).image { context in
            let cg = context.cgContext
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors.map { Palette.uiColor($0).cgColor } as CFArray, locations: [0, 0.62, 1])!
            cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 512), options: [])
        }
        var sky = UnlitMaterial(applyPostProcessToneMap: false)
        sky.faceCulling = .front
        if let cg = image.cgImage, let texture = try? await TextureResource(image: cg, options: .init(semantic: .color)) {
            sky.color = .init(tint: .white, texture: .init(texture))
        }
        let dome = ModelEntity(mesh: .generateSphere(radius: 20), materials: [sky])
        dome.name = "sky.atmosphere"; root.addChild(dome)

        func soft(_ hex: String, glow: Float = 0) -> PhysicallyBasedMaterial {
            var material = PhysicallyBasedMaterial()
            material.baseColor.tint = Palette.uiColor(hex)
            material.roughness = 1.0
            material.emissiveColor = .init(color: Palette.uiColor(hex))
            material.emissiveIntensity = glow
            return material
        }
        func sphere(_ name: String, size: SIMD3<Float>, position: SIMD3<Float>, material: any Material, parent: Entity) {
            let node = ModelEntity(mesh: .generateSphere(radius: 0.5), materials: [material])
            node.name = name; node.scale = size; node.position = position; parent.addChild(node)
        }
        var clouds: [Entity] = []
        let cloudMaterial = soft(night ? "#A8B3D0" : sunset ? "#FFE3D2" : "#FFF9EF", glow: night ? 0.18 : 0.08)
        for i in 0..<6 {
            let cloud = Entity(); cloud.name = "sky.cloud.\(i)"
            let scale: Float = i % 2 == 0 ? 0.90 : 0.62
            cloud.scale = SIMD3(repeating: scale)
            cloud.position = [Float(i % 3) * 1.25 - 1.35, [Float(1.42), 0.82, 1.94, 1.10, 2.35, 1.60][i], -3.4 - Float(i % 2) * 0.7]
            sphere("cloud.base", size: [0.86, 0.22, 0.26], position: [0, 0, 0], material: cloudMaterial, parent: cloud)
            for (size, at) in [
                (SIMD3<Float>(0.32, 0.30, 0.28), SIMD3<Float>(-0.25, 0.06, 0)),
                (SIMD3<Float>(0.40, 0.43, 0.34), SIMD3<Float>(-0.04, 0.15, -0.02)),
                (SIMD3<Float>(0.34, 0.32, 0.28), SIMD3<Float>(0.20, 0.09, 0))
            ] { sphere("cloud.puff", size: size, position: at, material: cloudMaterial, parent: cloud) }
            root.addChild(cloud); clouds.append(cloud)
        }
        if night {
            let moon = ModelEntity(mesh: crescent(), materials: [soft("#FFF0CA", glow: 0.9)])
            moon.name = "sky.crescent"; moon.position = [-0.64, 1.88, -3.2]
            moon.orientation = simd_quatf(angle: -0.25, axis: [0, 0, 1]); root.addChild(moon)
            let starMesh = sparkle()
            for i in 0..<43 {
                let star = ModelEntity(mesh: starMesh, materials: [soft(i % 4 == 0 ? "#FFE6B6" : "#EDF3FF", glow: 0.8)])
                star.name = "sky.star.\(i)"
                star.position = [Float((i * 47 + 13) % 101) / 100 * 4.8 - 2.4,
                                 Float((i * 31 + 7) % 97) / 96 * 2.7 + 0.48, -4.8]
                star.scale = SIMD3(repeating: i % 7 == 0 ? 0.030 : 0.012)
                root.addChild(star)
            }
        } else {
            sphere("sky.sun", size: [0.34, 0.34, 0.14], position: [sunset ? -0.36 : -0.66, sunset ? 0.62 : 1.88, -3.5],
                   material: soft(sunset ? "#FFD5A2" : "#FFF0C3", glow: 0.8), parent: root)
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
            let body = ModelEntity(mesh: .generateSphere(radius: 0.5), materials: [material])
            body.scale = [0.06, 0.025, 0.025]; bird.addChild(body)
            for (side, name) in [(Float(-1), "wing.left"), (Float(1), "wing.right")] {
                let wing = Entity(); wing.name = name
                let feather = ModelEntity(mesh: .generateSphere(radius: 0.5), materials: [material])
                feather.scale = [0.03, 0.012, 0.095]; feather.position.z = side * 0.035
                wing.addChild(feather); bird.addChild(wing)
            }
            root.addChild(bird)
            return bird
        }
    }

    private static func crescent() -> MeshResource {
        let count = 64, radius: Float = 0.21, shift: Float = 0.12
        let angle = acos(shift / (2 * radius))
        var points: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], indices: [UInt32] = []
        for side: Float in [1, -1] {
            for i in 0...count {
                let t = Float(i) / Float(count)
                let outer = angle + t * (2 * .pi - 2 * angle)
                let inner = .pi - angle + t * 2 * angle
                points += [[radius * cos(outer), radius * sin(outer), side * 0.012],
                           [shift + radius * cos(inner), radius * sin(inner), side * 0.012]]
                normals += [[0, 0, side], [0, 0, side]]
            }
        }
        let back = UInt32((count + 1) * 2)
        for i in 0..<count {
            let a = UInt32(i * 2), b = a + 2
            indices += [a, b, a + 1, a + 1, b, b + 1,
                        back + a, back + a + 1, back + b, back + a + 1, back + b + 1, back + b]
            for edge: UInt32 in [0, 1] {
                indices += [a + edge, back + a + edge, b + edge, b + edge, back + a + edge, back + b + edge]
            }
        }
        var mesh = MeshDescriptor(name: "closed-crescent")
        mesh.positions = .init(points); mesh.normals = .init(normals); mesh.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [mesh])
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

import RealityKit
import UIKit

/// The reference radio is modeled as a padded case, woven grille and separate controls.
@MainActor enum RadioModel {
    static func make(playing: Bool) async -> Entity {
        let root = Entity(); root.name = "radio"
        let texture = try? await TextureResource(named: "CozyFabricColor")
        let normal = try? await TextureResource(named: "CozyFabricNormal", options: .init(semantic: .normal))
        func fabric(_ hex: String) -> PhysicallyBasedMaterial {
            var m = PhysicallyBasedMaterial()
            m.baseColor.tint = Palette.uiColor(hex); m.roughness = 0.96
            if let texture { m.baseColor.texture = .init(texture) }
            if let normal { m.normal.texture = .init(normal) }
            return m
        }
        func solid(_ hex: String, metallic: Float = 0) -> PhysicallyBasedMaterial {
            var m = fabric(hex); m.baseColor.texture = nil; m.normal.texture = nil
            m.metallic = .init(floatLiteral: metallic); m.roughness = metallic > 0 ? 0.35 : 0.75
            return m
        }
        func add(_ name: String, mesh: MeshResource, at position: SIMD3<Float>, material: PhysicallyBasedMaterial) -> ModelEntity {
            let model = ModelEntity(mesh: mesh, materials: [material]); model.name = name; model.position = position
            root.addChild(model); return model
        }
        let cream = fabric("#F3DFBA"), sage = solid("#9EAA84"), gold = solid("#C5AD77", metallic: 0.35)
        _ = add("radio.case", mesh: paddedCase(size: [0.37, 0.27, 0.17]), at: [0, 0.153, 0], material: cream)
        _ = add("radio.front", mesh: paddedCase(size: [0.348, 0.245, 0.036]), at: [0, 0.153, 0.077], material: fabric("#F7E8CA"))
        for x: Float in [-0.125, 0.125] {
            _ = add("radio.foot", mesh: .generateSphere(radius: 0.019), at: [x, 0.018, 0], material: sage).scale = [1, 0.72, 0.85]
        }
        let speaker = Entity(); speaker.name = "radio.speaker"; speaker.position = [-0.077, 0.155, 0.094]; root.addChild(speaker)
        let backing = ModelEntity(mesh: .generateSphere(radius: 0.080), materials: [fabric("#B69A75")]); backing.scale.z = 0.09; speaker.addChild(backing)
        let rim = ModelEntity(mesh: ring(radius: 0.081, tube: 0.007), materials: [sage]); speaker.addChild(rim)
        let inner = ModelEntity(mesh: ring(radius: 0.074, tube: 0.002), materials: [gold]); inner.position.z = 0.005; speaker.addChild(inner)
        for index in -11...11 {
            let offset = Float(index) * 0.006
            let half = sqrt(max(0, 0.072 * 0.072 - offset * offset))
            for horizontal in [true, false] {
                let strand = ModelEntity(mesh: .generateCylinder(height: half * 2, radius: 0.0014), materials: [fabric(index.isMultiple(of: 2) ? "#D6B58D" : "#B9976D")])
                strand.name = "radio.grille-strand"
                strand.position = horizontal ? [0, offset, 0.009] : [offset, 0, 0.011]
                if horizontal { strand.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1]) }
                speaker.addChild(strand)
            }
        }
        _ = add("radio.tuning-recess", mesh: .generateBox(size: [0.112, 0.036, 0.014], cornerRadius: 0.015), at: [0.095, 0.205, 0.097], material: solid("#B6B894"))
        _ = add("radio.tuning-scale", mesh: .generateBox(size: [0.094, 0.013, 0.004], cornerRadius: 0.005), at: [0.095, 0.205, 0.106], material: solid("#697F68"))
        for i in 0..<9 {
            _ = add("radio.tuning-tick", mesh: .generateBox(size: [0.001, i.isMultiple(of: 2) ? 0.009 : 0.005, 0.001]), at: [0.054 + Float(i) * 0.01, 0.205, 0.109], material: solid("#E7D5B2"))
        }
        _ = add("radio.tuning-slider", mesh: .generateBox(size: [0.025, 0.025, 0.012], cornerRadius: 0.007), at: [playing ? 0.098 : 0.084, 0.205, 0.115], material: sage)
        let knob = add("radio.volume", mesh: .generateCylinder(height: 0.020, radius: 0.027), at: [0.100, 0.114, 0.107], material: sage)
        knob.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        let knobFace = add("radio.volume-face", mesh: .generateSphere(radius: 0.023), at: [0.100, 0.114, 0.12], material: fabric("#AAB68D")); knobFace.scale.z = 0.2
        _ = add("radio.volume-mark", mesh: .generateBox(size: [0.002, 0.010, 0.001], cornerRadius: 0.0005), at: [0.100, 0.128, 0.126], material: solid("#EDE1BD"))
        var indicator = solid(playing ? "#A6C6A2" : "#B9B79B")
        if playing { indicator.emissiveColor = .init(color: Palette.uiColor("#B7CF94")); indicator.emissiveIntensity = 0.35 }
        _ = add("radio.power", mesh: .generateSphere(radius: 0.005), at: [0.143, 0.114, 0.103], material: indicator)
        let antenna = Entity(); antenna.name = "radio.antenna"; antenna.position = [0.120, 0.278, -0.035]
        antenna.orientation = simd_quatf(angle: -0.27, axis: [0, 0, 1]); root.addChild(antenna)
        for (height, y, radius) in [(Float(0.070), Float(0.035), Float(0.0045)), (0.075, 0.105, 0.003)] {
            let rod = ModelEntity(mesh: .generateCylinder(height: height, radius: radius), materials: [gold]); rod.position.y = y; antenna.addChild(rod)
        }
        let tip = ModelEntity(mesh: .generateSphere(radius: 0.006), materials: [sage]); tip.position.y = 0.145; antenna.addChild(tip)
        return root
    }

    private static func paddedCase(size: SIMD3<Float>) -> MeshResource {
        var vertices: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = [], indices: [UInt32] = []
        for i in 0...32 { for j in 0...64 {
            let latitude = Float(i) / 32 * .pi - .pi / 2, longitude = Float(j) / 64 * 2 * .pi
            let direction = SIMD3(cos(latitude) * cos(longitude), sin(latitude), cos(latitude) * sin(longitude))
            let power = direction * direction * direction * direction
            let shape = direction / pow(power.x + power.y + power.z, 0.25)
            vertices.append(shape * size / 2)
            normals.append(simd_normalize(shape * shape * shape / size))
            uv.append([Float(j) / 64 * 6, Float(i) / 32 * 6])
            if i < 32, j < 64 { let p = UInt32(i * 65 + j); indices += [p, p + 65, p + 1, p + 1, p + 65, p + 66] }
        } }
        var mesh = MeshDescriptor(name: "radio.padded-case")
        mesh.positions = .init(vertices); mesh.normals = .init(normals); mesh.textureCoordinates = .init(uv); mesh.primitives = .triangles(indices)
        return (try? MeshResource.generate(from: [mesh])) ?? .generateBox(size: size, cornerRadius: 0.06)
    }

    private static func ring(radius: Float, tube: Float) -> MeshResource {
        var vertices: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], indices: [UInt32] = []
        for i in 0...72 { for j in 0...12 {
            let a = Float(i) / 72 * 2 * .pi, b = Float(j) / 12 * 2 * .pi
            let normal = SIMD3(cos(a) * cos(b), sin(a) * cos(b), sin(b))
            vertices.append([cos(a) * radius + normal.x * tube, sin(a) * radius + normal.y * tube, normal.z * tube]); normals.append(normal)
            if i < 72, j < 12 { let p = UInt32(i * 13 + j); indices += [p, p + 13, p + 1, p + 1, p + 13, p + 14] }
        } }
        var mesh = MeshDescriptor(name: "radio.circular-trim")
        mesh.positions = .init(vertices); mesh.normals = .init(normals); mesh.primitives = .triangles(indices)
        return (try? MeshResource.generate(from: [mesh])) ?? .generateSphere(radius: radius)
    }
}

import RealityKit
import UIKit

enum FurnitureSceneB {
    private static var meshes: [FurnitureKind: [MeshResource]] = [:]
    private static var studio: EnvironmentResource?
    private static var contactMask: TextureResource?

    static func make(_ item: RoomItemState, photoMaterial: any RealityKit.Material) async -> Entity {
        let parts = FurnitureModelB.parts(for: item.kind)
        if meshes[item.kind] == nil {
            meshes[item.kind] = parts.map { part in
                switch part.shape {
                case .box: .generateBox(size: part.size, cornerRadius: min(part.radius, part.size.min() / 3))
                case .sphere: .generateSphere(radius: 0.5)
                case .cylinder: .generateCylinder(height: 1, radius: 0.5)
                case .cone: shadeMesh()
                }
            }
        }
        let root = Entity()
        for (index, part) in parts.enumerated() {
            if part.pattern && item.photoData != nil { continue }
            var material = PhysicallyBasedMaterial()
            material.faceCulling = .none
            material.baseColor = .init(tint: Palette.uiColor(part.custom ? item.colorName ?? part.color : part.color))
            material.roughness = 0.88
            material.metallic = 0.0
            // 원본의 간접광처럼 밝은 침구가 가구 방향 때문에 회색으로 가라앉지 않게 한다.
            if item.kind == .bed && !part.custom && ["#FFFDF2", "#FFF1BE", "#FFF4D8"].contains(part.color) {
                material.emissiveColor = .init(color: Palette.uiColor(part.color))
                material.emissiveIntensity = 0.6
            }
            if part.glow {
                material.emissiveColor = .init(color: Palette.uiColor("#FFF4D8"))
                material.emissiveIntensity = 1.1
            }
            let finish: any RealityKit.Material = part.photo && item.photoData != nil ? photoMaterial : material
            let entity = ModelEntity(mesh: meshes[item.kind]![index], materials: [finish])
            entity.position = part.position
            if part.shape != .box { entity.scale = part.size }
            root.addChild(entity)
            if part.glow {
                let bulb = PointLight()
                bulb.light.color = Palette.uiColor("#FFDC8D")
                bulb.light.intensity = 620
                bulb.light.attenuationRadius = 0.7
                bulb.position = part.position - [0, part.size.y * 0.35, 0]
                root.addChild(bulb)
                let pool = SpotLight()
                pool.light.color = Palette.uiColor("#FFF1AA")
                pool.light.intensity = 420
                pool.light.innerAngleInDegrees = 35
                pool.light.outerAngleInDegrees = 105
                pool.light.attenuationRadius = 0.8
                pool.shadow = nil
                let position = part.position - [0, part.size.y * 0.48, 0]
                pool.look(at: position - [0, 1, 0], from: position, relativeTo: root)
                root.addChild(pool)
                // 갓 위로 반사되는 빛이 가까운 벽에 부드럽게 퍼진다.
                let rotation = simd_quatf(angle: item.yaw, axis: [0, 1, 0])
                let mirror: Float = item.isMirrored ? -1 : 1
                let world = rotation.act(position * [mirror, 1, 1]) + [item.x, 0, item.z]
                let leftWall = world.x < world.z
                let wallDistance = leftWall ? world.x + 1 : world.z + 1
                if wallDistance < 0.6 {
                    let target = SIMD3<Float>(leftWall ? -0.995 : world.x, min(1.45, world.y + 0.55), leftWall ? world.z : -0.995)
                    let direction = rotation.inverse.act(target - world) * [mirror, 1, 1]
                    let wash = SpotLight()
                    wash.light.color = Palette.uiColor("#FFF5BB")
                    wash.light.intensity = 520
                    wash.light.innerAngleInDegrees = 20
                    wash.light.outerAngleInDegrees = 100
                    wash.light.attenuationRadius = 1.3
                    wash.shadow = nil
                    wash.look(at: position + direction, from: position, relativeTo: root)
                    root.addChild(wash)
                }
            }
        }
        if item.kind.isMovable, let shadow = await contactShadow(for: item.kind) {
            root.addChild(shadow)
        }
        return root
    }

    private static func contactShadow(for kind: FurnitureKind) async -> Entity? {
        if contactMask == nil {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            let image = UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128), format: format).image { context in
                UIColor.black.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 128, height: 128))
                let colors = [UIColor.white.cgColor, UIColor(white: 0.55, alpha: 1).cgColor, UIColor.black.cgColor] as CFArray
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.5, 1]) {
                    context.cgContext.drawRadialGradient(gradient, startCenter: CGPoint(x: 64, y: 64), startRadius: 0,
                                                        endCenter: CGPoint(x: 64, y: 64), endRadius: 64, options: [])
                }
            }
            if let image = image.cgImage { contactMask = try? await TextureResource(image: image, options: .init(semantic: .raw)) }
        }
        guard let contactMask else { return nil }
        var material = UnlitMaterial(applyPostProcessToneMap: false)
        material.color = .init(tint: Palette.uiColor("#74512F"))
        material.blending = .transparent(opacity: .init(scale: 0.25, texture: .init(contactMask)))
        material.faceCulling = .none
        let size = kind.size
        let shadow: ModelEntity
        if kind.hangsOnWall {
            shadow = ModelEntity(mesh: .generatePlane(width: size.x * 1.3, height: size.y * 1.5), materials: [material])
            shadow.position = [0.025, size.y * 0.35, -size.z / 2 - 0.004]
        } else {
            shadow = ModelEntity(mesh: .generatePlane(width: size.x * 1.15, depth: size.z * 1.15), materials: [material])
            shadow.position.y = 0.0005
        }
        return shadow
    }

    private static func shadeMesh() -> MeshResource {
        let count = 32
        var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = []
        var uv: [SIMD2<Float>] = [], triangles: [UInt32] = []
        for i in 0...count {
            let angle = Float(i) / Float(count) * 2 * .pi
            for (radius, y): (Float, Float) in [(0.5, -0.5), (0.23, 0.5)] {
                positions.append([cos(angle) * radius, y, sin(angle) * radius])
                normals.append(simd_normalize([cos(angle), 0.27, sin(angle)]))
                uv.append([Float(i) / Float(count), y + 0.5])
            }
            if i < count {
                let k = UInt32(i * 2)
                triangles += [k, k + 1, k + 2, k + 1, k + 3, k + 2]
            }
        }
        for (radius, y): (Float, Float) in [(0.5, -0.5), (0.23, 0.5)] {
            let center = UInt32(positions.count)
            positions.append([0, y, 0]); normals.append([0, y > 0 ? 1 : -1, 0]); uv.append([0.5, 0.5])
            for i in 0...count {
                let angle = Float(i) / Float(count) * 2 * .pi
                positions.append([cos(angle) * radius, y, sin(angle) * radius])
                normals.append([0, y > 0 ? 1 : -1, 0]); uv.append([0.5 + cos(angle) * 0.5, 0.5 + sin(angle) * 0.5])
                if i < count {
                    let k = center + 1 + UInt32(i)
                    triangles += y > 0 ? [center, k + 1, k] : [center, k, k + 1]
                }
            }
        }
        var descriptor = MeshDescriptor(name: "B lamp shade")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uv)
        descriptor.primitives = .triangles(triangles)
        return (try? MeshResource.generate(from: [descriptor])) ?? .generateCone(height: 1, radius: 0.5)
    }

    static func light(_ view: ARView) async {
        if studio == nil {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let image = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 256), format: format).image { context in
                let colors = [Palette.uiColor("#FFFDF8").cgColor, Palette.uiColor("#B6ADA0").cgColor] as CFArray
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                    context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 256), options: [])
                }
            }
            if let cgImage = image.cgImage {
                studio = try? await EnvironmentResource(equirectangular: cgImage, withName: "B soft studio")
            }
        }
        view.environment.lighting.resource = studio
        view.environment.lighting.intensityExponent = 0.15
    }

    static func board() -> Entity {
        let board = Entity()
        board.name = "board"
        board.position = [-0.972, 1.02, -0.24]
        var material = UnlitMaterial(applyPostProcessToneMap: false)
        material.color = .init(tint: Palette.uiColor("#FFFDF3"))
        board.addChild(ModelEntity(mesh: .generateBox(size: [0.018, 0.50, 0.55], cornerRadius: 0.005), materials: [material]))
        let pin = ModelEntity(mesh: .generateSphere(radius: 0.007), materials: [SimpleMaterial(color: Palette.uiColor("#BD8756"), roughness: 0.8, isMetallic: false)])
        pin.position = [0.014, 0.03, 0]
        board.addChild(pin)
        // 밝은 보드와 구분되는 큰 메모지와 진한 필기선. 조명에 묻히지 않도록 무광으로 그린다.
        func paper(y: Float, z: Float, color: String, angle: Float) {
            let note = Entity()
            note.position = [0.017, y, z]
            note.orientation = simd_quatf(angle: angle, axis: [1, 0, 0])
            func tile(_ size: SIMD3<Float>, _ position: SIMD3<Float>, _ color: String) {
                var ink = UnlitMaterial(applyPostProcessToneMap: false)
                ink.color = .init(tint: Palette.uiColor(color))
                let piece = ModelEntity(mesh: .generateBox(size: size, cornerRadius: 0.001), materials: [ink])
                piece.position = position
                note.addChild(piece)
            }
            tile([0.002, 0.164, 0.175], [0, -0.004, -0.004], "#D9BE91")
            tile([0.003, 0.16, 0.17], [0.003, 0, 0], color)
            tile([0.004, 0.025, 0.065], [0.006, 0.074, 0], "#D49B61")
            for (index, width) in [Float(0.11), 0.095, 0.065].enumerated() {
                tile([0.004, 0.005, width], [0.006, 0.03 - Float(index) * 0.03, (0.11 - width) / 2], "#91613C")
            }
            board.addChild(note)
        }
        paper(y: 0.095, z: -0.12, color: "#FFE299", angle: -0.08)
        paper(y: 0.06, z: 0.105, color: "#FAD4BA", angle: 0.07)
        paper(y: -0.125, z: -0.005, color: "#FFF0BC", angle: -0.04)
        board.components.set(CollisionComponent(shapes: [.generateBox(size: [0.04, 0.5, 0.55])]))
        return board
    }
}

import RealityKit
import UIKit
import Metal

/// 고정된 홈 카메라에서도 실제 깊이와 가림이 생기는, 부위별로 분리된 가구.
/// 저장 좌표·충돌 범위·앉는 높이는 기존 FurnitureKind와 함께 쓴다.
enum CozyFurniture {
    static func clearCache() { meshes.removeAll(); bakedModels.removeAll(); fabricColor = nil; fabricNormal = nil; contactShadow = nil; windowSky = nil }

    private static let fabricShader: CustomMaterial.SurfaceShader? = {
        guard let library = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary(),
              library.makeFunction(name: "cozyFabric") != nil else { return nil }
        return CustomMaterial.SurfaceShader(named: "cozyFabric", in: library)
    }()
    private static var meshes: [String: MeshResource] = [:]
    private static var bakedModels: [FurnitureKind: Entity] = [:]
    private static var fabricColor: TextureResource?
    private static var fabricNormal: TextureResource?
    private static var contactShadow: UnlitMaterial?
    private static var windowSky: UnlitMaterial?

    static func make(_ item: RoomItemState, photoMaterial: any Material, usesWindowLighting: Bool = true, useBakedModels: Bool = true, cutaway: Bool = false) async -> Entity {
        if fabricColor == nil { fabricColor = await texture("CozyFabricColor", semantic: .color) }
        if fabricNormal == nil { fabricNormal = await texture("CozyFabricNormal", semantic: .normal) }
        if contactShadow == nil { contactShadow = await shadowMaterial() }
        if item.kind == .wall, windowSky == nil { windowSky = await skyMaterial() }
        let root = Entity()
        let s = item.kind.size
        let main = item.colorName ?? defaultColor(for: item.kind)
        func material(_ hex: String, part: String = "") -> any Material {
            let scale: Float
            let softness: Float
            switch item.kind {
            case .bed:
                scale = part.hasPrefix("duvet") ? 1.9 : (part == "pillow" ? 2.8 : 3.2)
                softness = 1
            case .chair, .sofa, .flowerCushion: (scale, softness) = (2.8, 1)
            case .rugRound, .rugSquare: (scale, softness) = (2.2, 1)
            case .plant: (scale, softness) = (7, 0.8)
            case .desk, .shelf, .frame: (scale, softness) = (10, 0.45)
            case .wall, .floor: (scale, softness) = (12, 0.25)
            case .lamp: (scale, softness) = (9, 0.35)
            }
            return Self.material(hex, usesWindowLighting: usesWindowLighting,
                                 textureRepeat: item.kind == .floor ? 16 : scale / 1.5,
                                 softness: softness, surfaceScale: scale,
                                 surfaceGlow: part.hasPrefix("window") ? 0.75 : (item.kind == .lamp && part == "shade" ? 0.45 : (item.kind == .bed && (part == "headboard" || part == "frame") ? 0.12 : 0)),
                                 isFiber: part.hasSuffix(".pile"))
        }
        func box(_ name: String, _ size: SIMD3<Float>, _ at: SIMD3<Float>, _ color: String,
                 radius: Float = 0.025) {
            let padded = ["duvet", "duvet.fold", "duvet.fold.drape", "pillow", "mattress", "headboard", "seat", "seat.base", "backrest", "armrest"].contains(name) || ((item.kind == .bed || item.kind == .frame) && name == "frame")
            let exponent: Float
            if name == "pillow" || name == "headboard" { exponent = 0.45 }
            else if item.kind == .sofa { exponent = name == "backrest" ? 0.60 : 0.48 }
            else if item.kind == .chair && name == "backrest" { exponent = 0.50 }
            else if item.kind == .bed && name == "frame" { exponent = 0.24 }
            else { exponent = 0.32 }
            let drape = name == "duvet.fold"
            let key = "\(size)-\(radius)-\(padded)-\(exponent)-\(drape)"
            let mesh: MeshResource
            if let cached = meshes[key] { mesh = cached }
            else {
                mesh = padded ? cushion(size, exponent: exponent, drape: drape) : .generateBox(size: size, cornerRadius: min(radius, size.min() * 0.49))
                meshes[key] = mesh
            }
            let wallPhoto = item.kind == .wall && item.photoData != nil && name.hasPrefix("wall.")
            let model = ModelEntity(mesh: mesh, materials: wallPhoto ? [photoMaterial] : [material(color, part: name)])
            model.name = name
            model.position = at
            if item.kind == .wall || item.kind == .floor {
                // 창문이 있는 벽이 방 전체를 가리는 그림자를 만들지 않게 한다.
                // Window bars are projected by the soft aperture shader; a second
                // shadow-map projection would create misaligned, hard duplicate bars.
                model.components.set(DynamicLightShadowComponent(castsShadow: false))
            }
            root.addChild(model)
            if padded, let pile = meshes["pile-\(size)-\(exponent)-\(drape)"] {
                let fibers = ModelEntity(mesh: pile, materials: [material(color, part: name + ".pile")])
                fibers.name = "\(name).pile"
                fibers.position = at
                // Tiny fibers receive light without casting oversized shadow-map dots.
                fibers.components.set(DynamicLightShadowComponent(castsShadow: false))
                root.addChild(fibers)
            }
        }
        func ball(_ name: String, _ size: SIMD3<Float>, _ at: SIMD3<Float>, _ color: String) {
            let plush = name.contains("leaf") || name.contains("flower") || name == "rug"
            let mesh: MeshResource
            if plush {
                let key = "plush-ball-\(size)"
                if let cached = meshes[key] { mesh = cached }
                else {
                    mesh = cushion(size, exponent: 1)
                    meshes[key] = mesh
                }
            } else {
                mesh = meshes["sphere"] ?? .generateSphere(radius: 0.5)
                meshes["sphere"] = mesh
            }
            let model = ModelEntity(mesh: mesh, materials: [material(color)])
            model.name = name
            model.scale = plush ? SIMD3<Float>(repeating: 1) : size
            model.position = at
            root.addChild(model)
            if plush, let pile = meshes["pile-\(size)-\(Float(1))-false"] {
                let fibers = ModelEntity(mesh: pile, materials: [material(color, part: name + ".pile")])
                fibers.name = "\(name).pile"
                fibers.position = at
                fibers.components.set(DynamicLightShadowComponent(castsShadow: false))
                root.addChild(fibers)
            }
        }
        func leg(_ x: Float, _ z: Float, height: Float, color: String) {
            let model = ModelEntity(mesh: .generateCylinder(height: max(0.01, height - 0.035), radius: 0.032), materials: [material(color)])
            model.name = "leg"
            model.position = [x, height / 2, z]
            root.addChild(model)
            ball("leg.foot", [0.064, 0.05, 0.064], [x, 0.025, z], color)
        }
        let baked = useBakedModels ? await bakedModel(for: item.kind) : nil
        if let baked {
            func restoreMaterials(_ entity: Entity) {
                if var model = entity.components[ModelComponent.self], let source = model.materials.first as? PhysicallyBasedMaterial {
                    let hex = item.colorName != nil && customizablePart(entity.name, kind: item.kind)
                        ? main : colorHex(source.baseColor.tint)
                    model.materials = [material(hex, part: entity.name)]
                    entity.components.set(model)
                    if entity.name.hasSuffix(".pile") {
                        entity.components.set(DynamicLightShadowComponent(castsShadow: false))
                    }
                }
                for child in entity.children { restoreMaterials(child) }
            }
            restoreMaterials(baked)
            for child in Array(baked.children) where child.name != "contact-shadow" { root.addChild(child) }
        } else {
        switch item.kind {
        case .flowerCushion:
            for i in 0..<5 {
                let a = Float(i) / 5 * 2 * .pi
                ball("flower.petal", [0.125, 0.09, 0.12], [cos(a) * 0.069, 0.045, sin(a) * 0.069], main)
            }
            ball("flower.center", [0.08, 0.09, 0.08], [0, 0.055, 0], "#F2D793")
        case .wall:
            func wallPanel(_ name: String, _ size: SIMD2<Float>, _ center: SIMD2<Float>, _ color: String) {
                let mesh = CozyRoomShell.panel(size: size, center: center, cutaway: cutaway)
                let model = ModelEntity(mesh: mesh, materials: item.photoData != nil ? [photoMaterial] : [material(color)])
                model.name = name
                model.components.set(DynamicLightShadowComponent(castsShadow: false))
                root.addChild(model)
            }
            wallPanel("wall.left", [0.055, 2.04], [-1.025, 0], main)
            wallPanel("wall.back", [2.04, 0.055], [0, -1.025], item.colorName ?? "#F5DAC1")
            if item.photoData == nil {
                for i in 0..<10 {
                    wallPanel("wall.stripe.\(i)", [0.006, 0.10], [-0.993, -0.94 + Float(i) * 0.21],
                              item.colorName == nil ? "#FFC1B7" : main)
                }
            }
            box("skirting.left", [0.075, 0.13, 2], [-0.976, 0.065, 0], "#ECA7B9")
            box("skirting.back", [2, 0.13, 0.075], [0, 0.065, -0.976], "#ECA7B9")
            if !cutaway {
            for isLeft in [true, false] {
                let slope = isLeft ? CozyRoomShell.riseZ : CozyRoomShell.riseX
                let center: SIMD2<Float> = isLeft ? [-0.97, 0] : [0, -0.97]
                let length = 2 * sqrt(1 + slope * slope)
                let molding = ModelEntity(mesh: .generateBox(size: isLeft ? [0.10, 0.08, length] : [length, 0.08, 0.10], cornerRadius: 0.02),
                                          materials: [material("#D7C7DD")])
                molding.name = isLeft ? "cornice.left" : "cornice.back"
                molding.position = [center.x, CozyRoomShell.height(x: center.x, z: center.y) - 0.04, center.y]
                molding.orientation = simd_quatf(angle: isLeft ? -atan(slope) : atan(slope), axis: isLeft ? [1, 0, 0] : [0, 0, 1])
                molding.components.set(DynamicLightShadowComponent(castsShadow: false))
                root.addChild(molding)
            }
            let ceiling = ModelEntity(mesh: CozyRoomShell.ceiling(), materials: [material(item.colorName ?? "#EFD4EB")])
            ceiling.name = "ceiling"
            ceiling.components.set(DynamicLightShadowComponent(castsShadow: false))
            root.addChild(ceiling)
            }
            // 창문은 벽의 자식으로 두어 벽 전체 교체 시 함께 정리된다.
            let sky = ModelEntity(mesh: archedPane(), materials: [windowSky ?? UnlitMaterial(color: Palette.uiColor("#D9C6EC"))])
            sky.name = "window.sky"
            sky.position = [-0.982, 0.70, 0.16]
            sky.components.set(DynamicLightShadowComponent(castsShadow: false))
            root.addChild(sky)
            box("window.sill", [0.18, 0.06, 0.66], [-0.94, 0.70, 0.16], "#FFE7AE")
            for z: Float in [-0.13, 0.45] {
                box("window.frame", [0.07, 0.73, 0.055], [-0.94, 1.055, z], "#FFE7AE")
            }
            let arch = ModelEntity(mesh: archFrame(), materials: [material("#FFE7AE", part: "window.arch")])
            arch.name = "window.arch"
            arch.position = [-0.94, 0.70, 0.16]
            arch.components.set(DynamicLightShadowComponent(castsShadow: false))
            root.addChild(arch)
            box("window.crossbar", [0.07, 0.045, 0.58], [-0.93, 1.12, 0.16], "#FFE7AE")
            box("window.mullion", [0.07, 0.96, 0.035], [-0.93, 1.19, 0.16], "#FFE7AE")
        case .floor:
            // 홈에서는 바닥 가장자리가 드러나지 않게 화면 밖까지 이어진다.
            box("floor", [cutaway ? 2 : 8, 0.145, cutaway ? 2 : 8], [0, -0.0725, 0], main)
            if cutaway, item.colorName == nil, item.photoData == nil {
                for x in 0..<8 { for z in 0..<8 {
                    box("floor.tile", [0.25, 0.002, 0.25], [-0.875 + Float(x) * 0.25, 0.002, -0.875 + Float(z) * 0.25], (x + z).isMultiple(of: 2) ? "#F8D5DD" : "#FFF0DD", radius: 0.001)
                } }
            }
        case .bed:
            box("frame", [s.x, 0.13, s.z], [0, 0.105, 0], "#F5DFC8", radius: 0.07)
            box("mattress", [s.x * 0.94, 0.14, s.z * 0.94], [0, 0.24, 0], "#FFF0D9", radius: 0.055)
            box("headboard", [s.x, 0.53, 0.105], [0, 0.36, -s.z / 2 + 0.04], "#F5DFC8", radius: 0.05)
            box("duvet", [s.x * 1.01, 0.20, s.z * 0.71], [0, 0.29, s.z * 0.15], main, radius: 0.045)
            box("duvet.fold", [s.x * 1.16, 0.10, 0.26], [0, 0.385, -s.z * 0.07], "#FBE2DB", radius: 0.035)
            box("pillow", [s.x * 0.86, 0.13, 0.28], [0, 0.375, -s.z * 0.32], "#FFE6DE", radius: 0.065)
            for x: Float in [-s.x * 0.36, s.x * 0.36] {
                for z: Float in [-s.z * 0.36, s.z * 0.36] { leg(x, z, height: 0.09, color: "#E7C7AF") }
            }
        case .desk:
            let top = item.kind.seatHeight ?? 0.437
            box("desktop", [s.x, 0.075, s.z], [0, top - 0.0375, 0], main, radius: 0.035)
            for x: Float in [-s.x * 0.39, s.x * 0.39] {
                for z: Float in [-s.z * 0.32, s.z * 0.32] { leg(x, z, height: top - 0.06, color: "#EBD5BD") }
            }
            box("notebook.lower.cover", [0.20, 0.016, 0.14], [0.045, top + 0.008, 0.15], "#BCAAD8", radius: 0.006)
            box("notebook.pages", [0.18, 0.014, 0.125], [0.05, top + 0.023, 0.15], "#FFF5E6", radius: 0.006)
            box("notebook.cover", [0.19, 0.014, 0.13], [0.05, top + 0.039, 0.15], "#F1BCBF", radius: 0.006)
            box("pencil.cup", [0.065, 0.085, 0.065], [-0.125, top + 0.043, -0.01], "#EBA7B7")
            for i in 0..<4 {
                box("pencil", [0.008, 0.12, 0.008], [-0.143 + Float(i) * 0.012, top + 0.12, -0.01],
                    ["#D7BAE7", "#E7B36C", "#B3CBBD", "#E09CA9"][i], radius: 0.003)
            }
        case .chair:
            let top = item.kind.seatHeight ?? 0.227
            box("seat", [s.x, 0.09, s.z * 0.94], [0, top - 0.045, 0], main, radius: 0.044)
            box("backrest", [s.x * 0.95, s.y - top, 0.085], [0, (s.y + top) / 2, -s.z * 0.36], main, radius: 0.04)
            for x: Float in [-s.x * 0.33, s.x * 0.33] {
                for z: Float in [-s.z * 0.31, s.z * 0.31] { leg(x, z, height: top - 0.07, color: main) }
            }
        case .sofa:
            box("seat.base", [s.x * 0.96, 0.05, s.z * 0.94], [0, 0.035, 0], main, radius: 0.025)
            box("seat", [s.x, 0.14, s.z], [0, 0.09, 0], main, radius: 0.065)
            box("backrest", [s.x * 0.80, 0.32, 0.13], [0, 0.24, -s.z * 0.35], main, radius: 0.06)
            for i in 0..<5 {
                let a = Float(i) / 5 * 2 * .pi
                ball("flower.petal", [0.125, 0.105, 0.12], [cos(a) * 0.073, 0.205 + sin(a) * 0.022, sin(a) * 0.073], "#FFF1D9")
            }
            ball("flower.center", [0.083, 0.09, 0.083], [0, 0.225, 0], "#F2D793")
        case .rugRound, .rugSquare:
            if item.kind == .rugRound { ball("rug", [s.x, 0.025, s.z], [0, 0.013, 0], main) }
            else { box("rug", [s.x, 0.01, s.z], [0, 0.005, 0], main, radius: 0.004) }
        case .shelf:
            box("shelf", [s.x, 0.045, s.z], [0, 0.023, 0], main)
            for i in 0..<4 {
                let h: Float = i.isMultiple(of: 2) ? 0.17 : 0.19
                let x = -0.06 + Float(i) * 0.058
                let color = ["#B8B1DA", "#E9AAB8", "#C4BADF", "#E8BECD"][i]
                box("book.pages", [0.044, h - 0.016, 0.088], [x, 0.045 + h / 2, -0.004], "#F7E3D1", radius: 0.003)
                for side: Float in [-1, 1] {
                    box("book.cover", [0.006, h, 0.10], [x + side * 0.025, 0.045 + h / 2, 0], color, radius: 0.002)
                }
                box("book.spine", [0.054, h, 0.014], [x, 0.045 + h / 2, 0.045], color, radius: 0.005)
                for y: Float in [0.075, 0.045 + h - 0.025] {
                    box("book.detail", [0.025, 0.008, 0.003], [x, y, 0.053], "#F4D6AC", radius: 0.001)
                }
            }
            let pot = ModelEntity(mesh: turnedMesh(name: "shelf-pot", profile: [(0, 0.029), (0.006, 0.036), (0.02, 0.043), (0.065, 0.048), (0.075, 0.048), (0.080, 0.044)]), materials: [material("#F8E3C1")])
            pot.name = "pot"
            pot.position = [-0.22, 0.045, 0]
            root.addChild(pot)
            for i in 0..<7 {
                let angle = Float(i) * 2.4
                ball("leaf", [0.065, 0.045, 0.045], [-0.22 + cos(angle) * 0.05, 0.15 + sin(angle) * 0.04, sin(angle) * 0.035], "#91AD70")
            }
            for i in 0..<6 {
                let t = Float(i)
                ball("vine.leaf", [0.060, 0.070, 0.045], [-0.25 - sin(t * 0.6) * 0.07, 0.14 - t * 0.047, 0.06],
                     i.isMultiple(of: 2) ? "#789457" : "#A4B570")
            }
            ball("plant.bud", [0.055, 0.055, 0.055], [-0.22, 0.19, 0.045], "#E8A7BF")
            for i in 0..<5 {
                let a = Float(i) / 5 * 2 * .pi
                ball("shelf.flower", [0.055, 0.055, 0.035], [0.24 + cos(a) * 0.034, 0.105 + sin(a) * 0.034, 0.035], "#EDADBB")
            }
            ball("shelf.flower.center", [0.035, 0.035, 0.035], [0.24, 0.105, 0.052], "#F3D59C")
        case .plant:
            ball("pot", [s.x, 0.19, s.z], [0, 0.095, 0], "#F4DABA")
            box("stem", [0.018, 0.29, 0.018], [0, 0.30, 0], "#839C64", radius: 0.008)
            for i in 0..<8 {
                let angle = Float(i) * 2.4
                ball("leaf", [0.11, 0.065, 0.08], [cos(angle) * 0.06, 0.21 + Float(i) * 0.034, sin(angle) * 0.06], main)
            }
        case .frame:
            box("frame", [s.x, s.y, 0.055], [0, s.y / 2, 0], item.colorName ?? "#F5D6B7", radius: 0.017)
            box("mat", [s.x * 0.76, s.y * 0.77, 0.009], [0, s.y / 2, 0.031], "#FFF0DF", radius: 0.004)
            for x: Float in [-0.032, 0.032] { ball("heart", [0.083, 0.10, 0.018], [x, s.y * 0.54, 0.041], "#E9A0B2") }
            let tip = ModelEntity(mesh: .generateBox(size: [0.083, 0.083, 0.012], cornerRadius: 0.012), materials: [material("#E9A0B2")])
            tip.position = [0, s.y * 0.44, 0.041]
            tip.orientation = simd_quatf(angle: .pi / 4, axis: [0, 0, 1])
            root.addChild(tip)
        case .lamp:
            ball("base", [0.085, 0.075, 0.085], [0, 0.0375, 0], "#E2AE70")
            box("stem", [0.02, 0.12, 0.02], [0, 0.09, 0], "#DCB477", radius: 0.009)
            let shade = ModelEntity(mesh: lampShade(), materials: [material(main, part: "shade")])
            shade.name = "shade"
            shade.position.y = 0.125
            root.addChild(shade)
            let glow = PointLight()
            glow.light.color = Palette.uiColor("#FFE3A9")
            glow.light.intensity = 16
            glow.light.attenuationRadius = 0.65
            glow.position = [0, 0.19, 0]
            root.addChild(glow)
        }
        }
        if item.kind == .wall {
            for child in root.children where child.name.hasPrefix("window.") {
                child.position.y = 0.46 + (child.position.y - 0.70)
                child.position.z -= 0.11
            }
        }
        if item.kind.blocksFloor, let contactShadow {
            let shadow = ModelEntity(mesh: .generatePlane(width: s.x * 1.35, depth: s.z * 1.35), materials: [contactShadow])
            shadow.name = "contact-shadow"
            shadow.position.y = 0.002
            shadow.components.set(DynamicLightShadowComponent(castsShadow: false))
            root.addChild(shadow)
        }
        if item.photoData != nil, item.kind != .wall {
            let isWall = item.kind.hangsOnWall
            let size: SIMD2<Float> = isWall ? [s.x * 0.76, s.y * 0.77] : [s.x * 0.9, s.z * 0.85]
            let photo = ModelEntity(mesh: .generatePlane(width: size.x, height: size.y), materials: [photoMaterial])
            photo.name = "custom-photo"
            if isWall { photo.position = [0, s.y / 2, s.z / 2 + 0.015] }
            else {
                photo.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
                photo.position = [0, (item.kind.seatHeight ?? 0.01) + 0.002, 0]
            }
            root.addChild(photo)
        }
        return root
    }

    private static func bakedModel(for kind: FurnitureKind) async -> Entity? {
        if let model = bakedModels[kind] { return model.clone(recursive: true) }
        guard let url = Bundle.main.url(forResource: "cozy_" + kind.rawValue, withExtension: "reality"),
              let model = try? await Entity(contentsOf: url) else { return nil }
        bakedModels[kind] = model
        return model.clone(recursive: true)
    }

    private static func customizablePart(_ name: String, kind: FurnitureKind) -> Bool {
        let part = name.replacingOccurrences(of: ".pile", with: "")
        switch kind {
        case .bed: return part == "duvet"
        case .chair, .sofa: return ["seat", "seat.base", "backrest", "leg", "leg.foot"].contains(part)
        case .desk: return part == "desktop"
        case .shelf: return part == "shelf"
        case .frame: return part == "frame"
        case .lamp: return part == "shade"
        case .rugRound, .rugSquare: return part == "rug"
        case .plant: return part.contains("leaf")
        case .flowerCushion: return part == "flower.petal"
        case .wall, .floor: return true
        }
    }

    private static func colorHex(_ color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
    }

    private static func material(_ hex: String, usesWindowLighting: Bool, textureRepeat: Float, softness: Float, surfaceScale: Float, surfaceGlow: Float = 0, isFiber: Bool = false) -> any Material {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: Palette.uiColor(hex))
        if let fabricColor { material.baseColor = .init(tint: Palette.uiColor(hex), texture: .init(fabricColor)) }
        if let fabricNormal { material.normal = .init(texture: .init(fabricNormal)) }
        material.textureCoordinateTransform = .init(offset: .zero, scale: [textureRepeat, textureRepeat], rotation: 0)
        material.roughness = .init(floatLiteral: 0.95)
        material.metallic = .init(floatLiteral: 0)
        material.faceCulling = .none
        if usesWindowLighting, let fabricShader, var custom = try? CustomMaterial(surfaceShader: fabricShader, lightingModel: .lit) {
            custom.baseColor = .init(tint: Palette.uiColor(hex))
            if let fabricColor { custom.baseColor.texture = .init(fabricColor) }
            if let fabricNormal { custom.normal = .init(texture: .init(fabricNormal)) }
            custom.custom.value = [surfaceScale, softness, surfaceGlow, isFiber ? 1 : 0]
            custom.faceCulling = .none
            return custom
        }
        return material
    }

    private static func defaultColor(for kind: FurnitureKind) -> String {
        switch kind {
        case .wall: "#FFE8DB"
        case .floor: "#E5D4FC"
        case .bed: "#FFABB2"
        case .chair, .sofa: "#F6B2CF"
        case .desk, .shelf: "#F9E5D1"
        case .rugRound, .rugSquare: "#F2BDCA"
        default: kind.defaultColorName
        }
    }

    private static func skyMaterial() async -> UnlitMaterial? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 512), format: format).image { renderer in
            let context = renderer.cgContext
            let colors = ["#BBA3D5", "#D7AECF", "#F8D8C8"].map { Palette.uiColor($0).cgColor }
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 0.6, 1]) {
                context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 512), options: [])
            }
            for (x, y, scale) in [(18.0, 125.0, 0.7), (148.0, 215.0, 1.0), (40.0, 325.0, 1.2)] {
                context.saveGState()
                context.translateBy(x: x, y: y)
                context.scaleBy(x: scale, y: scale)
                let cloud = CGMutablePath()
                for rect in [CGRect(x: 0, y: 8, width: 92, height: 20), CGRect(x: 12, y: -2, width: 38, height: 30), CGRect(x: 36, y: -17, width: 39, height: 45), CGRect(x: 65, y: 1, width: 28, height: 25)] {
                    cloud.addEllipse(in: rect)
                }
                context.addPath(cloud)
                context.clip()
                if let light = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [Palette.uiColor("#FFF1C7").cgColor, Palette.uiColor("#EDB2BB").cgColor] as CFArray, locations: [0, 1]) {
                    context.drawLinearGradient(light, start: CGPoint(x: 0, y: -17), end: CGPoint(x: 0, y: 30), options: [])
                }
                context.restoreGState()
            }
            for i in 0..<12 {
                let rect = CGRect(x: -25 + i * 25, y: 437 + (i % 3) * 18, width: 65, height: 86)
                context.saveGState()
                context.addEllipse(in: rect)
                context.clip()
                if let foliage = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [Palette.uiColor("#CCD1A0").cgColor, Palette.uiColor("#6E8D72").cgColor] as CFArray, locations: [0, 1]) {
                    context.drawRadialGradient(foliage, startCenter: CGPoint(x: rect.midX - 14, y: rect.minY + 20), startRadius: 1, endCenter: CGPoint(x: rect.midX, y: rect.midY), endRadius: 55, options: [.drawsAfterEndLocation])
                }
                context.restoreGState()
            }
        }
        guard let cgImage = image.cgImage,
              let texture = try? await TextureResource(image: cgImage, options: .init(semantic: .color)) else { return nil }
        var material = UnlitMaterial(applyPostProcessToneMap: false)
        material.color = .init(tint: .white, texture: .init(texture))
        return material
    }

    private static func shadowMaterial() async -> UnlitMaterial? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128), format: format).image { renderer in
            UIColor.black.setFill()
            renderer.fill(CGRect(x: 0, y: 0, width: 128, height: 128))
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: [UIColor.white.cgColor, UIColor.black.cgColor] as CFArray,
                                         locations: [0, 1]) {
                renderer.cgContext.drawRadialGradient(gradient, startCenter: CGPoint(x: 64, y: 64), startRadius: 8,
                                                      endCenter: CGPoint(x: 64, y: 64), endRadius: 64, options: [])
            }
        }
        guard let cgImage = image.cgImage,
              let mask = try? await TextureResource(image: cgImage, options: .init(semantic: .raw)) else { return nil }
        var material = UnlitMaterial(color: Palette.uiColor("#816A91"))
        material.blending = .transparent(opacity: .init(scale: 0.22, texture: .init(mask)))
        return material
    }

    private static func archedPane() -> MeshResource {
        if let mesh = meshes["arched-window"] { return mesh }
        var points: [SIMD3<Float>] = [[0, 0.49, 0], [0, 0, -0.29], [0, 0, 0.29]]
        for i in 0...32 {
            let angle = Float(i) / 32 * .pi
            points.append([0, 0.69 + sin(angle) * 0.29, cos(angle) * 0.29])
        }
        var indices: [UInt32] = []
        for i in 1..<points.count {
            indices += [0, UInt32(i == points.count - 1 ? 1 : i + 1), UInt32(i)]
        }
        var descriptor = MeshDescriptor(name: "arched-window")
        descriptor.positions = .init(points)
        descriptor.normals = .init(Array(repeating: SIMD3<Float>(1, 0, 0), count: points.count))
        descriptor.textureCoordinates = .init(points.map { [$0.z / 0.58 + 0.5, $0.y / 0.98] })
        descriptor.primitives = .triangles(indices)
        let mesh = (try? MeshResource.generate(from: [descriptor])) ?? .generateBox(size: [0.01, 0.98, 0.58])
        meshes["arched-window"] = mesh
        return mesh
    }

    private static func lampShade() -> MeshResource {
        turnedMesh(name: "lamp-shade", profile: [(0, 0.071), (0.008, 0.078), (0.020, 0.077), (0.060, 0.065), (0.10, 0.049), (0.126, 0.028), (0.136, 0.001)])
    }

    private static func turnedMesh(name: String, profile: [(Float, Float)]) -> MeshResource {
        if let mesh = meshes[name] { return mesh }
        var points: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = [], indices: [UInt32] = []
        let columns = 48
        for row in profile.indices {
            let previous = profile[max(0, row - 1)], next = profile[min(profile.count - 1, row + 1)]
            for column in 0...columns {
                let angle = Float(column) / Float(columns) * 2 * .pi
                points.append([cos(angle) * profile[row].1, profile[row].0, sin(angle) * profile[row].1])
                normals.append(simd_normalize(SIMD3(cos(angle) * (next.0 - previous.0), previous.1 - next.1, sin(angle) * (next.0 - previous.0))))
                uv.append([Float(column) / Float(columns), profile[row].0 / 0.136])
                if row < profile.count - 1, column < columns {
                    let a = UInt32(row * (columns + 1) + column), b = a + UInt32(columns + 1)
                    indices += [a, b, a + 1, a + 1, b, b + 1]
                }
            }
        }
        var descriptor = MeshDescriptor(name: name)
        descriptor.positions = .init(points)
        descriptor.normals = .init(normals)
        descriptor.textureCoordinates = .init(uv)
        descriptor.primitives = .triangles(indices)
        let mesh = (try? MeshResource.generate(from: [descriptor])) ?? .generateSphere(radius: 0.07)
        meshes[name] = mesh
        return mesh
    }

    private static func archFrame() -> MeshResource {
        if let mesh = meshes["window-frame"] { return mesh }
        let rows = 40, columns = 12
        var points: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for row in 0...rows {
            let angle = Float(row) / Float(rows) * .pi
            let center = SIMD3<Float>(0, 0.69 + sin(angle) * 0.29, cos(angle) * 0.29)
            for col in 0...columns {
                let around = Float(col) / Float(columns) * 2 * .pi
                let normal = SIMD3<Float>(cos(around), sin(around) * sin(angle), sin(around) * cos(angle))
                points.append(center + normal * 0.036)
                normals.append(normal)
                if row < rows, col < columns {
                    let a = UInt32(row * (columns + 1) + col), b = a + UInt32(columns + 1)
                    indices += [a, b, a + 1, a + 1, b, b + 1]
                }
            }
        }
        var descriptor = MeshDescriptor(name: "window-frame")
        descriptor.positions = .init(points)
        descriptor.normals = .init(normals)
        descriptor.primitives = .triangles(indices)
        let mesh = (try? MeshResource.generate(from: [descriptor])) ?? .generateBox(size: [0.07, 0.07, 0.58])
        meshes["window-frame"] = mesh
        return mesh
    }

    /// 평평한 상자 모서리 대신 솜이 든 것처럼 넓게 부푸는 사각 쿠션 표면.
    private static func cushion(_ size: SIMD3<Float>, exponent: Float, drape: Bool = false) -> MeshResource {
        let rows = 32, columns = 64
        let half = size / 2
        func signedPower(_ value: Float, _ power: Float) -> Float {
            (value < 0 ? -1 : 1) * pow(abs(value), power)
        }
        var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for row in 0...rows {
            let v = Float(row) / Float(rows) * .pi - .pi / 2
            for col in 0...columns {
                let u: Float = col == columns ? 0 : Float(col) / Float(columns) * 2 * .pi
                let latitude: Float = row == 0 || row == rows ? 0 : max(0, cos(v))
                let point = SIMD3<Float>(signedPower(latitude, exponent) * signedPower(cos(u), exponent),
                                         signedPower(sin(v), exponent),
                                         signedPower(latitude, exponent) * signedPower(sin(u), exponent))
                var position = point * half
                var normal = SIMD3<Float>(signedPower(point.x, 2 / exponent - 1),
                                          signedPower(point.y, 2 / exponent - 1),
                                          signedPower(point.z, 2 / exponent - 1)) / half
                if drape {
                    // A continuous rolled blanket bends over the mattress edges;
                    // transform the normals with the same deformation as the mesh.
                    let edge = max(0, (abs(point.x) - 0.74) / 0.26)
                    position.y -= 0.13 * edge * edge
                    let slope = 0.26 * edge / (0.26 * half.x) * (point.x < 0 ? -1 : Float(1))
                    normal.x += slope * normal.y
                }
                positions.append(position)
                normals.append(simd_normalize(normal))
                if row < rows, col < columns {
                    let a = UInt32(row * (columns + 1) + col), b = a + UInt32(columns + 1)
                    indices += [a, b, a + 1, a + 1, b, b + 1]
                }
            }
        }
        // Project each triangle in model space: latitude UVs stretch at the
        // cushion poles, particularly in the single-item PBR editing preview.
        var projectedPositions: [SIMD3<Float>] = [], projectedNormals: [SIMD3<Float>] = []
        var projectedUV: [SIMD2<Float>] = []
        for triangle in stride(from: 0, to: indices.count, by: 3) {
            let vertices = (0..<3).map { Int(indices[triangle + $0]) }
            let n = simd_abs(vertices.reduce(SIMD3<Float>.zero) { $0 + normals[$1] })
            for index in vertices {
                let point = positions[index]
                projectedPositions.append(point)
                projectedNormals.append(normals[index])
                let coordinate: SIMD2<Float> = n.y > max(n.x, n.z) ? [point.x, point.z] : (n.x > n.z ? [point.y, point.z] : [point.x, point.y])
                projectedUV.append(coordinate * 1.5)
            }
        }
        var seed: UInt64 = 9452242
        func random() -> Float {
            seed = seed &* 6364136223846793005 &+ 1
            return Float((seed >> 32) & 0xFFFFFF) / Float(0xFFFFFF)
        }
        var pilePositions: [SIMD3<Float>] = [], pileNormals: [SIMD3<Float>] = [], pileUV: [SIMD2<Float>] = []
        // Sample by triangle area, so the fleece stays evenly distributed at the poles.
        for triangle in stride(from: 0, to: projectedPositions.count, by: 3) {
            let a = projectedPositions[triangle], b = projectedPositions[triangle + 1], c = projectedPositions[triangle + 2]
            let area = simd_length(simd_cross(b - a, c - a)) / 2
            let expected = area * 34000
            let count = Int(expected) + (random() < expected - floor(expected) ? 1 : 0)
            for _ in 0..<count {
                let u = sqrt(random()), v = random()
                let bary = SIMD3<Float>(1 - u, u * (1 - v), u * v)
                let center = a * bary.x + b * bary.y + c * bary.z
                let normal = simd_normalize(projectedNormals[triangle] * bary.x + projectedNormals[triangle + 1] * bary.y + projectedNormals[triangle + 2] * bary.z)
                let axis: SIMD3<Float> = abs(normal.y) > 0.9 ? [1, 0, 0] : [0, 1, 0]
                let tangent = simd_normalize(simd_cross(normal, axis))
                let bitangent = simd_cross(normal, tangent)
                let angle = random() * 2 * Float.pi
                let side = tangent * cos(angle) + bitangent * sin(angle)
                let tip = center + normal * (0.0018 + random() * 0.0022) + side * 0.0005
                let coordinate = projectedUV[triangle] * bary.x + projectedUV[triangle + 1] * bary.y + projectedUV[triangle + 2] * bary.z
                pilePositions += [center - side * 0.0004, center + side * 0.0004, tip]
                pileNormals += [normal, normal, normal]
                pileUV += [coordinate, coordinate + [0.001, 0], coordinate + [0, 0.002]]
            }
        }
        var pile = MeshDescriptor(name: "short-fleece")
        pile.positions = .init(pilePositions)
        pile.normals = .init(pileNormals)
        pile.textureCoordinates = .init(pileUV)
        pile.primitives = .triangles((0..<UInt32(pilePositions.count)).map { $0 })
        meshes["pile-\(size)-\(exponent)-\(drape)"] = try? MeshResource.generate(from: [pile])
        var mesh = MeshDescriptor(name: "padded-cushion")
        mesh.positions = .init(projectedPositions)
        mesh.normals = .init(projectedNormals)
        mesh.textureCoordinates = .init(projectedUV)
        mesh.primitives = .triangles((0..<UInt32(projectedPositions.count)).map { $0 })
        return (try? MeshResource.generate(from: [mesh])) ?? .generateBox(size: size, cornerRadius: size.min() / 3)
    }

    private static func texture(_ name: String, semantic: TextureResource.Semantic) async -> TextureResource? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let image = UIImage(contentsOfFile: url.path)?.cgImage else { return nil }
        return try? await TextureResource(image: image, options: .init(semantic: semantic))
    }
}

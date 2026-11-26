import RealityKit
import UIKit
import Metal

/// 고정된 홈 카메라에서도 실제 깊이와 가림이 생기는, 부위별로 분리된 가구.
/// 저장 좌표·충돌 범위·앉는 높이는 기존 FurnitureKind와 함께 쓴다.
enum CozyFurniture {
    static func clearCache() { CheckedRugMaterial.clearCache(); CozyLeafMesh.clearCache(); CozyArtworkMesh.clearCache(); ReferenceQuiltMesh.clearCache(); RadioModel.clearRoomCache(); RoomWoodMaterial.clearCache(); meshes.removeAll(); bakedModels.removeAll(); fabricColor = nil; fabricNormal = nil; contactShadow = nil; windowSky = nil; windowSkyPhase = nil }

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
    private static var windowSkyPhase: RoomDaylight.Phase?

    private struct MaterialKey: Hashable {
        var color: String
        var scale: Float
        var softness: Float
        var glow: Float
        var fiber: Bool
        var closedSurface: Bool
    }

    // Only for paired measurements with the same executable and saved room.
    private static var usesResourceOptimizations: Bool {
        #if DEBUG
        return !ProcessInfo.processInfo.arguments.contains("--render-baseline")
        #else
        return true
        #endif
    }

    static func make(_ item: RoomItemState, photoMaterial: any Material, rightWallPhotoMaterial: (any Material)? = nil, usesWindowLighting: Bool = true, useBakedModels: Bool = true, cutaway: Bool = false, roomOverview: Bool = false) async -> Entity {
        if fabricColor == nil { fabricColor = await texture("CozyFabricColor", semantic: .color) }
        if fabricNormal == nil { fabricNormal = await texture("CozyFabricNormal", semantic: .normal) }
        if contactShadow == nil { contactShadow = await shadowMaterial() }
        if item.kind == .wall { windowSky = await skyMaterial() }
        let root = Entity()
        let s = item.kind.size
        let main = item.colorName ?? defaultColor(for: item.kind, cutaway: cutaway)
        let timber = await RoomWoodMaterial.timberTexture()
        let woodFloor = item.kind == .floor && !cutaway && item.colorName == nil && item.photoData == nil
            ? await RoomWoodMaterial.floor() : nil
        var materials: [MaterialKey: any Material] = [:]
        func material(_ hex: String, part: String = "") -> any Material {
            let surfacePart = part.replacingOccurrences(of: ".pile", with: "")
            if part == "floor", var woodFloor {
                if roomOverview { woodFloor.textureCoordinateTransform.scale = [1, 1] }
                return woodFloor
            }
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
            var color: String
            if part.hasPrefix("window.") {
                color = item.windowFrameColor ?? CozyRoomPalette.wood
            } else if customizablePart(part, kind: item.kind), item.kind != .wall || item.colorName != nil {
                color = main
            } else {
                color = CozyRoomPalette.color(for: part, kind: item.kind, fallback: hex)
            }
            // The cutaway source uses pale blue/white checks and honey timber.
            // Keep these material changes independent from saved custom colors.
            if cutaway, item.colorName == nil {
                if item.kind == .floor, surfacePart == "floor" { color = "#BED8F5" }
                if item.kind == .floor, surfacePart == "floor.tile" {
                    color = hex == CozyRoomPalette.softMint ? "#FAFAF5" : "#BEDAF5"
                }
                if item.kind == .wall, surfacePart == "wall.left" { color = "#F4FAFF" }
                if item.kind == .wall, surfacePart.hasPrefix("wall.stripe.") { color = "#C7DFF5" }
                if item.kind == .wall, surfacePart.hasPrefix("skirting.") { color = "#B5D1ED" }
                if item.kind == .bed, surfacePart.hasPrefix("duvet.fold") { color = "#FCFCF8" }
                if item.kind == .bed, ["frame", "headboard", "leg", "leg.foot"].contains(surfacePart) { color = "#DEB883" }
                if item.kind == .desk, ["desktop", "leg", "leg.foot"].contains(surfacePart) { color = "#EBC08B" }
                if item.kind == .shelf, surfacePart == "book.cover" || surfacePart == "book.spine" { color = "#BDD2E8" }
                if item.kind == .shelf, surfacePart.contains("leaf") { color = "#77A44B" }
                if item.kind == .lamp, surfacePart == "shade" { color = "#FFFDF5" }
                if item.kind == .lamp, ["base", "stem"].contains(surfacePart) { color = "#D8AD76" }
                if item.kind == .plant, surfacePart == "pot" { color = "#FFFFFF" }
                if item.kind == .plant, surfacePart == "leaf" { color = "#7EAA54" }
            }
            if cutaway, item.kind == .frame, surfacePart.hasPrefix("heart") { color = "#8BBCE8" }
            if cutaway, item.kind == .chair, ["leg", "leg.foot"].contains(surfacePart) { color = "#DEB883" }
            if !cutaway, part.hasPrefix("window."), item.windowFrameColor == nil { color = "#8B6449" }
            if !cutaway, part.hasPrefix("art.") { color = hex }
            if !cutaway, part.hasPrefix("sofa.") { color = hex }
            if !cutaway, item.kind == .desk, part == "leg.panel" { color = "#A17450" }
            if !cutaway, item.kind == .lamp, ["base", "stem"].contains(part) { color = "#F1EBE3" }
            if !cutaway, item.kind == .chair, ["leg", "leg.foot", "back.support"].contains(part) { color = "#A17450" }
            if !cutaway, item.colorName == nil {
                if item.kind == .wall, surfacePart == "wall.back" { color = "#F2F2F4" }
                if item.kind == .wall, surfacePart.hasPrefix("wall.stripe.") { color = "#D9E5F5" }
                if item.kind == .bed, surfacePart.hasPrefix("duvet.fold") { color = "#F4F1E9" }
                if item.kind == .frame, surfacePart == "frame" { color = "#F3F1ED" }
                if ["shelf", "desktop", "leg", "leg.foot", "frame", "skirting.left", "skirting.back"].contains(surfacePart),
                   item.kind != .chair && item.kind != .frame { color = "#A17450" }
                if item.kind == .bed, surfacePart == "headboard" { color = "#79543C" }
                if item.kind == .bed, surfacePart == "frame" { color = "#D8C8B1" }
                if item.kind == .bed, ["headboard.pad", "footboard"].contains(surfacePart) { color = hex }
                if item.kind == .desk {
                    if surfacePart == "notebook.lower.cover" { color = "#BBD0DC" }
                    if surfacePart == "notebook.cover" { color = "#AEC4D3" }
                    if surfacePart == "pencil.cup" { color = "#8FA9BA" }
                }
                if item.kind == .shelf {
                    if surfacePart.contains("leaf") { color = "#718B50" }
                    if surfacePart == "book.cover" || surfacePart == "book.spine" { color = "#B9C7D1" }
                }
            }
            // Resolve each wall independently, after the room palette overrides.
            if item.kind == .wall, surfacePart == "wall.back" {
                color = item.rightWallColorName ?? (cutaway ? CozyRoomPalette.ivory : "#F2F2F4")
            }
            let glow: Float = part.hasPrefix("window") ? (cutaway ? 0.75 : 0.20) : (item.kind == .lamp && part == "shade" ? -0.65 : (item.kind == .bed && (part == "headboard" || part == "frame") ? 0.12 : (cutaway && item.kind == .chair && !["leg", "leg.foot"].contains(surfacePart) ? 0.75 : 0)))
            // These cushion meshes are closed with outward winding. Threads and
            // open wall/lamp geometry still need both sides of their triangles.
            let closed = usesResourceOptimizations && ["duvet", "duvet.fold", "pillow", "mattress", "headboard", "seat", "seat.base", "backrest", "armrest", "rug"].contains(part)
            let woodPart = !part.hasSuffix(".pile") && (
                (item.kind == .wall && (part.hasPrefix("skirting.") || part.hasPrefix("cornice") || (part.hasPrefix("window.") && item.windowFrameColor == nil))) ||
                ([FurnitureKind.desk, .shelf].contains(item.kind) && ["desktop", "shelf", "leg", "leg.foot", "leg.panel"].contains(part)) ||
                (item.kind == .chair && ["leg", "leg.foot", "back.support"].contains(part)) ||
                (item.kind == .bed && (["headboard", "leg", "leg.foot"].contains(part) || (cutaway && part == "frame"))))
            let surfaceSoftness: Float = woodPart ? -1 : softness
            let key = MaterialKey(color: color, scale: scale, softness: surfaceSoftness, glow: glow,
                                  fiber: part.hasSuffix(".pile"), closedSurface: closed)
            if usesResourceOptimizations, let cached = materials[key] { return cached }
            let value = Self.material(color, usesWindowLighting: usesWindowLighting,
                                 textureRepeat: item.kind == .floor ? 16 : scale / 1.5,
                                 softness: surfaceSoftness, surfaceScale: cutaway ? -scale : scale,
                                 surfaceGlow: glow, isFiber: key.fiber, closedSurface: closed, woodTexture: woodPart ? timber : nil)
            if usesResourceOptimizations { materials[key] = value }
            return value
        }
        func box(_ name: String, _ size: SIMD3<Float>, _ at: SIMD3<Float>, _ color: String,
                 radius: Float = 0.025) {
            let padded = ["duvet", "duvet.fold", "duvet.fold.drape", "pillow", "mattress", "headboard", "headboard.pad", "footboard", "seat", "seat.base", "backrest", "armrest", "sofa.blue-pillow", "sofa.cream-pillow"].contains(name) || ((item.kind == .bed || item.kind == .frame) && name == "frame")
            let exponent: Float
            if name == "pillow" || name == "headboard" || name == "headboard.pad" || name == "footboard" { exponent = 0.45 }
            else if item.kind == .sofa {
                exponent = name == "armrest" ? (cutaway ? 0.86 : 0.60)
                    : (name == "backrest" ? (cutaway ? 0.78 : 0.54) : 0.58)
            }
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
            let wallPhoto = item.kind == .wall && item.photoData != nil && name == "wall.left"
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
            let model = ModelEntity(mesh: mesh, materials: [material(color, part: name)])
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
            let key = "leg-cylinder-\(height)"
            let mesh = meshes[key] ?? .generateCylinder(height: max(0.01, height - 0.035), radius: 0.032)
            meshes[key] = mesh
            let model = ModelEntity(mesh: mesh, materials: [material(color, part: "leg")])
            model.name = "leg"
            model.position = [x, height / 2, z]
            root.addChild(model)
            ball("leg.foot", [0.064, 0.05, 0.064], [x, 0.025, z], color)
        }
        let baked = useBakedModels && item.kind != .wall && item.kind != .lamp && !(item.kind == .sofa && !cutaway) ? await bakedModel(for: item.kind) : nil
        if let baked {
            func restoreMaterials(_ entity: Entity) {
                if var model = entity.components[ModelComponent.self], let source = model.materials.first as? PhysicallyBasedMaterial {
                    let hex = customizablePart(entity.name, kind: item.kind)
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
            ball("flower.center", [0.08, 0.09, 0.08], [0, 0.055, 0], CozyRoomPalette.mint)
        case .wall:
            func wallPanel(_ name: String, _ size: SIMD2<Float>, _ center: SIMD2<Float>, _ color: String) {
                let mesh = CozyRoomShell.panel(size: size, center: center, cutaway: cutaway, overview: roomOverview)
                let model = ModelEntity(mesh: mesh, materials: item.photoData != nil && name == "wall.left" ? [photoMaterial] : [material(color, part: name)])
                model.name = name
                model.components.set(DynamicLightShadowComponent(castsShadow: false))
                root.addChild(model)
            }
            wallPanel("wall.left", [0.055, 2.04], [-1.025, 0], main)
            wallPanel("wall.back", [2.04, 0.055], [0, -1.025], item.colorName ?? CozyRoomPalette.ivory)
            if item.photoData == nil {
                for i in 0..<10 {
                    wallPanel("wall.stripe.\(i)", [0.006, 0.10], [-0.993, -0.94 + Float(i) * 0.21],
                              item.colorName == nil ? CozyRoomPalette.softMint : main)
                }
            }
            box("skirting.left", [0.075, 0.13, 2], [-0.976, 0.065, 0], CozyRoomPalette.mint)
            box("skirting.back", [2, 0.13, 0.075], [0, 0.065, -0.976], CozyRoomPalette.mint)
            if !cutaway && !roomOverview {
            for isLeft in [true, false] {
                let slope = isLeft ? CozyRoomShell.riseZ : CozyRoomShell.riseX
                let center: SIMD2<Float> = isLeft ? [-0.97, 0] : [0, -0.97]
                let length = 2 * sqrt(1 + slope * slope)
                let molding = ModelEntity(mesh: .generateBox(size: isLeft ? [0.10, 0.08, length] : [length, 0.08, 0.10], cornerRadius: 0.02),
                                          materials: [material(CozyRoomPalette.softMint, part: "cornice")])
                molding.name = isLeft ? "cornice.left" : "cornice.back"
                molding.position = [center.x, CozyRoomShell.height(x: center.x, z: center.y) - 0.04, center.y]
                molding.orientation = simd_quatf(angle: isLeft ? -atan(slope) : atan(slope), axis: isLeft ? [1, 0, 0] : [0, 0, 1])
                molding.components.set(DynamicLightShadowComponent(castsShadow: false))
                root.addChild(molding)
            }
            }
            // 창문은 벽의 자식으로 두어 벽 전체 교체 시 함께 정리된다.
            let sky = ModelEntity(mesh: archedPane(), materials: [windowSky ?? UnlitMaterial(color: Palette.uiColor("#D9C6EC"))])
            sky.name = "window.sky"
            sky.position = [-0.982, 0.70, 0.16]
            sky.components.set(DynamicLightShadowComponent(castsShadow: false))
            root.addChild(sky)
            box("window.sill", [0.18, 0.06, 0.66], [-0.94, 0.70, 0.16], CozyRoomPalette.mint)
            for z: Float in [-0.13, 0.45] {
                box("window.frame", [0.07, 0.73, 0.055], [-0.94, 1.055, z], CozyRoomPalette.mint)
            }
            let arch = ModelEntity(mesh: archFrame(), materials: [material(CozyRoomPalette.mint, part: "window.arch")])
            arch.name = "window.arch"
            arch.position = [-0.94, 0.70, 0.16]
            arch.components.set(DynamicLightShadowComponent(castsShadow: false))
            root.addChild(arch)
            box("window.crossbar", [0.07, 0.045, 0.58], [-0.93, 1.12, 0.16], CozyRoomPalette.mint)
            box("window.mullion", [0.07, 0.96, 0.035], [-0.93, 1.19, 0.16], CozyRoomPalette.mint)
        case .floor:
            // 홈에서는 바닥 가장자리가 드러나지 않게 화면 밖까지 이어진다.
            box("floor", [(cutaway || roomOverview) ? 2 : 8, cutaway ? 0.23 : 0.145, (cutaway || roomOverview) ? 2 : 8], [0, cutaway ? -0.115 : -0.0725, 0], main)
            if cutaway, item.colorName == nil, item.photoData == nil {
                for x in 0..<8 { for z in 0..<8 {
                    box("floor.tile", [0.25, 0.002, 0.25], [-0.875 + Float(x) * 0.25, 0.002, -0.875 + Float(z) * 0.25], (x + z).isMultiple(of: 2) ? CozyRoomPalette.softMint : CozyRoomPalette.floorMint, radius: 0.001)
                } }
            }
        case .bed:
            box("frame", [s.x, 0.13, s.z], [0, 0.105, 0], CozyRoomPalette.wood, radius: 0.07)
            box("mattress", [s.x * 0.94, 0.14, s.z * 0.94], [0, 0.24, 0], CozyRoomPalette.surface, radius: 0.055)
            box("headboard", [s.x, 0.66, 0.13], [0, 0.40, -s.z / 2 + 0.04], CozyRoomPalette.wood, radius: 0.07)
            box("duvet", [s.x * 1.01, 0.20, s.z * 0.71], [0, 0.29, s.z * 0.15], main, radius: 0.045)
            box("duvet.fold", [s.x * 1.16, 0.10, 0.26], [0, 0.385, -s.z * 0.07], CozyRoomPalette.softMint, radius: 0.035)
            box("pillow", [s.x * 0.86, 0.13, 0.28], [0, 0.375, -s.z * 0.32], CozyRoomPalette.surface, radius: 0.065)
            for x: Float in [-s.x * 0.36, s.x * 0.36] {
                for z: Float in [-s.z * 0.36, s.z * 0.36] { leg(x, z, height: 0.09, color: CozyRoomPalette.wood) }
            }
        case .desk:
            let top = item.kind.seatHeight ?? 0.437
            box("desktop", [s.x, 0.075, s.z], [0, top - 0.0375, 0], main, radius: 0.035)
            for x: Float in [-s.x * 0.39, s.x * 0.39] {
                for z: Float in [-s.z * 0.32, s.z * 0.32] { leg(x, z, height: top - 0.06, color: CozyRoomPalette.wood) }
            }
            box("notebook.lower.cover", [0.20, 0.016, 0.14], [0.15, top + 0.008, 0.12], CozyRoomPalette.softMint, radius: 0.006)
            box("notebook.pages", [0.18, 0.014, 0.125], [0.15, top + 0.023, 0.12], CozyRoomPalette.surface, radius: 0.006)
            box("notebook.cover", [0.19, 0.014, 0.13], [0.15, top + 0.039, 0.12], CozyRoomPalette.mint, radius: 0.006)
            box("pencil.cup", [0.065, 0.085, 0.065], [-0.125, top + 0.043, -0.01], CozyRoomPalette.mint)
            for i in 0..<4 {
                box("pencil", [0.008, 0.12, 0.008], [-0.143 + Float(i) * 0.012, top + 0.12, -0.01],
                    [CozyRoomPalette.softMint, CozyRoomPalette.wood, CozyRoomPalette.mint, CozyRoomPalette.softMint][i], radius: 0.003)
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
            box("seat", [s.x * 0.82, 0.14, s.z * 0.86], [0, 0.09, 0.015], main, radius: 0.065)
            for side: Float in [-1, 1] {
                box("armrest", [s.x * 0.23, cutaway ? 0.24 : 0.28, s.z * 0.88], [side * s.x * 0.385, cutaway ? 0.18 : 0.20, 0.015], main, radius: 0.07)
            }
            if cutaway {
                box("backrest", [s.x * 0.90, s.y * 0.64, 0.18], [0, s.y * 0.57, -s.z * 0.35], main, radius: 0.06)
            } else {
                // Two upholstered cushions share a cached mesh; the centre seam
                // belongs to the model and remains visible from every camera.
                for side: Float in [-1, 1] {
                    box("backrest", [s.x * 0.445, s.y * 0.54, 0.18],
                        [side * s.x * 0.2275, s.y * 0.54, -s.z * 0.35], main, radius: 0.06)
                }
            }
            if cutaway { for i in 0..<5 {
                let a = Float(i) / 5 * 2 * .pi
                ball("flower.petal", [0.125, 0.105, 0.12], [cos(a) * 0.073, 0.205 + sin(a) * 0.022, sin(a) * 0.073], CozyRoomPalette.ivory)
            }
            ball("flower.center", [0.083, 0.09, 0.083], [0, 0.225, 0], CozyRoomPalette.mint)
            } else {
                box("sofa.blue-pillow", [s.x * 0.31, 0.21, 0.085], [-s.x * 0.18, 0.27, -s.z * 0.15], "#B8D3E2", radius: 0.04)
                box("sofa.cream-pillow", [s.x * 0.28, 0.18, 0.08], [s.x * 0.18, 0.24, -s.z * 0.10], "#E9E2D8", radius: 0.04)
                root.findEntity(named: "sofa.blue-pillow")?.orientation = simd_quatf(angle: -0.12, axis: [0, 0, 1])
                root.findEntity(named: "sofa.cream-pillow")?.orientation = simd_quatf(angle: 0.15, axis: [0, 0, 1])
                let throwCloth = ModelEntity(mesh: ReferenceQuiltMesh.sofaThrow(width: s.x * 0.36, depth: s.z),
                                            materials: [material("#9FB9CB", part: "sofa.throw")])
                throwCloth.name = "sofa.throw"
                throwCloth.position.x = -s.x * 0.10
                root.addChild(throwCloth)
            }
        case .rugRound, .rugSquare:
            if item.kind == .rugRound { ball("rug", [s.x, 0.025, s.z], [0, 0.013, 0], main) }
            else { box("rug", [s.x, 0.01, s.z], [0, 0.005, 0], main, radius: 0.004) }
        case .shelf:
            box("shelf", [s.x, 0.045, s.z], [0, 0.023, 0], main)
            for i in 0..<4 {
                let h: Float = i.isMultiple(of: 2) ? 0.17 : 0.19
                let x = -0.06 + Float(i) * 0.058
                let color = [CozyRoomPalette.lavender, CozyRoomPalette.blush, CozyRoomPalette.softMint, CozyRoomPalette.peach][i]
                box("book.pages", [0.044, h - 0.016, 0.088], [x, 0.045 + h / 2, -0.004], CozyRoomPalette.surface, radius: 0.003)
                for side: Float in [-1, 1] {
                    box("book.cover", [0.006, h, 0.10], [x + side * 0.025, 0.045 + h / 2, 0], color, radius: 0.002)
                }
                box("book.spine", [0.054, h, 0.014], [x, 0.045 + h / 2, 0.045], color, radius: 0.005)
                for y: Float in [0.075, 0.045 + h - 0.025] {
                    box("book.detail", [0.025, 0.008, 0.003], [x, y, 0.053], CozyRoomPalette.wood, radius: 0.001)
                }
            }
            let pot = ModelEntity(mesh: turnedMesh(name: "shelf-pot", profile: [(0, 0.029), (0.006, 0.036), (0.02, 0.043), (0.065, 0.048), (0.075, 0.048), (0.080, 0.044)]), materials: [material(CozyRoomPalette.surface, part: "pot")])
            pot.name = "pot"
            pot.position = [-0.22, 0.045, 0]
            root.addChild(pot)
            for i in 0..<7 {
                let angle = Float(i) * 2.4
                ball("leaf", [0.065, 0.045, 0.045], [-0.22 + cos(angle) * 0.05, 0.15 + sin(angle) * 0.04, sin(angle) * 0.035], CozyRoomPalette.mint)
            }
            for i in 0..<6 {
                let t = Float(i)
                ball("vine.leaf", [0.060, 0.070, 0.045], [-0.25 - sin(t * 0.6) * 0.07, 0.14 - t * 0.047, 0.06],
                     i.isMultiple(of: 2) ? CozyRoomPalette.mint : CozyRoomPalette.mint)
            }
            ball("plant.bud", [0.055, 0.055, 0.055], [-0.22, 0.19, 0.045], CozyRoomPalette.softMint)
            for i in 0..<5 {
                let a = Float(i) / 5 * 2 * .pi
                ball("shelf.flower", [0.055, 0.055, 0.035], [0.24 + cos(a) * 0.034, 0.105 + sin(a) * 0.034, 0.035], CozyRoomPalette.softMint)
            }
            ball("shelf.flower.center", [0.035, 0.035, 0.035], [0.24, 0.105, 0.052], CozyRoomPalette.wood)
        case .plant:
            if cutaway {
                box("pot", [0.20, 0.15, 0.20], [0, 0.075, 0], "#FFFFFF", radius: 0.015)
                box("stem", [0.018, 0.19, 0.018], [0, 0.20, 0], "#839C64", radius: 0.008)
                for (size, position) in [(SIMD3<Float>(0.20, 0.21, 0.19), SIMD3<Float>(0, 0.34, 0)),
                                         (SIMD3<Float>(0.16, 0.17, 0.15), SIMD3<Float>(-0.07, 0.23, 0.05)),
                                         (SIMD3<Float>(0.15, 0.16, 0.14), SIMD3<Float>(0.07, 0.24, 0.04))] {
                    ball("leaf", size, position, item.colorName ?? "#7EAA54")
                }
            } else {
            ball("pot", [s.x, 0.19, s.z], [0, 0.095, 0], CozyRoomPalette.surface)
            box("stem", [0.018, 0.29, 0.018], [0, 0.30, 0], "#839C64", radius: 0.008)
            for i in 0..<8 {
                let angle = Float(i) * 2.4
                ball("leaf", [0.11, 0.065, 0.08], [cos(angle) * 0.06, 0.21 + Float(i) * 0.034, sin(angle) * 0.06], main)
            }
            }
        case .frame:
            box("frame", [s.x, s.y, 0.055], [0, s.y / 2, 0], item.colorName ?? CozyRoomPalette.wood, radius: 0.017)
            box("mat", [s.x * 0.76, s.y * 0.77, 0.009], [0, s.y / 2, 0.031], CozyRoomPalette.surface, radius: 0.004)
            for x: Float in [-0.032, 0.032] { ball("heart", [0.083, 0.10, 0.018], [x, s.y * 0.54, 0.041], CozyRoomPalette.mint) }
            let tip = ModelEntity(mesh: .generateBox(size: [0.083, 0.083, 0.012], cornerRadius: 0.012), materials: [material(CozyRoomPalette.mint, part: "heart.tip")])
            tip.name = "heart.tip"
            tip.position = [0, s.y * 0.44, 0.041]
            tip.orientation = simd_quatf(angle: .pi / 4, axis: [0, 0, 1])
            root.addChild(tip)
        case .lamp:
            ball("base", [0.085, 0.075, 0.085], [0, 0.0375, 0], CozyRoomPalette.wood)
            box("stem", [0.02, 0.12, 0.02], [0, 0.09, 0], CozyRoomPalette.wood, radius: 0.009)
            let shade = ModelEntity(mesh: cutaway ? lampShade() : PresetDollModel.unitSphere(), materials: [material(main, part: "shade")])
            shade.name = "shade"
            shade.scale = cutaway ? [1.15, 1.1, 1.15] : [0.25, 0.18, 0.25]
            shade.position.y = cutaway ? 0.15 : 0.174
            root.addChild(shade)

        }
        }
        if cutaway, item.kind == .rugRound, item.photoData == nil, item.colorName == nil {
            let weave = ModelEntity(mesh: CheckedRugMaterial.mesh(size: s), materials: [await CheckedRugMaterial.material()])
            weave.name = "rug.checker-weave"
            root.addChild(weave)
        }
        if cutaway, item.kind == .rugRound {
            for child in root.children where child.name.hasPrefix("rug") { child.scale *= SIMD3<Float>(0.91, 1, 1.215) }
        }
        if cutaway, item.kind == .desk {
            for child in root.children {
                child.position.x = child.position.x * 1.15 + 0.054
                child.scale.x *= 1.15
            }
            for child in Array(root.children) where child.name.hasPrefix("notebook") || child.name.hasPrefix("pencil") { child.removeFromParent() }
        }
        if cutaway, item.kind == .chair {
            for child in root.children {
                child.position *= SIMD3<Float>(1.12, 1.07, 1.12)
                child.scale *= SIMD3<Float>(1.12, 1.07, 1.12)
            }
            for child in root.children where child.name == "backrest" || child.name == "backrest.pile" {
                child.scale *= SIMD3<Float>(1.12, 1.08, 1)
                child.position.y += 0.015
            }
        }
        if !cutaway, item.kind == .chair {
            for child in root.children {
                if child.name == "backrest" || child.name == "backrest.pile" { child.position.y += 0.04 }
                let sideX: Float = child.position.x < 0 ? -1 : 1
                let sideZ: Float = child.position.z < 0 ? -1 : 1
                if child.name == "leg" {
                    child.orientation = simd_quatf(angle: -sideZ * 0.15, axis: [1, 0, 0])
                        * simd_quatf(angle: sideX * 0.15, axis: [0, 0, 1])
                } else if child.name == "leg.foot" {
                    child.position.x += sideX * 0.01
                    child.position.z += sideZ * 0.01
                }
            }
            box("back.support", [0.08, 0.14, 0.055], [0, 0.22, -s.z * 0.42], "#A17450", radius: 0.012)
        }
        if cutaway, item.kind == .shelf {
            for child in Array(root.children) where child.name.hasPrefix("shelf.flower") || child.name == "plant.bud" { child.removeFromParent() }
            for index in 0..<3 {
                ball("bookend", [0.065, 0.07, 0.065], [0.23, 0.08 + Float(index) * 0.06, 0.015], "#FFFFFF")
            }
        }
        if item.kind == .bed, cutaway {
            for child in root.children {
                child.position.z *= 0.92
                child.scale.z *= 0.92
            }
            if let headboard = root.findEntity(named: "headboard") as? ModelEntity {
                headboard.model?.mesh = cushion([s.x, 0.40, 0.10], exponent: 0.45, drape: false)
                headboard.position.y = 0.28
                // Keep the headboard inside the cutaway wall after the bed turns.
                headboard.position.z += 0.12
            }
            if let pillow = root.findEntity(named: "pillow") as? ModelEntity {
                pillow.model?.mesh = cushion([s.x * 0.72, 0.07, 0.25], exponent: 0.45, drape: false)
                pillow.position.y = 0.395
                pillow.position.x += 0.05
                pillow.position.z += 0.12
            }
            root.findEntity(named: "pillow.pile")?.removeFromParent()
            root.findEntity(named: "headboard.pile")?.removeFromParent()
        }
        if item.kind == .bed, !cutaway {
            if let frame = root.findEntity(named: "frame") as? ModelEntity {
                let key = "interior-padded-bed-base"
                let mesh = meshes[key] ?? cushion([s.x, 0.20, s.z], exponent: 0.32)
                meshes[key] = mesh
                frame.model?.mesh = mesh
                frame.position.y = 0.12
                root.findEntity(named: "frame.pile")?.removeFromParent()
            }
            if let pillow = root.findEntity(named: "pillow") as? ModelEntity {
                pillow.model?.mesh = cushion([s.x * 0.72, 0.13, 0.34], exponent: 0.45, drape: false)
                pillow.orientation = simd_quatf(angle: .pi / 7, axis: [1, 0, 0])
                pillow.position = [0, 0.41, -s.z * 0.32]
                pillow.scale = .one
            }
            if let headboard = root.findEntity(named: "headboard") as? ModelEntity {
                headboard.model?.mesh = .generateBox(size: [s.x + 0.35, 0.58, 0.065], cornerRadius: 0.025)
                headboard.position.x = 0.175
                headboard.position.y = 0.415
            }
            root.findEntity(named: "pillow.pile")?.removeFromParent()
            root.findEntity(named: "headboard.pile")?.removeFromParent()
            box("headboard.pad", [s.x * 0.72, 0.39, 0.09], [0, 0.47, -s.z * 0.43], "#ECE3D6", radius: 0.06)
            if let quilt = root.findEntity(named: "duvet") as? ModelEntity {
                quilt.model?.mesh = ReferenceQuiltMesh.make(size: [s.x * 1.01, 0.20, s.z * 0.71])
            }
            root.findEntity(named: "duvet.pile")?.removeFromParent()
            box("footboard", [s.x, 0.23, 0.10], [0, 0.135, s.z / 2 - 0.05], CozyRoomPalette.ivory, radius: 0.08)
        }
        if item.kind == .desk, !cutaway {
            for child in Array(root.children) where child.name == "leg" || child.name == "leg.foot" { child.removeFromParent() }
            let top = item.kind.seatHeight ?? 0.47
            for side: Float in [-1, 1] {
                box("leg.panel", [s.x * 0.10, top - 0.055, s.z * 0.90],
                    [side * s.x * 0.43, (top - 0.055) / 2, 0], "#A17450", radius: 0.025)
            }
            if let cup = root.findEntity(named: "pencil.cup") as? ModelEntity {
                let key = "interior-pencil-cup"
                let mesh = meshes[key] ?? .generateCylinder(height: 0.1275, radius: 0.04875)
                meshes[key] = mesh
                cup.model?.mesh = mesh
                cup.position = [-0.145, top + 0.06375, 0.12]
                cup.scale = .one
                ball("pencil.cup.inner", [0.073, 0.002, 0.073], [-0.145, top + 0.128, 0.12], "#645A51")
            }
            for pencil in root.children where pencil.name == "pencil" {
                pencil.position.x -= 0.02
                pencil.position.z += 0.13
                pencil.position.y = top + (pencil.position.y - top) * 1.5
                pencil.scale.y *= 1.5
            }
        }
        if item.kind == .frame, !cutaway {
            for child in Array(root.children) where child.name.hasPrefix("heart") { child.removeFromParent() }
            if let mat = root.findEntity(named: "mat") as? ModelEntity {
                mat.model?.mesh = CozyArtworkMesh.make(.mat)
            }
            if item.photoData == nil {
                for (shape, name, color) in [(CozyArtworkMesh.Shape.blue, "art.blue", "#A8BECF"), (.sand, "art.sand", "#DDCEB9")] {
                    let relief = ModelEntity(mesh: CozyArtworkMesh.make(shape), materials: [material(color, part: name)])
                    relief.name = name
                    relief.position.z = 0.041
                    root.addChild(relief)
                }
                ball("art.pebble", [0.055, 0.075, 0.012], [0.065, 0.105, 0.043], "#DDCEB9")
            }
        }
        if item.kind == .shelf, !cutaway {
            for child in Array(root.children) where child.name.hasPrefix("shelf.flower") || child.name == "plant.bud" || child.name.contains("leaf.pile") { child.removeFromParent() }
            for child in Array(root.children) where child.name.contains("leaf") { child.removeFromParent() }
            let leafMesh = CozyLeafMesh.make()
            var leafMaterials: [PhysicallyBasedMaterial] = []
            for tint in ["#496C2C", "#64873C", "#7A984B"] {
                var leafMaterial = PhysicallyBasedMaterial()
                leafMaterial.baseColor.tint = Palette.uiColor(tint)
                leafMaterial.roughness = 0.78; leafMaterial.faceCulling = .none
                leafMaterials.append(leafMaterial)
            }
            func ivyLeaf(_ index: Int, at position: SIMD3<Float>, angle: Float, size: Float = 1) {
                let leaf = ModelEntity(mesh: leafMesh, materials: [leafMaterials[index % 3]])
                leaf.name = "ivy.leaf"
                leaf.scale = SIMD3<Float>(0.048, 0.078, 0.060) * size
                leaf.position = position
                leaf.orientation = simd_quatf(angle: Float(index % 4 - 2) * 0.28, axis: [1, 0, 0])
                    * simd_quatf(angle: angle, axis: [0, 0, 1])
                    * simd_quatf(angle: Float(index % 5 - 2) * 0.22, axis: [0, 1, 0])
                root.addChild(leaf)
            }
            for index in 0..<24 {
                let angle = Float(index) * 2.39996
                let radius = 0.04 + Float(index % 4) * 0.020
                ivyLeaf(index, at: [-0.22 + cos(angle) * radius, 0.17 + Float(index % 5) * 0.023,
                                    sin(angle) * radius], angle: cos(angle) * 1.0)
            }
            for vine in 0..<2 {
                for index in 0..<9 {
                    let t = Float(index)
                    let x = -0.26 + Float(vine) * 0.07 - sin(t * 0.60) * 0.045
                    ivyLeaf(index + vine, at: [x, 0.10 - t * 0.043, 0.075 + Float(vine) * 0.025],
                            angle: index.isMultiple(of: 2) ? -0.6 : 0.6, size: 0.88)
                }
            }
            box("bookend.top", [0.08, 0.025, 0.055], [0.25, 0.105, 0.03], CozyRoomPalette.ivory, radius: 0.012)
            for x: Float in [0.22, 0.28] {
                box("bookend.leg", [0.022, 0.055, 0.055], [x, 0.067, 0.03], CozyRoomPalette.ivory, radius: 0.01)
            }
            let radio = await RadioModel.roomModel()
            radio.scale = SIMD3(repeating: 0.80)
            radio.position = [0.16, 0.045, 0.055]
            root.addChild(radio)
        }
        if item.kind == .rugRound, !cutaway {
            for child in root.children where child.name == "rug" || child.name == "rug.pile" {
                child.scale *= SIMD3<Float>(1.15, 1, s.x / s.z * 1.15)
            }
        }
        // Baked furniture also needs a live light; the mesh alone cannot illuminate the desk.
        if item.kind == .lamp {
            let glow = PointLight()
            glow.name = "desk-lamp-light"
            glow.light.color = Palette.uiColor("#FFE3A9")
            glow.light.intensity = 0
            glow.light.attenuationRadius = 1.5
            glow.position = [0, 0.19, 0]
            root.addChild(glow)
        }
        if item.kind == .wall {
            // Apply to both generated and bundled walls; each surface owns its photo.
            func applyWallPhotos(_ entity: Entity) {
                if var model = entity.components[ModelComponent.self] {
                    if entity.name == "wall.left", item.photoData != nil { model.materials = [photoMaterial] }
                    if entity.name == "wall.back", let rightWallPhotoMaterial { model.materials = [rightWallPhotoMaterial] }
                    entity.components.set(model)
                }
                if entity.name.hasPrefix("wall.stripe."), item.photoData != nil { entity.removeFromParent(); return }
                for child in Array(entity.children) { applyWallPhotos(child) }
            }
            applyWallPhotos(root)
            for child in root.children where child.name.hasPrefix("window.") {
                let heightScale: Float = (cutaway || roomOverview) ? 0.85 : 1.14
                child.position.y = (cutaway ? 0.42 : 0.68) + (child.position.y - 0.70) * heightScale
                child.scale.y *= heightScale
                child.position.z += cutaway ? 0.11 : -0.11
            }
        }
        if item.kind.blocksFloor, let contactShadow {
            let shadow = ModelEntity(mesh: .generatePlane(width: s.x * 1.35, depth: s.z * 1.35), materials: [contactShadow])
            shadow.name = "contact-shadow"
            // The checker tiles finish at y=0.003. Keep the contact shadow
            // above them instead of hiding it inside the floor geometry.
            shadow.position.y = cutaway ? 0.006 : 0.002
            shadow.components.set(DynamicLightShadowComponent(castsShadow: false))
            root.addChild(shadow)
        }
        if item.kind == .frame, item.photoData != nil {
            // Baked frames also contain the original heart artwork. Remove that artwork,
            // keeping named frame/mat meshes and any grouping entities intact.
            func removeArtwork(_ entity: Entity) {
                for child in Array(entity.children) {
                    if child.name.hasPrefix("heart") || (child.name.isEmpty && child.components[ModelComponent.self] != nil) { child.removeFromParent() }
                    else { removeArtwork(child) }
                }
            }
            removeArtwork(root)
        }
        if item.kind == .bed {
            box("bed.base", [s.x * 0.96, 0.20, s.z * 0.96], [0, 0.12, 0], CozyRoomPalette.surface, radius: 0.06)
            // Keep the upholstered mattress, pillow and quilt; remove wooden rails.
            for name in ["headboard", "headboard.pile", "frame", "frame.pile", "footboard", "leg", "leg.foot"] {
                for child in Array(root.children) where child.name == name { child.removeFromParent() }
            }
        }
        if let data = item.photoData, item.kind != .wall && item.kind != .frame {
            let names: Set<String>
            switch item.kind {
            case .bed: names = ["duvet", "duvet.fold", "duvet.fold.drape"]
            case .floor: names = ["floor"]
            case .rugRound, .rugSquare: names = ["rug"]
            case .desk: names = ["desktop"]
            case .chair, .sofa: names = ["seat", "seat.base", "backrest", "armrest"]
            case .shelf: names = ["shelf"]
            case .plant: names = ["pot"]
            case .lamp: names = ["shade"]
            default: names = []
            }
            let imageAspect = ImageDownsampling.aspectRatio(data)
            func applySurface(_ entity: Entity) {
                for child in Array(entity.children) {
                    if child.name.hasSuffix(".pile"), names.contains(String(child.name.dropLast(5))) { child.removeFromParent(); continue }
                    if item.kind == .floor && child.name.hasPrefix("floor.tile") { child.removeFromParent(); continue }
                    if names.contains(child.name), var model = child.components[ModelComponent.self] {
                        let vertical = ["backrest", "pot", "shade"].contains(child.name)
                        let native = [.floor, .desk, .shelf].contains(item.kind)
                        let bounds = child.visualBounds(relativeTo: child)
                        let size = bounds.extents * child.scale
                        let aspect = item.kind == .rugRound ? 1 : size.x / max(0.0001, vertical ? size.y : size.z)
                        model.mesh = FurnitureSurfaceGeometry.mesh(model.mesh,
                            planarPhoto: !native && !vertical, verticalPhoto: vertical, singleMaterial: true)
                        var finish = photoMaterial
                        if var photo = finish as? UnlitMaterial {
                            photo.textureCoordinateTransform = FurniturePhotoTransform.make(item, imageAspect: imageAspect, surfaceAspect: aspect)
                            finish = photo
                        }
                        model.materials = [finish]
                        child.components.set(model)
                    }
                    applySurface(child)
                }
            }
            applySurface(root)
        }
        if item.photoData != nil, item.kind == .frame {
            let photo = ModelEntity(mesh: .generatePlane(width: s.x * 0.76, height: s.y * 0.77), materials: [photoMaterial])
            photo.name = "custom-photo"
            let front = (root.findEntity(named: "mat")?.visualBounds(relativeTo: root).max.z ?? 0.0355) + 0.001
            photo.position = [0, s.y / 2, front]
            root.addChild(photo)
        }
        return root
    }

    private static func bakedModel(for kind: FurnitureKind) async -> Entity? {
        if let model = bakedModels[kind] { return model.clone(recursive: true) }
        guard let url = Bundle.main.url(forResource: "cozy_" + kind.rawValue, withExtension: "reality"),
              let model = try? await Entity(contentsOf: url) else { return nil }
        if usesResourceOptimizations {
            // Only the tint is read by restoreMaterials. Keeping the exported
            // normal/color maps here retains another copy per .reality asset.
            func retainTintOnly(_ entity: Entity) {
                if var component = entity.components[ModelComponent.self] {
                    component.materials = component.materials.map { material in
                        guard let source = material as? PhysicallyBasedMaterial else { return material }
                        var tint = PhysicallyBasedMaterial()
                        tint.baseColor = .init(tint: source.baseColor.tint)
                        return tint
                    }
                    entity.components.set(component)
                }
                for child in entity.children { retainTintOnly(child) }
            }
            retainTintOnly(model)
        }
        bakedModels[kind] = model
        return model.clone(recursive: true)
    }

    private static func customizablePart(_ name: String, kind: FurnitureKind) -> Bool {
        let part = name.replacingOccurrences(of: ".pile", with: "")
        switch kind {
        case .bed: return part == "duvet"
        case .chair, .sofa: return ["seat", "seat.base", "backrest", "armrest", "leg", "leg.foot"].contains(part)
        case .desk: return part == "desktop"
        case .shelf: return part == "shelf"
        case .frame: return part == "frame"
        case .lamp: return part == "shade"
        case .rugRound, .rugSquare: return part == "rug"
        case .plant: return part.contains("leaf")
        case .flowerCushion: return part == "flower.petal"
        case .wall: return part.hasPrefix("wall.") || part == "ceiling"
        case .floor: return part == "floor"
        }
    }

    private static func colorHex(_ color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
    }

    private static func material(_ hex: String, usesWindowLighting: Bool, textureRepeat: Float, softness: Float, surfaceScale: Float, surfaceGlow: Float = 0, isFiber: Bool = false, closedSurface: Bool = false, woodTexture: TextureResource? = nil) -> any Material {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: Palette.uiColor(hex))
        if let texture = woodTexture ?? fabricColor { material.baseColor = .init(tint: Palette.uiColor(hex), texture: .init(texture)) }
        if woodTexture == nil, let fabricNormal { material.normal = .init(texture: .init(fabricNormal)) }
        material.textureCoordinateTransform = .init(offset: .zero, scale: [textureRepeat, textureRepeat], rotation: 0)
        material.roughness = .init(floatLiteral: woodTexture == nil ? 0.95 : 0.78)
        material.metallic = .init(floatLiteral: 0)
        material.faceCulling = closedSurface ? .back : .none
        if usesWindowLighting, let fabricShader, var custom = try? CustomMaterial(surfaceShader: fabricShader, lightingModel: .lit) {
            custom.baseColor = .init(tint: Palette.uiColor(hex))
            if let texture = woodTexture ?? fabricColor { custom.baseColor.texture = .init(texture) }
            if woodTexture == nil, let fabricNormal { custom.normal = .init(texture: .init(fabricNormal)) }
            custom.custom.value = [surfaceScale, softness, surfaceGlow, isFiber ? -2 : 1]
            custom.faceCulling = closedSurface ? .back : .none
            return custom
        }
        return material
    }

    static func defaultColor(for kind: FurnitureKind, cutaway: Bool = false) -> String {
        if cutaway, kind == .bed { return "#A2C6F1" }
        return cutaway ? kind.defaultColorName : interiorColor(for: kind)
    }

    private static func interiorColor(for kind: FurnitureKind) -> String {
        switch kind {
        case .floor: "#B98C68"
        case .bed: "#B6CEDD"
        case .chair, .sofa: "#F5F2EB"
        case .frame: "#F3F1ED"
        case .lamp: "#F5F3EC"
        case .rugRound, .rugSquare: "#F5F1E9"
        case .desk, .shelf: "#A17450"
        default: kind.defaultColorName
        }
    }

    static func skyMaterial(at date: Date = .now, profile: RoomDaylight? = nil) async -> UnlitMaterial? {
        let daylight = profile ?? RoomDaylight.at(date)
        if windowSkyPhase == daylight.phase, let windowSky { return windowSky }
        windowSkyPhase = daylight.phase
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 512), format: format).image { renderer in
            let context = renderer.cgContext
            let colors = daylight.sky.map { Palette.uiColor($0).cgColor }
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 0.6, 1]) {
                context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 512), options: [])
            }
            Palette.uiColor(daylight.phase == .night ? "#EDE9CE" : "#FFE3B0").setFill()
            context.fillEllipse(in: CGRect(x: 170, y: daylight.phase == .sunset ? 330 : 50, width: 42, height: 42))
            if daylight.phase == .night {
                for i in 0..<14 { context.fillEllipse(in: CGRect(x: (i * 71) % 250, y: 20 + (i * 83) % 380, width: 2, height: 2)) }
            }
            for (x, y, scale) in [(5.0, 125.0, 1.4), (146.0, 240.0, 0.8)] {
                context.saveGState()
                context.translateBy(x: x, y: y)
                context.scaleBy(x: scale, y: scale)
                let cloud = CGMutablePath()
                for rect in [CGRect(x: 0, y: 8, width: 92, height: 20), CGRect(x: 12, y: -2, width: 38, height: 30), CGRect(x: 36, y: -17, width: 39, height: 45), CGRect(x: 65, y: 1, width: 28, height: 25)] {
                    cloud.addEllipse(in: rect)
                }
                context.addPath(cloud)
                context.clip()
                if let light = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [Palette.uiColor(daylight.phase == .night ? "#8995B0" : "#FFFFFF").cgColor, Palette.uiColor(daylight.phase == .night ? "#52617F" : "#E4F0F6").cgColor] as CFArray, locations: [0, 1]) {
                    context.drawLinearGradient(light, start: CGPoint(x: 0, y: -17), end: CGPoint(x: 0, y: 30), options: [])
                }
                context.restoreGState()
            }
            // Layer broad distant hills and separate round foreground crowns.
            // The old tall, overlapping ellipses hid one another's highlights.
            let foliageShapes: [CGRect] = [
                CGRect(x: -45, y: 376, width: 175, height: 170),
                CGRect(x: 85, y: 360, width: 195, height: 190),
                CGRect(x: -18, y: 445, width: 66, height: 66),
                CGRect(x: 28, y: 421, width: 80, height: 80),
                CGRect(x: 91, y: 449, width: 67, height: 67),
                CGRect(x: 143, y: 424, width: 82, height: 82),
                CGRect(x: 211, y: 451, width: 66, height: 66)
            ]
            for rect in foliageShapes {
                context.saveGState()
                context.addEllipse(in: rect)
                context.clip()
                if let foliage = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [Palette.uiColor(daylight.phase == .night ? "#52665D" : "#D3E3AA").cgColor, Palette.uiColor(daylight.phase == .night ? "#293D3A" : "#52763D").cgColor] as CFArray, locations: [0, 1]) {
                    let highlight = CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.25)
                    context.drawRadialGradient(foliage, startCenter: highlight, startRadius: 0,
                                               endCenter: highlight, endRadius: rect.width * 0.85,
                                               options: [.drawsAfterEndLocation])
                }
                context.restoreGState()
            }
        }
        guard let cgImage = image.cgImage,
              let texture = try? await TextureResource(image: cgImage, options: .init(semantic: .color)) else { return nil }
        var material = UnlitMaterial(applyPostProcessToneMap: false)
        material.color = .init(tint: .white, texture: .init(texture))
        windowSky = material
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
        material.blending = .transparent(opacity: .init(scale: 0.30, texture: .init(mask)))
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
        let rows = 20, columns = 40
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
            // The fabric shader supplies surface detail; sparse geometry preserves
            // the fuzzy silhouette without tens of thousands of subpixel fibers.
            let expected = area * 1600
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

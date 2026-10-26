import Metal
import RealityKit
import UIKit

/// 방 장면에 들어갈 엔티티를 만든다.
/// 가구는 Resources에 `FurnitureKind.assetName`.usdz가 있으면 그 모델을, 없으면 공용 가구 모델을 만든다.
enum SceneFactory {
    static let dollHeight: Float = 0.45

    /// 불러온 USDZ 모델(없으면 nil). 장면을 다시 그릴 때마다 파일을 찾지 않도록 기억해 둔다.
    static func clearCache() {
        furnitureCache.removeAll()
        models.removeAll()
        memoArtwork = nil
    }

    private static var models: [FurnitureKind: Entity?] = [:]

    private struct FurnitureKey: Equatable {
        var item: RoomItemState
        var onFloor: Bool
        var elevation: Float
        var cozy: Bool
        var cutaway: Bool
    }
    private static let furnitureCache = EntityTemplateCache<FurnitureKey>(capacity: 24, byteLimit: 96 * 1024 * 1024)

    /// `onFloor`는 가구 하나만 보여줄 때 벽에 거는 가구도 바닥 높이에 두려고 쓴다.
    static func furniture(_ item: RoomItemState, onFloor: Bool = false, elevation: Float = 0, cozy: Bool = false, cutaway: Bool = false) async -> Entity {
        let key = FurnitureKey(item: item, onFloor: onFloor, elevation: elevation, cozy: cozy, cutaway: cutaway)
        return await furnitureCache.entity(for: key, estimatedCost: 8 * 1024 * 1024 + (item.photoData == nil ? 0 : 12 * 1024 * 1024) + (item.photoData?.count ?? 0)) {
            await buildFurniture(item, onFloor: onFloor, elevation: elevation, cozy: cozy, cutaway: cutaway)
        }
    }

    private static func buildFurniture(_ item: RoomItemState, onFloor: Bool, elevation: Float, cozy: Bool, cutaway: Bool) async -> Entity {
        if models[item.kind] == nil {
            if let url = Bundle.main.url(forResource: item.kind.assetName, withExtension: "usdz") {
                models[item.kind] = .some(try? await Entity(contentsOf: url))
            } else {
                models[item.kind] = .some(nil)
            }
        }
        let entity: Entity
        if let model = models[item.kind] ?? nil {
            entity = model.clone(recursive: true)
        } else if cozy {
            entity = await CozyFurniture.make(item, photoMaterial: material(item), usesWindowLighting: !onFloor, cutaway: cutaway)
        } else if let illustration = try? await FurnitureIllustration.make(item, photoMaterial: material(item)) {
            entity = illustration
        } else {
            entity = await modeledFurniture(item)
        }
        entity.name = "item|\(item.id)"
        let hangs = item.kind.hangsOnWall && !onFloor
        entity.position = [item.x, hangs ? item.kind.hangingHeight : elevation, item.z]
        if item.kind.hangsOnWall {
            let pivot = Entity()
            for child in Array(entity.children) { pivot.addChild(child) }
            pivot.position.y = -item.kind.size.y / 2
            let centered = Entity()
            centered.addChild(pivot)
            centered.position.y = item.kind.size.y / 2
            centered.orientation = simd_quatf(angle: item.yaw, axis: [0, 0, 1])
            entity.addChild(centered)
        }
        entity.orientation = simd_quatf(angle: hangs ? RoomLayout.wall(of: item).yaw : (item.kind.hangsOnWall ? 0 : item.yaw), axis: [0, 1, 0])
        if item.isMirrored {
            if cozy, item.kind == .bed, (models[item.kind] ?? nil) == nil {
                // The procedural bed is symmetric. Reflect only its user artwork;
                // negative scale on the fleece reverses its lighting handedness.
                entity.findEntity(named: "custom-photo")?.scale.x = -1
            } else {
                let visual = Entity()
                for child in Array(entity.children) { visual.addChild(child) }
                visual.scale.x = -1
                entity.addChild(visual)
            }
        }
        // 원본 색상별 메시를 합쳐도 벽 사이의 빈 공간이 충돌 영역이 되지 않게 한다.
        let shapes: [ShapeResource]
        if item.kind == .wall {
            let height: Float = cozy ? CozyRoomShell.maximumHeight : 1.55
            shapes = [ShapeResource.generateBox(size: [0.04, height, 2]).offsetBy(translation: [-1.02, height / 2, 0]),
                      ShapeResource.generateBox(size: [2, height, 0.04]).offsetBy(translation: [0, height / 2, -1.02])]
        } else if item.kind == .floor {
            shapes = [ShapeResource.generateBox(size: [2, 0.145, 2]).offsetBy(translation: [0, -0.0725, 0])]
        } else {
            let size = item.kind.size
            shapes = [ShapeResource.generateBox(size: size).offsetBy(translation: [0, size.y / 2, 0])]
        }
        entity.components.set(CollisionComponent(shapes: shapes))
        return entity
    }

    static func doll(_ doll: DollState) async -> Entity {
        if let preset = doll.preset {
            let entity = Entity()
            let visual = await PresetDollModel.make(preset, detail: .room)
            let body = Entity(); body.name = "body"; body.position.y = dollHeight / 2
            visual.position.y = -dollHeight / 2; body.addChild(visual); entity.addChild(body)
            entity.name = "doll|\(doll.id)"; entity.position = doll.position
            entity.orientation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])
            entity.components.set(CollisionComponent(shapes: [.generateBox(size: [0.3, dollHeight, 0.2]).offsetBy(translation: [0, dollHeight / 2, 0])]))
            if let dance = doll.dance { play(dance, on: entity) }
            return entity
        }
        let image = ImageDownsampling.image(doll.imageData, maxPixel: 1024)
        let aspect = Float((image?.size.width ?? 1) / max(image?.size.height ?? 1, 1))
        var material = UnlitMaterial(applyPostProcessToneMap: false)
        material.faceCulling = .none
        if let image, let cgImage = image.cgImage,
           let texture = try? await TextureResource(image: cgImage, options: .init(semantic: .color)),
           let maskImage = opacityMask(of: image),
           let mask = try? await TextureResource(image: maskImage, options: .init(semantic: .raw)) {
            material.color = .init(tint: .white, texture: .init(texture))
            material.blending = .transparent(opacity: .init(scale: 1, texture: .init(mask)))
            material.opacityThreshold = 0.5
        }
        let plane = ModelEntity(mesh: .generatePlane(width: dollHeight * aspect, height: dollHeight), materials: [material])
        plane.position.y = dollHeight / 2
        plane.name = "body"

        var shadowMaterial = UnlitMaterial(color: .black)
        shadowMaterial.blending = .transparent(opacity: 0.15)
        let shadow = ModelEntity(mesh: .generateCylinder(height: 0.002, radius: dollHeight * aspect * 0.4), materials: [shadowMaterial])
        shadow.position.y = 0.002

        let entity = Entity()
        entity.addChild(shadow)
        entity.addChild(plane)
        // 카메라가 (+x, +z) 쪽에서 보므로 인형 앞면을 그쪽으로 돌린다.
        entity.orientation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])
        entity.position = doll.position
        entity.name = "doll|\(doll.id)"
        // 두께 없는 이미지 면 대신 몸통 전체를 잡을 수 있는 터치 영역을 둔다.
        let body = ShapeResource.generateBox(size: [dollHeight * aspect, dollHeight, 0.06])
            .offsetBy(translation: [0, dollHeight / 2, 0])
        entity.components.set(CollisionComponent(shapes: [body]))
        if let dance = doll.dance {
            play(dance, on: entity)
        }
        return entity
    }

    /// RealityKit은 불투명도 텍스처의 빨강 채널을 읽는다. 알파를 흰(보임)/검정(투명) 이미지로 바꾼다.
    static func opacityMask(of image: UIImage) -> CGImage? {
        guard let cgImage = image.cgImage else { return nil }
        let rect = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: rect.size, format: format).image { context in
            UIColor.black.setFill()
            context.fill(rect)
            context.cgContext.translateBy(x: 0, y: rect.height)
            context.cgContext.scaleBy(x: 1, y: -1)
            context.cgContext.clip(to: rect, mask: cgImage)
            UIColor.white.setFill()
            context.fill(rect)
        }.cgImage
    }

    /// 인형 몸통을 아래를 기준으로 납작하게 눌렀다가 튕기듯 되돌린다.
    static func squish(_ doll: Entity) async {
        guard let body = doll.findEntity(named: "body") else { return }
        var pressed = Transform(scale: [1.15, 0.8, 1], translation: [0, dollHeight * 0.8 / 2, 0])
        pressed.rotation = body.orientation
        body.move(to: pressed, relativeTo: doll, duration: 0.1, timingFunction: .easeOut)
        try? await Task.sleep(for: .milliseconds(110))
        var rest = Transform(scale: [1, 1, 1], translation: [0, dollHeight / 2, 0])
        rest.rotation = body.orientation
        body.move(to: rest, relativeTo: doll, duration: 0.45, timingFunction: .easeOut)
    }

    static func play(_ dance: DanceMove, on entity: Entity) {
        var from = entity.transform
        var to = entity.transform
        let base = entity.orientation
        var duration = 0.4
        switch dance {
        case .bounce:
            to.translation.y += 0.05
            duration = 0.3
        case .jump:
            to.translation.y += 0.15
            duration = 0.35
        case .sway:
            from.rotation = base * simd_quatf(angle: -0.3, axis: [0, 0, 1])
            to.rotation = base * simd_quatf(angle: 0.3, axis: [0, 0, 1])
        case .spin:
            from.rotation = base * simd_quatf(angle: -.pi * 0.9, axis: [0, 1, 0])
            to.rotation = base * simd_quatf(angle: .pi * 0.9, axis: [0, 1, 0])
            duration = 0.8
        case .nod:
            to.rotation = base * simd_quatf(angle: 0.3, axis: [1, 0, 0])
        case .squish:
            from.scale = entity.scale * [1.1, 0.9, 1.1]
            to.scale = entity.scale * [0.92, 1.08, 0.92]
        }
        let animation = FromToByAnimation(from: from, to: to, duration: duration, timing: .easeInOut,
                                          bindTarget: .transform, repeatMode: .autoReverse)
        if let resource = try? AnimationResource.generate(with: animation) {
            entity.playAnimation(resource)
        }
    }

    private static var memoArtwork: UnlitMaterial?

    /// 가구와 같은 원본 질감 필터로 그린 메모보드. 탭하면 방명록이 열린다.
    static func memoBoard() async -> Entity {
        let board = Entity()
        board.name = "board"
        board.position = [-0.977, 1.05, 0.74]

        let edge = UnlitMaterial(color: Palette.uiColor("#E7C3A2"), applyPostProcessToneMap: false)
        board.addChild(ModelEntity(mesh: .generateBox(size: [0.016, 0.38, 0.43]), materials: [edge]))
        if memoArtwork == nil,
           let url = Bundle.main.url(forResource: "memo_board", withExtension: "png")
            ?? Bundle.main.url(forResource: "memo_board", withExtension: "png", subdirectory: "IllustrationTextures"),
           let image = UIImage(contentsOfFile: url.path), let cgImage = image.cgImage,
           let mask = opacityMask(of: image),
           let color = try? await TextureResource(image: cgImage, options: .init(semantic: .color)),
           let opacity = try? await TextureResource(image: mask, options: .init(semantic: .raw)) {
            var material = UnlitMaterial(applyPostProcessToneMap: false)
            material.faceCulling = .none
            material.color = .init(tint: .white, texture: .init(color))
            material.blending = .transparent(opacity: .init(scale: 1, texture: .init(opacity)))
            material.opacityThreshold = 0.1
            memoArtwork = material
        }
        // 왼쪽 위부터 다른 일러스트 면과 같은 이미지 방향으로 붙인다.
        var descriptor = MeshDescriptor(name: "memo-board")
        descriptor.positions = MeshBuffers.Positions([
            SIMD3<Float>(0.014, 0.234375, 0.25), [0.014, 0.234375, -0.25],
            [0.014, -0.234375, -0.25], [0.014, -0.234375, 0.25]
        ])
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates([
            SIMD2<Float>(0, 1), [1, 1], [1, 0], [0, 0]
        ])
        descriptor.primitives = .triangles([0, 1, 2, 0, 2, 3])
        if let mesh = try? MeshResource.generate(from: [descriptor]), let material = memoArtwork {
            board.addChild(ModelEntity(mesh: mesh, materials: [material]))
        }
        board.components.set(CollisionComponent(shapes: [.generateBox(size: [0.05, 0.47, 0.5])]))
        return board
    }

    /// 들고 있는 인형의 발밑에 까는 원. 인형이 떠 있는 높이만큼 내려서 바닥(자리)에 붙인다.
    static func heldRing(below lift: Float) -> Entity {
        var material = UnlitMaterial(color: UIColor(named: "brandAccent") ?? .systemPink)
        material.blending = .transparent(opacity: 0.8)
        let ring = ModelEntity(mesh: .generateCylinder(height: 0.004, radius: 0.16), materials: [material])
        ring.position.y = -lift + 0.008
        return ring
    }

    /// 인형을 끌 때 올려둘 수 있는 자리를 표시하는 판
    static func seatHighlight(_ item: RoomItemState) -> Entity {
        var material = UnlitMaterial(color: UIColor(named: "brandAccent") ?? .systemPink)
        material.blending = .transparent(opacity: 0.55)
        let size = item.kind.size
        let entity = ModelEntity(mesh: .generateBox(size: [size.x * 0.95, 0.004, size.z * 0.95]), materials: [material])
        entity.position = [item.x, (item.kind.seatHeight ?? 0) + 0.006, item.z]
        entity.orientation = simd_quatf(angle: item.yaw, axis: [0, 1, 0])
        return entity
    }

    /// 꾸미기 화면에서 고른 가구를 감싸는 반투명 테두리 상자
    static func selectionBox(_ item: RoomItemState) -> Entity {
        let material = UnlitMaterial(color: Palette.uiColor("#F48FA8"), applyPostProcessToneMap: false)
        let visualSize = item.kind.size
        var size = visualSize
        if item.kind.hangsOnWall {
            size = [abs(cos(item.yaw)) * size.x + abs(sin(item.yaw)) * size.y,
                    abs(sin(item.yaw)) * size.x + abs(cos(item.yaw)) * size.y, size.z]
        }
        size += [0.04, 0.04, 0.04]
        let outline = Entity()
        for axis in 0..<3 {
            let others = (0..<3).filter { $0 != axis }
            let steps = max(1, Int(size[axis] / 0.035))
            for a: Float in [-1, 1] {
                for b: Float in [-1, 1] {
                    for step in stride(from: 0, to: steps, by: 2) {
                        var dashSize = SIMD3<Float>(repeating: 0.004)
                        dashSize[axis] = size[axis] / Float(steps)
                        let dash = ModelEntity(mesh: .generateBox(size: dashSize), materials: [material])
                        dash.position[axis] = -size[axis] / 2 + (Float(step) + 0.5) * dashSize[axis]
                        dash.position[others[0]] = a * size[others[0]] / 2
                        dash.position[others[1]] = b * size[others[1]] / 2
                        outline.addChild(dash)
                    }
                }
            }
        }
        let hangs = item.kind.hangsOnWall
        outline.position = [item.x, (hangs ? item.kind.hangingHeight : 0) + visualSize.y / 2, item.z]
        outline.orientation = simd_quatf(angle: hangs ? RoomLayout.wall(of: item).yaw : item.yaw, axis: [0, 1, 0])
        return outline
    }

    private static func material(_ item: RoomItemState, withPhoto: Bool = true) async -> RealityKit.Material {
        var material = UnlitMaterial(applyPostProcessToneMap: false)
        material.faceCulling = .none
        material.color = .init(tint: Palette.uiColor(item.colorName ?? item.kind.defaultColorName))
        if withPhoto, let data = item.photoData, let cgImage = ImageDownsampling.image(data, maxPixel: 1024)?.cgImage,
           let texture = try? await TextureResource(image: cgImage, options: .init(semantic: .color)) {
            // 맞추기에서 사진 밖으로 나가는 부분은 흰 여백으로 보인다.
            let sampler = MTLSamplerDescriptor()
            sampler.sAddressMode = .clampToBorderColor
            sampler.tAddressMode = .clampToBorderColor
            sampler.borderColor = .opaqueWhite
            sampler.minFilter = .linear
            sampler.magFilter = .linear
            material.color = .init(tint: .white, texture: .init(texture, sampler: .init(sampler)))

            // 면의 가운데를 기준으로, 사진이 보이는 비율을 정한다. 90도로 돌리면 사진의 가로세로가 바뀐다.
            let turned = item.photoTurns % 2 == 1
            let aspect = item.kind.photoAspect
            let ratio = Float(cgImage.width) / Float(cgImage.height) / aspect
            let shown = turned ? 1 / ratio : ratio
            let isFit = item.photoFit == 1
            var visible: SIMD2<Float> = shown > 1 ? [isFit ? 1 : 1 / shown, isFit ? shown : 1] : [isFit ? 1 / shown : 1, isFit ? 1 : shown]
            visible /= item.photoScale
            let scale = SIMD2<Float>(item.photoFlipped ? -visible.x : visible.x, visible.y)
            let angle = Float(item.photoTurns) * .pi / 2
            let half = scale * 0.5
            let rotated = SIMD2<Float>(cos(angle) * half.x - sin(angle) * half.y, sin(angle) * half.x + cos(angle) * half.y)
            material.textureCoordinateTransform = .init(offset: SIMD2(0.5 + item.photoOffsetX, 0.5 + item.photoOffsetY) - rotated, scale: scale, rotation: angle)
        }
        return material
    }

    private static func modeledFurniture(_ item: RoomItemState) async -> Entity {
        let main = await material(item)
        let plain = await material(item, withPhoto: false)
        let root = Entity()
        for part in FurnitureModel.parts(for: item.kind) {
            if part.isPattern && (item.photoData != nil || (item.kind == .wall && item.colorName != nil)) { continue }
            let mesh: MeshResource
            switch part.shape {
            case .box:
                mesh = .generateBox(size: part.size, cornerRadius: min(0.018, part.size.min() / 3))
            case .sphere:
                mesh = .generateSphere(radius: 0.5)
            case .cylinder:
                mesh = .generateCylinder(height: part.size.y, radius: part.size.x / 2)
            }
            let finish: RealityKit.Material
            switch part.finish {
            case .main: finish = main
            case .plain: finish = plain
            default:
                var material = UnlitMaterial(applyPostProcessToneMap: false)
                material.faceCulling = .none
                material.color = .init(tint: FurnitureModel.color(for: part.finish, kind: item.kind))
                finish = material
            }
            let entity = ModelEntity(mesh: mesh, materials: [finish])
            entity.position = part.position
            entity.orientation = simd_quatf(angle: part.tilt, axis: [0, 0, 1])
            if part.shape == .sphere { entity.scale = part.size }
            root.addChild(entity)
        }
        return root
    }
}

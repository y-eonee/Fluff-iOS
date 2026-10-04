import RealityKit
import UIKit

/// 방 장면에 들어갈 엔티티를 만든다.
/// 가구는 Resources에 `FurnitureKind.assetName`.usdz가 있으면 그 모델을, 없으면 임시 도형을 쓴다.
enum SceneFactory {
    static let dollHeight: Float = 0.45

    /// 불러온 USDZ 모델(없으면 nil). 장면을 다시 그릴 때마다 파일을 찾지 않도록 기억해 둔다.
    private static var models: [FurnitureKind: Entity?] = [:]

    static func furniture(_ item: RoomItemState) async -> Entity {
        if models[item.kind] == nil {
            models[item.kind] = .some(try? await Entity(named: item.kind.assetName))
        }
        let entity: Entity
        if let model = models[item.kind] ?? nil {
            entity = model.clone(recursive: true)
        } else {
            entity = await placeholder(item)
        }
        entity.name = "item|\(item.id)"
        entity.position = [item.x, 0, item.z]
        entity.generateCollisionShapes(recursive: true)
        return entity
    }

    static func doll(_ doll: DollState) async -> Entity {
        let image = UIImage(data: doll.imageData)
        let aspect = Float((image?.size.width ?? 1) / max(image?.size.height ?? 1, 1))
        var material = UnlitMaterial()
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
        entity.generateCollisionShapes(recursive: true)
        if let dance = doll.dance {
            play(dance, on: entity)
        }
        return entity
    }

    /// RealityKit은 불투명도 텍스처의 빨강 채널을 읽는다. 알파를 흰(보임)/검정(투명) 이미지로 바꾼다.
    private static func opacityMask(of image: UIImage) -> CGImage? {
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
        }
        let animation = FromToByAnimation(from: from, to: to, duration: duration, timing: .easeInOut,
                                          bindTarget: .transform, repeatMode: .autoReverse)
        if let resource = try? AnimationResource.generate(with: animation) {
            entity.playAnimation(resource)
        }
    }

    /// 인형을 끌 때 올려둘 수 있는 자리를 표시하는 판
    static func seatHighlight(_ item: RoomItemState) -> Entity {
        var material = UnlitMaterial(color: UIColor(named: "brandAccent") ?? .systemPink)
        material.blending = .transparent(opacity: 0.55)
        let size = item.kind.size
        let entity = ModelEntity(mesh: .generateBox(size: [size.x * 0.95, 0.004, size.z * 0.95]), materials: [material])
        entity.position = [item.x, (item.kind.seatHeight ?? 0) + 0.006, item.z]
        return entity
    }

    private static func material(_ item: RoomItemState, withPhoto: Bool = true) async -> RealityKit.Material {
        var material = PhysicallyBasedMaterial()
        material.roughness = 0.9
        material.metallic = 0.0
        material.baseColor = .init(tint: UIColor(named: item.colorName ?? item.kind.defaultColorName) ?? .white)
        if withPhoto, let data = item.photoData, let cgImage = UIImage(data: data)?.cgImage,
           let texture = try? await TextureResource(image: cgImage, options: .init(semantic: .color)) {
            material.baseColor = .init(tint: .white, texture: .init(texture))
            let scale = SIMD2<Float>(item.photoFlipped ? -1 : 1, 1) / item.photoScale
            material.textureCoordinateTransform = .init(offset: .zero, scale: scale, rotation: Float(item.photoTurns) * .pi / 2)
        }
        return material
    }

    private static func placeholder(_ item: RoomItemState) async -> Entity {
        let main = await material(item)
        let plain = await material(item, withPhoto: false)
        let size = item.kind.size
        let root = Entity()

        func box(_ boxSize: SIMD3<Float>, _ center: SIMD3<Float>, _ material: RealityKit.Material) {
            let entity = ModelEntity(mesh: .generateBox(size: boxSize, cornerRadius: min(0.02, boxSize.min() / 2)), materials: [material])
            entity.position = center
            root.addChild(entity)
        }

        func cylinder(height: Float, radius: Float, _ y: Float, _ material: RealityKit.Material) {
            let entity = ModelEntity(mesh: .generateCylinder(height: height, radius: radius), materials: [material])
            entity.position.y = y
            root.addChild(entity)
        }

        switch item.kind {
        case .wall:
            box([0.04, size.y, size.z], [-1.02, size.y / 2, 0], main)
            box([size.x, size.y, 0.04], [0, size.y / 2, -1.02], main)
        case .floor:
            box([size.x, 0.04, size.z], [0, -0.02, 0], main)
        case .bed:
            box([size.x, 0.3, size.z], [0, 0.15, 0], main)
            box([size.x, size.y, 0.06], [0, size.y / 2, -size.z / 2 + 0.03], plain)
        case .desk:
            box([size.x, 0.04, size.z], [0, size.y - 0.02, 0], main)
            for x in [-1, 1] as [Float] {
                for z in [-1, 1] as [Float] {
                    box([0.04, size.y - 0.04, 0.04], [x * (size.x / 2 - 0.03), (size.y - 0.04) / 2, z * (size.z / 2 - 0.03)], plain)
                }
            }
        case .shelf:
            box(size, [0, size.y / 2, 0], main)
        case .chair:
            box([0.06, 0.3, 0.06], [0, 0.15, 0], plain)
            box([size.x, 0.05, size.z], [0, 0.32, 0], main)
            box([size.x, 0.4, 0.04], [0, 0.5, -size.z / 2 + 0.02], plain)
        case .sofa:
            box([size.x, 0.3, size.z], [0, 0.15, 0], main)
            box([size.x, 0.3, 0.1], [0, 0.45, -size.z / 2 + 0.05], plain)
        case .rugRound:
            cylinder(height: 0.01, radius: size.x / 2, 0.005, main)
        case .rugSquare:
            box([size.x, 0.01, size.z], [0, 0.005, 0], main)
        case .plant:
            cylinder(height: 0.2, radius: 0.09, 0.1, await material(RoomItemState(id: item.id, kind: .desk, x: 0, z: 0), withPhoto: false))
            let leaves = ModelEntity(mesh: .generateSphere(radius: 0.14), materials: [main])
            leaves.position.y = 0.33
            root.addChild(leaves)
        case .frame:
            box(size, [0, size.y / 2, 0], plain)
            box([size.x * 0.8, size.y * 0.8, 0.01], [0, size.y / 2, size.z / 2], main)
        case .lamp:
            cylinder(height: size.y, radius: 0.02, size.y / 2, plain)
            let shade = ModelEntity(mesh: .generateSphere(radius: 0.12), materials: [main])
            shade.position.y = size.y
            root.addChild(shade)
        }
        return root
    }
}

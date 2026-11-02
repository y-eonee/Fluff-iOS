import RealityKit

/// Pose changes reuse the loaded plush mesh; only lightweight transforms animate.
@MainActor
final class FocusDollMotion {
    private let doll: Entity
    private let props = Entity()
    private var originals: [DollPart: Transform] = [:]
    private var players: [AnimationPlaybackController] = []
    private var eyes: [Entity] = []
    private var smiles: [Entity] = []

    init(doll: Entity, configuration: PresetConfiguration) {
        self.doll = doll
        for part in DollPart.allCases {
            originals[part] = doll.findEntity(named: part.rawValue)?.transform
        }
        doll.addChild(props)
        func material(_ color: String) -> PhysicallyBasedMaterial {
            var result = PhysicallyBasedMaterial()
            result.baseColor.tint = Palette.uiColor(color)
            result.roughness = 0.95
            return result
        }
        let wood = material("#EBD4AE")
        func add(_ mesh: MeshResource, _ position: SIMD3<Float>, _ mat: PhysicallyBasedMaterial) -> ModelEntity {
            let entity = ModelEntity(mesh: mesh, materials: [mat]); entity.position = position
            props.addChild(entity); return entity
        }
        _ = add(.generateBox(size: [0.32, 0.026, 0.14], cornerRadius: 0.012), [0, 0.083, 0.115], wood)
        for x: Float in [-0.125, 0.125] {
            for z: Float in [0.065, 0.16] {
                _ = add(.generateCylinder(height: 0.07, radius: 0.013), [x, 0.035, z], wood)
            }
        }
        props.name = "focus.study-desk"
        // Real study materials replace the sewing spool, flower and needle.
        let paper = material("#FFF6DE")
        let ink = material("#9B8274")
        let book = Entity(); book.name = "focus.study-book"; props.addChild(book)
        for side: Float in [-1, 1] {
            let page = ModelEntity(mesh: .generateBox(size: [0.06, 0.005, 0.075], cornerRadius: 0.002), materials: [paper])
            page.position = [side * 0.03, 0.103, 0.13]
            page.orientation = simd_quatf(angle: -side * 0.10, axis: [0, 0, 1])
            book.addChild(page)
            for row in 0..<5 {
                let z = Float(row) * 0.009 + 0.105
                let line = PresetEmbroidery.line([[side * 0.012, 0.107, z], [side * 0.050, 0.107, z]], radius: 0.00045, material: ink, name: "focus.book-text")
                book.addChild(line)
            }
        }
        for (index, color) in ["#A8B59A", "#E8B8B0", "#D5C4AA"].enumerated() {
            let y = 0.10 + Float(index) * 0.009
            _ = add(.generateBox(size: [0.054, 0.009, 0.063], cornerRadius: 0.002), [-0.105, y, 0.13], material(color))
        }
        let cup = add(.generateCylinder(height: 0.03, radius: 0.013), [0.115, 0.112, 0.10], material("#E8B8B0"))
        cup.name = "focus.pencil-cup"
        for (index, color) in ["#A8B59A", "#E8B8B0", "#E6C574"].enumerated() {
            _ = add(.generateCylinder(height: 0.045, radius: 0.0015), [0.109 + Float(index) * 0.005, 0.135, 0.10], material(color))
        }
        _ = add(.generateBox(size: [0.036, 0.004, 0.026], cornerRadius: 0.001), [0.105, 0.098, 0.155], material("#E6C574"))
        if let arm = doll.findEntity(named: DollPart.leftArm.rawValue) {
            let pencil = Entity(); pencil.name = "focus.pencil"
            pencil.position = [0.012, 0.022, 0.04]
            pencil.orientation = simd_quatf(angle: 0.4, axis: [0, 0, 1])
            let shaft = ModelEntity(mesh: .generateCylinder(height: 0.05, radius: 0.0018), materials: [material("#E6C574")])
            pencil.addChild(shaft)
            let tip = ModelEntity(mesh: .generateCylinder(height: 0.006, radius: 0.0008), materials: [ink])
            tip.position.y = -0.028; pencil.addChild(tip)
            arm.addChild(pencil)
        }
        if configuration.face == nil, let head = doll.findEntity(named: DollPart.head.rawValue) {
            eyes = head.children.filter { $0.name == "eye" }
            for eye in eyes {
                let path = (0...24).map { i -> SIMD3<Float> in
                    let angle = Float(i) / 24 * .pi
                    return eye.position + SIMD3<Float>(cos(angle) * 0.011, sin(angle) * 0.007, 0.003)
                }
                let smile = PresetEmbroidery.line(path, radius: 0.0018, material: material("#523221"), name: "focus.smiling-eye")
                head.addChild(smile); smiles.append(smile)
            }
        }
    }

    func update(working: Bool, happy: Bool, animating: Bool) {
        players.forEach { $0.stop() }; players.removeAll()
        for (part, transform) in originals { doll.findEntity(named: part.rawValue)?.transform = transform }
        props.isEnabled = working
        doll.findEntity(named: "focus.pencil")?.isEnabled = working
        eyes.forEach { $0.isEnabled = !happy }; smiles.forEach { $0.isEnabled = happy }
        for part in [DollPart.leftArm, .rightArm] {
            guard let arm = doll.findEntity(named: part.rawValue), let base = originals[part] else { continue }
            let side: Float = part == .leftArm ? -1 : 1
            // Rotate around the sewn shoulder, not the center of the paw.
            let pivot = SIMD3<Float>(-side * 0.013, 0.028, -0.02) * base.scale
            func pose(_ angle: Float) -> Transform {
                var result = base
                let rotation = simd_quatf(angle: angle, axis: working ? [1, 0, 0] : [0, 0, 1])
                result.rotation = rotation * base.rotation
                result.translation += pivot - rotation.act(pivot)
                return result
            }
            arm.transform = pose(working ? -0.65 : happy ? side * 1.5 : 0)
            if animating && (working || happy) {
                let end = pose(working ? (part == .leftArm ? -1.25 : -0.78) : side * 1.7)
                let motion = FromToByAnimation<Transform>(from: arm.transform, to: end, duration: working ? 0.8 : 0.55, timing: .easeInOut, bindTarget: .transform, repeatMode: .autoReverse)
                if let animation = try? AnimationResource.generate(with: motion) { players.append(arm.playAnimation(animation.repeat())) }
            }
        }
    }
}

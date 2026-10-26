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
        let wood = material("#EBD4AE"), sage = material("#A8B59A")
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
        _ = add(.generateCylinder(height: 0.032, radius: 0.012), [-0.105, 0.112, 0.13], sage)
        for y: Float in [0.097, 0.129] {
            _ = add(.generateCylinder(height: 0.003, radius: 0.016), [-0.105, y, 0.13], wood)
        }
        for index in 0..<6 {
            let angle = Float(index) / 6 * 2 * .pi
            let petal = add(.generateSphere(radius: 1), [0.018 + cos(angle) * 0.024, 0.108, 0.14 + sin(angle) * 0.024], material("#FFF2D7"))
            petal.scale = [0.018, 0.012, 0.019]
        }
        let center = add(.generateSphere(radius: 1), [0.018, 0.116, 0.14], material("#E6C574"))
        center.scale = [0.014, 0.009, 0.014]
        if let arm = doll.findEntity(named: DollPart.leftArm.rawValue) {
            let needle = ModelEntity(mesh: .generateCylinder(height: 0.056, radius: 0.0009), materials: [material("#B8ABA0")])
            needle.name = "focus.needle"; needle.position = [0.012, 0.022, 0.04]
            needle.orientation = simd_quatf(angle: 0.4, axis: [0, 0, 1]); arm.addChild(needle)
            let thread = (0...24).map { i -> SIMD3<Float> in
                let t = Float(i) / 24
                return [0.012 + t * 0.035, 0.05 - t * 0.065, 0.04 + sin(t * .pi) * 0.015]
            }
            arm.addChild(PresetEmbroidery.line(thread, radius: 0.0006, material: sage, name: "focus.thread"))
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
        doll.findEntity(named: "focus.needle")?.isEnabled = working
        doll.findEntity(named: "focus.thread")?.isEnabled = working
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

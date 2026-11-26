import RealityKit

/// Every seam has an anchor inside both sewn volumes. Resizing a part changes
/// its free end, never its attachment. Each edge depends only on its two parts.
enum PresetAttachmentLayout {
    static func transforms(_ configuration: PresetConfiguration, happy: Bool = false) -> [DollPart: Transform] {
        let shape = configuration.shape
        let body: Float = shape == .bear ? 0.64 : 0.70
        func scale(_ part: DollPart) -> SIMD3<Float> {
            let p = configuration.part(part)
            return [p.size * p.width, p.size * p.length, p.size]
        }
        let p = configuration.part(.torso)
        let torso = Transform(scale: scale(.torso) * SIMD3<Float>(body * (shape == .cat ? 0.88 : 1.08), body, body),
                              translation: [0, (shape == .cat ? 0.112 : 0.122) * body + p.offset * 0.05, 0])
        var result: [DollPart: Transform] = [.torso: torso]
        for part in [DollPart.leftArm, .rightArm, .leftLeg, .rightLeg] {
            let arm = part == .leftArm || part == .rightArm
            let side: Float = part == .leftArm || part == .leftLeg ? -1 : 1
            let local = limbAnchor(part)
            var socket = torsoAnchor(part, shape: shape)
            // Legacy offset values slide along a short, internal seam.
            socket.y += min(0.008, max(-0.008, configuration.part(part).offset * 0.02))
            let rotation = simd_quatf(angle: happy && arm ? -side * 0.65 : 0, axis: [0, 0, 1])
            let limbScale = scale(part) * body
            result[part] = Transform(scale: limbScale, rotation: rotation,
                translation: torso.translation + socket * torso.scale - rotation.act(local * limbScale))
        }
        let headScale = scale(.head) * SIMD3<Float>(1, shape == .rabbit ? 0.97 : shape == .bear ? 1.06 : 1, 1)
        let rotation = simd_quatf(angle: shape == .cat ? -0.045 : 0, axis: [0, 0, 1])
        let neckY = 0.055 + min(0.008, max(-0.008, configuration.part(.head).offset * 0.02))
        let head = Transform(scale: headScale, rotation: rotation,
            translation: torso.translation + SIMD3<Float>(0, neckY, 0.006) * torso.scale - rotation.act(neckAnchor * headScale))
        result[.head] = head
        result[.ears] = head
        return result
    }

    static let neckAnchor = SIMD3<Float>(0, -0.083, 0)
    static func limbAnchor(_ part: DollPart) -> SIMD3<Float> {
        let side: Float = part == .leftArm || part == .leftLeg ? -1 : 1
        return part == .leftArm || part == .rightArm ? [-side * 0.025, 0.038, -0.020] : [0, 0.020, -0.005]
    }
    static func torsoAnchor(_ part: DollPart, shape: DollShape) -> SIMD3<Float> {
        let side: Float = part == .leftArm || part == .leftLeg ? -1 : 1
        return part == .leftArm || part == .rightArm
            ? [side * 0.050, shape == .cat ? 0.013 : 0.028, 0.022]
            : [side * 0.032, -0.032, 0.015]
    }
    static func earAnchor(shape: DollShape, side: Float) -> SIMD3<Float> {
        switch shape {
        case .bear: [side * 0.080, 0.065, -0.018]
        case .rabbit: [side * 0.067, 0.060, 0.006]
        default: [side * 0.075, 0.047, 0.006]
        }
    }
    static func earTransform(_ configuration: PresetConfiguration, side: Float) -> Transform {
        let p = configuration.part(.ears)
        let scale = SIMD3<Float>(p.size * p.width, p.size * p.length, p.size)
        let anchor = earAnchor(shape: configuration.shape, side: side)
        let y: Float = configuration.shape == .cat ? 0.017 : configuration.shape == .bear ? 0.004 : -0.003
        let socket = anchor + SIMD3<Float>(0, y + min(0.004, max(-0.004, p.offset * 0.01)), 0)
        return Transform(scale: scale, translation: socket - anchor * scale)
    }
}

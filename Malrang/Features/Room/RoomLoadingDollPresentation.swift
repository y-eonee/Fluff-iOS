import RealityKit
import UIKit

/// Temporary poses on the same room entity. Saved activity and placement never change.
@MainActor
final class RoomLoadingDollPose {
    private struct Pose {
        let transform: Transform
        let enabled: Bool
        init(_ entity: Entity) { transform = entity.transform; enabled = entity.isEnabled }
    }
    private let doll: Entity
    private var awake: [ObjectIdentifier: Pose] = [:]
    private var room: [(Entity, Pose)] = []

    init(awake doll: Entity) {
        self.doll = doll
        visit(doll) { awake[ObjectIdentifier($0)] = Pose($0) }
    }

    func captureRoomPose() {
        room.removeAll()
        visit(doll) { room.append(($0, Pose($0))) }
    }

    func apply(arrival: Float) {
        if arrival >= 1 { restore(); return }
        for (entity, destination) in room {
            guard let origin = awake[ObjectIdentifier(entity)] else {
                // Closed-eye embroidery is created only by the sleeping pose.
                entity.isEnabled = false
                continue
            }
            entity.transform = arrival <= 0 ? origin.transform : Transform(
                scale: simd_mix(origin.transform.scale, destination.transform.scale, SIMD3(repeating: arrival)),
                rotation: simd_slerp(origin.transform.rotation, destination.transform.rotation, arrival),
                translation: simd_mix(origin.transform.translation, destination.transform.translation, SIMD3(repeating: arrival)))
            entity.isEnabled = origin.enabled
        }
    }

    func restore() {
        for (entity, pose) in room { entity.transform = pose.transform; entity.isEnabled = pose.enabled }
    }

    #if DEBUG
    var hasAwakeParts: Bool {
        room.filter { $0.0 !== doll }.allSatisfy { entity, _ in
            guard let origin = awake[ObjectIdentifier(entity)] else { return !entity.isEnabled }
            return matches(entity.transform, origin.transform) && entity.isEnabled == origin.enabled
        }
    }
    var hasRoomPose: Bool { room.allSatisfy { matches($0.0.transform, $0.1.transform) && $0.0.isEnabled == $0.1.enabled } }
    private func matches(_ a: Transform, _ b: Transform) -> Bool {
        simd_distance(a.translation, b.translation) < 0.00001 && simd_distance(a.scale, b.scale) < 0.00001
            && abs(simd_dot(a.rotation.vector, b.rotation.vector)) > 0.99999
    }
    #endif

    private func visit(_ entity: Entity, _ action: (Entity) -> Void) {
        action(entity)
        for child in entity.children { visit(child, action) }
    }
}

/// The loading doll gets neutral ambient light, then blends into the room's light.
/// Direct room lights are restored along the same arrival path.
@MainActor
final class RoomLoadingDollLighting {
    private let ambient = Entity()
    private let neutral: EnvironmentResource
    private let roomEnvironment: EnvironmentResource
    private let roomExponent: Float
    private let key: DirectionalLight
    private let originalKey: DirectionalLightComponent
    private var receivers: [(Entity, ImageBasedLightReceiverComponent?)] = []
    private var spots: [(SpotLight, Float)] = []
    private var lamps: [(PointLight, Float)] = []
    private var restored = false

    init(doll: Entity, content: Entity, key: DirectionalLight, neutral: EnvironmentResource,
         roomEnvironment: EnvironmentResource, roomExponent: Float) {
        self.key = key; originalKey = key.light
        self.neutral = neutral; self.roomEnvironment = roomEnvironment; self.roomExponent = roomExponent
        ambient.name = "loading-neutral-light"
        content.addChild(ambient)
        func attach(_ entity: Entity) {
            if entity.components[ModelComponent.self] != nil {
                receivers.append((entity, entity.components[ImageBasedLightReceiverComponent.self]))
                entity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: ambient))
            }
            for child in entity.children { attach(child) }
        }
        attach(doll)
        func collect(_ entity: Entity) {
            if let light = entity as? SpotLight { spots.append((light, light.light.intensity)) }
            if let light = entity as? PointLight { lamps.append((light, light.light.intensity)) }
            for child in entity.children { collect(child) }
        }
        collect(content)
        apply(arrival: 0)
    }

    func apply(arrival: Float) {
        guard !restored else { return }
        if arrival >= 1 { restore(); return }
        ambient.components.set(ImageBasedLightComponent(source: .blend(neutral, roomEnvironment, arrival),
            intensityExponent: -0.1 + (roomExponent + 0.1) * arrival))
        var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
        originalKey.color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let t = CGFloat(arrival)
        key.light.color = UIColor(red: 1 + (r - 1) * t, green: 1 + (g - 1) * t, blue: 1 + (b - 1) * t, alpha: 1)
        key.light.intensity = 2550 + (originalKey.intensity - 2550) * arrival
        for (light, intensity) in spots { light.light.intensity = intensity * arrival }
        for (light, intensity) in lamps { light.light.intensity = intensity * arrival }
    }

    func restore() {
        guard !restored else { return }
        key.light = originalKey
        for (light, intensity) in spots { light.light.intensity = intensity }
        for (light, intensity) in lamps { light.light.intensity = intensity }
        for (entity, receiver) in receivers {
            if let receiver { entity.components.set(receiver) }
            else { entity.components.remove(ImageBasedLightReceiverComponent.self) }
        }
        ambient.removeFromParent()
        restored = true
    }

    #if DEBUG
    var isNeutral: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        key.light.color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return abs(r - 1) < 0.00001 && abs(g - 1) < 0.00001 && abs(b - 1) < 0.00001 && abs(key.light.intensity - 2550) < 0.01
            && spots.allSatisfy { $0.0.light.intensity == 0 } && lamps.allSatisfy { $0.0.light.intensity == 0 }
    }
    var isRestored: Bool {
        restored && key.light.color == originalKey.color && abs(key.light.intensity - originalKey.intensity) < 0.01
            && spots.allSatisfy { abs($0.0.light.intensity - $0.1) < 0.01 }
            && lamps.allSatisfy { abs($0.0.light.intensity - $0.1) < 0.01 }
            && receivers.allSatisfy { $0.0.components[ImageBasedLightReceiverComponent.self] == $0.1 }
    }
    #endif
}

import SwiftUI
import RealityKit
import Metal

struct PresetDollView: UIViewRepresentable {
    var configuration: PresetConfiguration
    var cameraDistance: Float = 0.95
    var cameraTarget: Float = 0.22
    var cameraYaw: Float = 0
    var working = false
    var happy = false
    var animating = true
    var onPart: ((DollPart) -> Void)?
    var onSnapshot: ((UIImage) -> Void)?
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(.clear); view.isOpaque = false
        view.environment.lighting.intensityExponent = -1.0
        if let device = MTLCreateSystemDefaultDevice(), let bloom = CozyBloom(device: device, preset: true) {
            view.renderCallbacks.postProcess = { context in bloom.render(context) }
        }
        let anchor = AnchorEntity(world: .zero)
        let camera = PerspectiveCamera(); camera.camera.fieldOfViewInDegrees = 32
        let target = configuration.isPhotoSuit == true ? cameraTarget - 0.015 : cameraTarget
        let distance = configuration.isPhotoSuit == true ? cameraDistance * 0.84 : cameraDistance
        camera.look(at: [0, target, 0], from: [sin(cameraYaw) * distance, target + 0.02, cos(cameraYaw) * distance], relativeTo: nil)
        anchor.addChild(camera)
        let light = DirectionalLight(); light.light.intensity = 2300; light.light.color = Palette.uiColor(configuration.isPhotoSuit == true ? "#FFFDFC" : "#FFF0D4")
        var shadow = DirectionalLightComponent.Shadow()
        shadow.shadowProjection = .automatic(maximumDistance: 2)
        shadow.depthBias = 0.5; light.shadow = shadow
        light.look(at: [0, 0.2, 0], from: [-2, 2.4, 2], relativeTo: nil); anchor.addChild(light)
        let fill = DirectionalLight(); fill.light.intensity = 1000; fill.light.color = Palette.uiColor(configuration.isPhotoSuit == true ? "#F7F5FA" : "#FFF3DF"); fill.look(at: [0, 0.2, 0], from: [0, 0.5, 3], relativeTo: nil); anchor.addChild(fill)
        let rim = DirectionalLight(); rim.light.intensity = 2100; rim.light.color = Palette.uiColor("#FFD0DF")
        rim.look(at: [0, 0.2, 0], from: [1, 0.7, 0.1], relativeTo: nil); anchor.addChild(rim)
        view.scene.addAnchor(anchor)
        context.coordinator.anchor = anchor; context.coordinator.view = view
        view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tap(_:))))
        return view
    }
    func updateUIView(_ view: ARView, context: Context) {
        context.coordinator.onPart = onPart
        context.coordinator.update(configuration, working: working, happy: happy, animating: animating, snapshot: onSnapshot)
    }
    static func dismantleUIView(_ view: ARView, coordinator: Coordinator) { coordinator.task?.cancel(); view.scene.anchors.removeAll() }
    final class Coordinator: NSObject {
        weak var view: ARView?
        var anchor: AnchorEntity?
        var model: Entity?
        var configuration: PresetConfiguration?
        var working = false
        var happy = false
        var animating = true
        var onPart: ((DollPart) -> Void)?
        var task: Task<Void, Never>?
        func update(_ value: PresetConfiguration, working: Bool, happy: Bool, animating: Bool, snapshot: ((UIImage) -> Void)?) {
            guard configuration != value || self.working != working || self.happy != happy || self.animating != animating else { return }
            configuration = value; self.working = working; self.happy = happy; self.animating = animating
            task?.cancel()
            task = Task { @MainActor in
                let entity = await PresetDollModel.make(value, happy: happy)
                guard !Task.isCancelled else { return }
                model?.removeFromParent(); model = entity; anchor?.addChild(entity)
                if working {
                    var wood = PhysicallyBasedMaterial(); wood.baseColor.tint = Palette.uiColor("#EBD4AE"); wood.roughness = 0.9
                    let bench = ModelEntity(mesh: .generateBox(size: [0.32, 0.025, 0.13], cornerRadius: 0.012), materials: [wood])
                    bench.position = [0, 0.09, 0.12]; entity.addChild(bench)
                    for x: Float in [-0.12, 0.12] {
                        let leg = ModelEntity(mesh: .generateCylinder(height: 0.08, radius: 0.013), materials: [wood]); leg.position = [x, 0.04, 0.12]; entity.addChild(leg)
                    }
                    let cushion = await CozyFurniture.make(RoomItemState(id: UUID(), kind: .flowerCushion, x: 0, z: 0), photoMaterial: wood, usesWindowLighting: false)
                    cushion.scale = .init(repeating: 0.35); cushion.position = [0.015, 0.105, 0.13]; entity.addChild(cushion)
                }
                if working, animating, let arm = entity.findEntity(named: DollPart.leftArm.rawValue) {
                    var to = arm.transform; to.rotation = simd_quatf(angle: -0.5, axis: [1, 0, 0]); to.translation.y += 0.02
                    let motion = FromToByAnimation<Transform>(from: arm.transform, to: to, duration: 0.6, timing: .easeInOut, bindTarget: .transform, repeatMode: .autoReverse)
                    if let animation = try? AnimationResource.generate(with: motion) { arm.playAnimation(animation.repeat()) }
                }
                if let snapshot {
                    try? await Task.sleep(for: .milliseconds(600))
                    guard !Task.isCancelled else { return }
                    view?.snapshot(saveToHDR: false) { image in if let image { snapshot(image) } }
                }
            }
        }
        @objc func tap(_ recognizer: UITapGestureRecognizer) {
            guard let view else { return }
            var entity = view.entity(at: recognizer.location(in: view))
            while let current = entity {
                if let part = DollPart(rawValue: current.name) { onPart?(part); return }
                entity = current.parent
            }
        }
    }
}

import SwiftUI
import RealityKit
import Metal

struct PresetDollView: UIViewRepresentable {
    var configuration: PresetConfiguration
    var cameraDistance: Float = 0.95
    var cameraTarget: Float = 0.22
    var cameraYaw: Float = 0
    var focusScene = false
    var working = false
    var happy = false
    var animating = true
    var onPart: ((DollPart) -> Void)?
    var onSnapshot: ((UIImage) -> Void)?
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.renderOptions.formUnion([.disableMotionBlur, .disableDepthOfField, .disableCameraGrain])
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
        context.coordinator.update(configuration, focusScene: focusScene, working: working, happy: happy, animating: animating, snapshot: onSnapshot)
    }
    static func dismantleUIView(_ view: ARView, coordinator: Coordinator) {
        coordinator.task?.cancel()
        coordinator.task = nil
        coordinator.motion = nil
        coordinator.model?.stopAllAnimations(recursive: true)
        coordinator.model = nil
        coordinator.anchor = nil
        coordinator.configuration = nil
        coordinator.renderedConfiguration = nil
        coordinator.onPart = nil
        view.renderCallbacks.postProcess = nil
        view.scene.anchors.removeAll()
    }
    final class Coordinator: NSObject {
        weak var view: ARView?
        var anchor: AnchorEntity?
        var model: Entity?
        var configuration: PresetConfiguration?
        var renderedConfiguration: PresetConfiguration?
        var photoAspect: Float = 1
        var motion: FocusDollMotion?
        var focusScene = false
        var working = false
        var happy = false
        var animating = true
        var onPart: ((DollPart) -> Void)?
        var task: Task<Void, Never>?
        func update(_ value: PresetConfiguration, focusScene: Bool, working: Bool, happy: Bool, animating: Bool, snapshot: ((UIImage) -> Void)?) {
            guard configuration != value || self.focusScene != focusScene || self.working != working || self.happy != happy || self.animating != animating else { return }
            if focusScene, self.focusScene, renderedConfiguration == value, let motion {
                self.working = working; self.happy = happy; self.animating = animating
                motion.update(working: working, happy: happy, animating: animating)
                return
            }
            // Photo gestures only change UVs. Keep the dense plush model and its lighting alive.
            if var previous = renderedConfiguration, let model, value.isPhotoSuit != true,
               self.working == working, self.happy == happy, self.animating == animating {
                previous.faceScale = value.faceScale
                previous.faceOffsetX = value.faceOffsetX
                previous.faceOffsetY = value.faceOffsetY
                if previous == value, value.face != nil,
                   let face = model.findEntity(named: "face.user-photo") as? ModelEntity {
                    configuration = value
                    renderedConfiguration = value
                    let mesh = PresetFaceMesh.photo(aspect: photoAspect,
                        zoom: value.faceScale, offsetX: value.faceOffsetX ?? 0, offsetY: value.faceOffsetY ?? 0,
                        radiusX: 0.081 * value.openingScale, radiusY: 0.072 * value.openingScale)
                    face.model?.mesh = mesh
                    (model.findEntity(named: "face.lining") as? ModelEntity)?.model?.mesh = mesh
                    task?.cancel()
                    if let snapshot {
                        task = Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(600))
                            guard !Task.isCancelled else { return }
                            view?.snapshot(saveToHDR: false) { image in if let image { snapshot(image) } }
                        }
                    }
                    return
                }
            }
            configuration = value; self.focusScene = focusScene; self.working = working; self.happy = happy; self.animating = animating
            task?.cancel()
            task = Task { @MainActor in
                if model != nil {
                    try? await Task.sleep(for: .milliseconds(100))
                    guard !Task.isCancelled else { return }
                }
                let entity = await PresetDollModel.make(value, happy: focusScene ? false : happy)
                guard !Task.isCancelled else { return }
                model?.removeFromParent(); model = entity; anchor?.addChild(entity)
                renderedConfiguration = value
                if let data = value.face { photoAspect = ImageDownsampling.aspectRatio(data) }
                if focusScene {
                    let motion = FocusDollMotion(doll: entity, configuration: value)
                    self.motion = motion
                    motion.update(working: self.working, happy: self.happy, animating: self.animating)
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

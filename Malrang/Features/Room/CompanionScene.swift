import Combine
import RealityKit
import SwiftUI

struct CompanionScene: UIViewRepresentable {
  enum Kind: Equatable {
    case window(hour: Int, weather: Int)
    case radio(playing: Bool)
  }
  let dolls: [DollState]
  let kind: Kind
  var windowFrameColor: String? = nil
  func makeCoordinator() -> Coordinator { Coordinator() }
  func makeUIView(context: Context) -> ARView {
    let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
    view.renderOptions = [.disableMotionBlur, .disableDepthOfField]
    view.environment.background = .color(Palette.uiColor("#FFFDF8"))
    context.coordinator.view = view
    return view
  }
  func updateUIView(_ view: ARView, context: Context) {
    context.coordinator.render(dolls: dolls, kind: kind, frameColor: windowFrameColor)
  }
  static func dismantleUIView(_ view: ARView, coordinator: Coordinator) {
    coordinator.stop()
    view.scene.anchors.removeAll()
    view.environment.lighting.resource = nil
  }

  @MainActor final class Coordinator {
    weak var view: ARView?
    private var task: Task<Void, Never>?
    private var subscription: (any Cancellable)?
    private var currentDolls: [DollState] = []
    private var currentKind: Kind?
    private var currentFrameColor: String?
    private var elapsed: Float = 0
    private var clouds: [Entity] = []
    private var birds: [Entity] = []
    private var companions: [Entity] = []
    private var rain: [Entity] = []
    func stop() {
      task?.cancel()
      subscription?.cancel()
      task = nil
      subscription = nil
      clouds = []
      birds = []
      companions = []
      rain = []
    }
    func render(dolls: [DollState], kind: Kind, frameColor: String?) {
      guard currentDolls != dolls || currentKind != kind || currentFrameColor != frameColor else { return }
      currentDolls = dolls
      currentKind = kind
      currentFrameColor = frameColor
      stop()
      task = Task { await build(dolls, kind, frameColor: frameColor) }
    }
    private func build(_ dolls: [DollState], _ kind: Kind, frameColor: String?) async {
      guard let view else { return }
      let root = AnchorEntity(world: .zero)
      var textile = PhysicallyBasedMaterial()
      textile.roughness = 1.0
      textile.metallic = 0.0
      if let texture = try? await TextureResource(named: "CozyFabricColor") {
        textile.baseColor.texture = .init(texture)
      }
      func material(_ hex: String) -> PhysicallyBasedMaterial {
        var m = textile
        m.baseColor.tint = Palette.uiColor(hex)
        return m
      }
      func box(_ size: SIMD3<Float>, _ at: SIMD3<Float>, _ color: String, radius: Float = 0.04)
        -> ModelEntity
      {
        let e = ModelEntity(
          mesh: .generateBox(
            size: size, cornerRadius: min(radius, min(size.x, min(size.y, size.z)) / 2)),
          materials: [material(color)])
        e.position = at
        root.addChild(e)
        return e
      }
      func ball(_ size: SIMD3<Float>, _ at: SIMD3<Float>, _ color: String) -> ModelEntity {
        let e = ModelEntity(mesh: .generateSphere(radius: 0.5), materials: [material(color)])
        e.scale = size
        e.position = at
        root.addChild(e)
        return e
      }
      let camera = PerspectiveCamera()
      camera.camera.fieldOfViewInDegrees = 40
      let light = DirectionalLight()
      light.light.intensity = 1400
      light.look(at: [0, 0, 0], from: [-2, 4, 3], relativeTo: nil)
      if case .window(let hour, let weather) = kind {
        let night = hour < 6 || hour >= 20
        let sunset = (17..<20).contains(hour)
        view.environment.background = .color(
          Palette.uiColor(night ? "#263450" : sunset ? "#EDB6A4" : "#ABD9E8"))
        light.light.color = Palette.uiColor(night ? "#B5C6EE" : "#FFE5B8")
        light.light.intensity = night ? 500 : 1600
        _ = box([2.6, 0.12, 0.50], [0, 0.05, 0], frameColor ?? "#F5DFBA")
        _ = box([0.10, 2.6, 0.16], [-0.89, 1.2, -0.18], frameColor ?? "#F5DFBA")
        _ = box([0.10, 2.6, 0.16], [0.89, 1.2, -0.18], frameColor ?? "#F5DFBA")
        _ = box([0.035, 2.6, 0.10], [0, 1.2, -0.22], frameColor ?? "#F5DFBA", radius: 0.01)
        _ = box([2.6, 0.6, 0.2], [0, -0.31, -0.10], "#E5B8B1")
        for i in 0..<5 {
          let x = Float(i) - 2
          _ = ball(
            [2.2, 0.8, 1.5], [x * 0.8, -0.22, -2.7 - Float(i % 2)], night ? "#354D4B" : "#91B67E")
          _ = ball([0.20, 0.48, 0.20], [x * 0.58, 0.16, -2.4], night ? "#3F6152" : "#82A567")
        }
        let sky = await WindowSkyModel.make(hour: hour)
        root.addChild(sky.root)
        clouds = sky.clouds
        if !night && weather < 51 { birds = WindowSkyModel.addBirds(to: sky.root) }
        if weather >= 51 {
          let snow = (71...77).contains(weather) || weather == 85 || weather == 86
          for i in 0..<55 {
            let e = ball(
              snow ? [0.014, 0.014, 0.014] : [0.004, 0.06, 0.004],
              [Float(i % 11) * 0.16 - 0.8, Float(i / 11) * 0.4, -0.9 - Float(i % 3) * 0.25],
              "#E8EFF7")
            rain.append(e)
          }
        }
        let count = max(dolls.count, 1)
        for (i, doll) in dolls.enumerated() {
          let model = await model(doll)
          DollRestPose.sitting(model)
          let spacing = min(Float(0.34), 1.35 / Float(count))
          model.position = [(Float(i) - Float(count - 1) / 2) * spacing, 0.10, 0.03]
          model.scale = SIMD3(repeating: min(1, 3.5 / Float(count)))
          model.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])
          root.addChild(model)
          companions.append(model)
        }
        camera.look(at: [0, 0.77, -1.0], from: [0, 0.68, 2.15], relativeTo: nil)
      } else {
        view.environment.background = .color(Palette.uiColor("#FFFDF8"))
        _ = box([2.0, 0.08, 1.5], [0, -0.05, 0], "#F4E7CF")
        _ = box([2.0, 1.5, 0.025], [0, 0.65, -0.48], "#F3D1C7", radius: 0.005)
        for i in 0..<16 {
          _ = box(
            [0.065, 1.5, 0.008], [Float(i) * 0.13 - 1, 0.65, -0.46], "#EABEB5", radius: 0.002)
        }
        _ = box([0.22, 0.68, 0.03], [-0.58, 0.48, -0.42], "#FFE8BC")
        _ = box([0.17, 0.61, 0.035], [-0.58, 0.48, -0.395], "#C5DDD4")
        _ = box([0.014, 0.61, 0.04], [-0.58, 0.48, -0.37], "#FFE8BC", radius: 0.002)
        _ = box([0.20, 0.014, 0.04], [-0.58, 0.48, -0.37], "#FFE8BC", radius: 0.002)
        let radio = await RadioModel.make(playing: kind == .radio(playing: true))
        radio.position = [0.22, 0, 0]
        root.addChild(radio)
        if let doll = dolls.first {
          let model = await model(doll)
          model.position = [-0.14, 0, 0.02]
          root.addChild(model)
          companions.append(model)
          if case .radio(playing: true) = kind {
            model.findEntity(named: DollPart.rightArm.rawValue)?.orientation = simd_quatf(
              angle: -0.9, axis: [0, 0, 1])
          }
        }
        camera.look(at: [0, 0.19, 0], from: [0, 0.38, 1.15], relativeTo: nil)
      }
      guard !Task.isCancelled else { return }
      root.addChild(camera)
      root.addChild(light)
      if let env = await CozyRoomLighting.environmentResource() {
        view.environment.lighting.resource = env
      }
      guard !Task.isCancelled else { return }
      view.scene.anchors.removeAll()
      view.scene.addAnchor(root)
      elapsed = 0
      subscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
        MainActor.assumeIsolated {
          guard let self, !UIAccessibility.isReduceMotionEnabled else { return }
          self.elapsed += Float(min(event.deltaTime, 0.05))
          for cloud in self.clouds {
            cloud.position.x += Float(event.deltaTime) * 0.015
            if cloud.position.x > 2.6 { cloud.position.x = -2.6 }
          }
          for (index, bird) in self.birds.enumerated() {
            bird.position.x += Float(min(event.deltaTime, 0.05)) * 0.13
            if bird.position.x > 2.8 { bird.position.x = -2.8 }
            bird.position.y += sin(self.elapsed * 1.4 + Float(index)) * 0.0004
            for (side, name) in [(Float(-1), "wing.left"), (Float(1), "wing.right")] {
              bird.findEntity(named: name)?.orientation = simd_quatf(angle: side * sin(self.elapsed * 5 + Float(index)) * 0.5, axis: [1, 0, 0])
            }
          }
          for drop in self.rain {
            drop.position.y -= Float(event.deltaTime) * 0.7
            if drop.position.y < 0.1 { drop.position.y = 2.4 }
          }
          for doll in self.companions {
            doll.scale.y = doll.scale.x * (1 + sin(self.elapsed * 1.8) * 0.008)
          }
        }
      }
    }
    private func model(_ doll: DollState) async -> Entity {
      if let config = doll.preset { return await PresetDollModel.make(config) }
      return await PlushCutoutModel.make(doll.imageData)
    }
  }
}

import Combine
import RealityKit
import SwiftUI

struct CompanionScene: UIViewRepresentable {
  enum Kind: Equatable {
    case window(hour: Double, weather: Int)
    case couch
    case radio(playing: Bool)
    case radioArtwork(playing: Bool)
  }
  let dolls: [DollState]
  let kind: Kind
  var windowFrameColor: String? = nil
  var onSpeechAnchor: ((CGPoint) -> Void)? = nil
  func makeCoordinator() -> Coordinator { Coordinator() }
  func makeUIView(context: Context) -> RoomRenderView {
    let view = RoomRenderView(adaptive: true)
    view.sceneBackground = (Palette.uiColor("#FFFDF8"))
    context.coordinator.view = view
    return view
  }
  func updateUIView(_ view: RoomRenderView, context: Context) {
    context.coordinator.onSpeechAnchor = onSpeechAnchor
    context.coordinator.render(dolls: dolls, kind: kind, frameColor: windowFrameColor)
  }
  static func dismantleUIView(_ view: RoomRenderView, coordinator: Coordinator) {
    coordinator.stop()
    view.shutdown()
  }

  @MainActor final class Coordinator {
    weak var view: RoomRenderView?
    var onSpeechAnchor: ((CGPoint) -> Void)?
    private var lastSpeechAnchor: CGPoint?
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
    private var windowLighting: WindowSceneLighting?
    private var timeSinceLighting: Float = 0
    private var windowStartHour: Double = 0
    func stop() {
      task?.cancel()
      subscription?.cancel()
      task = nil
      subscription = nil
      clouds = []
      birds = []
      companions = []
      rain = []
      windowLighting = nil
      lastSpeechAnchor = nil
    }
    func render(dolls: [DollState], kind: Kind, frameColor: String?) {
      guard currentDolls != dolls || currentKind != kind || currentFrameColor != frameColor else { return }
      if currentDolls == dolls, currentFrameColor == frameColor,
         case .window(_, let oldWeather) = currentKind,
         case .window(_, let newWeather) = kind, oldWeather == newWeather {
        currentKind = kind
        return // Time updates reuse all meshes, poses and the cloud animation subscription.
      }
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
        view.sceneBackground = Palette.uiColor("#97C9E9")
        windowStartHour = hour
        root.addChild(await WindowLandscapeModel.make(hour: hour, weather: weather, frameColor: frameColor))
        var shadow = DirectionalLightComponent.Shadow()
        shadow.shadowProjection = .automatic(maximumDistance: 8)
        shadow.depthBias = 1.5
        light.shadow = shadow
        let fill = DirectionalLight()
        fill.look(at: [0, 0.3, -1], from: [2, 2, 3], relativeTo: nil)
        root.addChild(fill)
        let sky = await WindowSkyModel.make(hour: hour, weather: weather)
        root.addChild(sky.root)
        clouds = sky.clouds
        if weather < 51 { birds = WindowSkyModel.addBirds(to: sky.root) }
        windowLighting = WindowSceneLighting(sky: sky, key: light, fill: fill, birds: birds, weather: weather)
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
      } else if case .couch = kind {
        view.sceneBackground = (.clear)
        view.isOpaque = false
        light.light.intensity = 2300
        light.light.color = Palette.uiColor("#FFF3E4")
        light.look(at: [0, 0.2, 0], from: [-2, 2.4, 2], relativeTo: nil)
        var shadow = DirectionalLightComponent.Shadow()
        shadow.shadowProjection = .automatic(maximumDistance: 2)
        shadow.depthBias = 0.5
        light.shadow = shadow
        view.lightingExponent = -0.7
        let fill = DirectionalLight()
        fill.light.intensity = 1600
        fill.light.color = Palette.uiColor("#FFF4E7")
        fill.look(at: [0, 0.2, 0], from: [0, 0.7, 3], relativeTo: nil)
        root.addChild(fill)
        let chosen = Array(dolls.prefix(2))
        for (index, doll) in chosen.enumerated() {
          let model = await model(doll)
          DollRestPose.sitting(model)
          let bounds = model.visualBounds(relativeTo: nil)
          let seatedHeight: Float = 0.54
          let scale: Float = seatedHeight / max(bounds.extents.y, 0.01)
          model.scale = SIMD3(repeating: scale)
          model.position = [(Float(index) - Float(chosen.count - 1) / 2) * 0.40, 0.04 - bounds.min.y * scale, 0]
          root.addChild(model)
          companions.append(model)
        }
        camera.look(at: [0, 0.32, 0], from: [0, 0.32, 1.0], relativeTo: nil)
      } else if case .radioArtwork(let playing) = kind {
        light.light.intensity = 2300
        light.light.color = Palette.uiColor("#FFF3E4")
        view.lightingExponent = -0.7
        var radioShadow = DirectionalLightComponent.Shadow()
        radioShadow.shadowProjection = .automatic(maximumDistance: 2)
        radioShadow.depthBias = 0.5
        light.shadow = radioShadow
        let fill = DirectionalLight()
        fill.light.intensity = 1200
        fill.light.color = Palette.uiColor("#FFF4E7")
        fill.look(at: [0, 0.2, 0], from: [0, 0.7, 3], relativeTo: nil)
        root.addChild(fill)
        view.sceneBackground = (.clear)
        view.isOpaque = false
        if let doll = dolls.first {
          let model = await model(doll)
          root.addChild(model)
          companions.append(model)
          if playing {
            model.findEntity(named: DollPart.rightArm.rawValue)?.orientation = simd_quatf(
              angle: -0.9, axis: [0, 0, 1])
          }
          let bounds = model.visualBounds(relativeTo: nil)
          let distance = max(bounds.extents.y, bounds.extents.x) / (2 * tan(Float.pi / 9)) * 1.27
          camera.look(at: bounds.center, from: bounds.center + [0, 0.015, distance], relativeTo: nil)
        }
      } else {
        view.sceneBackground = (Palette.uiColor("#FFFDF8"))
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
      let environmentProfile: RoomDaylight
      if case .window = kind { environmentProfile = .editor }
      else { environmentProfile = RoomDaylight.at(.now) }
      if let env = await CozyRoomLighting.environmentResource(profile: environmentProfile) {
        view.environmentResource = env
      }
      guard !Task.isCancelled else { return }
      windowLighting?.apply(hour: windowStartHour, view: view)
      view.attach(root, camera: camera)
      #if DEBUG
      DesignPreviewSignal.sceneReady()
      #endif
      elapsed = 0
      subscription = view.subscribe { [weak self] deltaTime in
        MainActor.assumeIsolated {
          guard let self else { return }
          self.timeSinceLighting += Float(deltaTime)
          self.elapsed += Float(min(deltaTime, 0.05))
          if self.timeSinceLighting >= 0.20, let lighting = self.windowLighting, let view = self.view {
            var hour = RoomDaylight.at(RoomDaylight.currentDate).hour
            #if DEBUG
            if let argument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--sky-time-lapse=") }),
               let speed = Double(argument.split(separator: "=").last ?? "") {
              hour = self.windowStartHour + Double(self.elapsed) * speed / 3600
            }
            #endif
            lighting.apply(hour: hour, view: view)
            if let report = self.onSpeechAnchor, !self.companions.isEmpty {
              let speaker = self.companions[self.companions.count / 2]
              let bounds = speaker.visualBounds(relativeTo: nil)
              if let point = view.project([bounds.center.x, bounds.max.y, bounds.center.z]),
                 self.lastSpeechAnchor.map({ hypot($0.x-point.x,$0.y-point.y) >= 0.75 }) ?? true {
                self.lastSpeechAnchor = point
                report(point)
              }
            }
            self.timeSinceLighting = 0
          }
          guard !UIAccessibility.isReduceMotionEnabled else { return }
          for cloud in self.clouds {
            cloud.position.x += Float(deltaTime) * 0.015
            if cloud.position.x > 2.6 { cloud.position.x = -2.6 }
          }
          for (index, bird) in self.birds.enumerated() {
            bird.position.x += Float(min(deltaTime, 0.05)) * 0.13
            if bird.position.x > 2.8 { bird.position.x = -2.8 }
            bird.position.y += sin(self.elapsed * 1.4 + Float(index)) * 0.0004
            for (side, name) in [(Float(-1), "wing.left"), (Float(1), "wing.right")] {
              bird.findEntity(named: name)?.orientation = simd_quatf(angle: side * sin(self.elapsed * 5 + Float(index)) * 0.5, axis: [1, 0, 0])
            }
          }
          for drop in self.rain {
            drop.position.y -= Float(deltaTime) * 0.7
            if drop.position.y < 0.1 { drop.position.y = 2.4 }
          }
          for doll in self.companions {
            doll.scale.y = doll.scale.x * (1 + sin(self.elapsed * 1.8) * 0.008)
          }
        }
      }
    }
    private func model(_ doll: DollState) async -> Entity {
      if let config = doll.preset { return await PresetDollModel.make(config, detail: .full) }
      return await PlushCutoutModel.make(doll.imageData)
    }
  }
}

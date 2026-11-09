import RealityKit
import UIKit

enum CozyRoomLighting {
  static func clearCache() {
    environment = nil
    environmentPhase = nil
    daylightTexture = nil
    daylightTint = nil
  }
  private static var environment: EnvironmentResource?
  private static var environmentPhase: RoomDaylight.Phase?
  private static var daylightTexture: TextureResource?
  private static var daylightTint: SIMD3<Float>?

  static func environmentResource(at date: Date = .now) async -> EnvironmentResource? {
    let profile = RoomDaylight.at(date)
    if environmentPhase == profile.phase, let environment { return environment }
    let size = CGSize(width: 512, height: 256)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
      // Keep the night sky dark while giving the room readable, soft ambient light.
      let ambientSky = profile.phase == .night ? ["#9295B4", "#B9B0B4", "#D5C8BB"] : profile.sky
      let colors = (ambientSky + [ambientSky.last!]).map { Palette.uiColor($0).cgColor }
      if let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray,
        locations: [0, 0.35, 0.65, 1])
      {
        renderer.cgContext.drawLinearGradient(
          gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
      }
    }
    guard let cgImage = image.cgImage else { return nil }
    environment = try? await EnvironmentResource(equirectangular: cgImage)
    environmentPhase = profile.phase
    return environment
  }

  static func apply(_ profile: RoomDaylight, to root: Entity) async {
    let color = UIColor(
      red: CGFloat(profile.tint.x), green: CGFloat(profile.tint.y), blue: CGFloat(profile.tint.z),
      alpha: 1)
    let texture: TextureResource?
    if daylightTint == profile.tint, let cached = daylightTexture {
      texture = cached
    } else {
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: format).image {
        context in
        color.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
      }
      if let cgImage = image.cgImage {
        texture = try? await TextureResource(image: cgImage, options: .init(semantic: .raw))
      } else {
        texture = nil
      }
      daylightTexture = texture
      daylightTint = profile.tint
    }
    let sky = await CozyFurniture.skyMaterial(profile: profile)
    func update(_ entity: Entity) {
      if let light = entity as? SpotLight {
        if light.name == "window-sunlight" || light.name == "window-desk-fill" {
          light.light.color = color
          light.light.intensity = (light.name == "window-sunlight" ? 4400 : 3200) * profile.strength
        }
      }
      if let lamp = entity as? PointLight, lamp.name == "desk-lamp-light" {
        lamp.light.intensity = 190 * (1 - profile.strength)
      }
      if var model = entity.components[ModelComponent.self] {
        if entity.name == "window.sky", let sky { model.materials = [sky] }
        model.materials = model.materials.map { material in
          guard var custom = material as? CustomMaterial else { return material }
          let isFiber = custom.custom.value.w < 0
          custom.custom.value.w = isFiber ? -1 - profile.strength : profile.strength
          if let texture { custom.custom.texture = .init(texture) }
          return custom
        }
        entity.components.set(model)
      }
      for child in entity.children { update(child) }
    }
    update(root)
  }

  static func sunlight() -> Entity {
    let lighting = Entity()
    lighting.name = "window-lighting"
    let sun = SpotLight()
    sun.name = "window-sunlight"
    sun.light.color = Palette.uiColor("#FFE1BA")
    sun.light.intensity = 4400
    sun.light.attenuationRadius = 4
    sun.light.innerAngleInDegrees = 14
    sun.light.outerAngleInDegrees = 34
    sun.shadow = .init()
    // Match the aperture projection direction: +x, -0.65y, +0.30z.
    sun.look(at: [0.60, 0.10, 0.421], from: [-1.20, 1.27, -0.119], relativeTo: nil)
    lighting.addChild(sun)

    // The broad window also illuminates the desk behind the main floor beam.
    // Use a real light so moved furniture receives the light and casts shadows.
    let deskFill = SpotLight()
    deskFill.name = "window-desk-fill"
    deskFill.light.color = Palette.uiColor("#FFE3BC")
    deskFill.light.intensity = 3200
    deskFill.light.attenuationRadius = 4
    deskFill.light.innerAngleInDegrees = 10
    deskFill.light.outerAngleInDegrees = 26
    deskFill.shadow = .init()
    deskFill.look(at: [0.35, 0.47, -0.38], from: [-0.88, 1.15, -0.12], relativeTo: nil)
    lighting.addChild(deskFill)
    return lighting
  }
}

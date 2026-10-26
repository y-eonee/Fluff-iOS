import RealityKit
import UIKit

enum CozyRoomLighting {
    private static var environment: EnvironmentResource?

    static func environmentResource() async -> EnvironmentResource? {
        if let environment { return environment }
        let size = CGSize(width: 512, height: 256)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let colors = ["#D9D3ED", "#FFF2ED", "#F4DEE5", "#C9C2E5"].map { Palette.uiColor($0).cgColor }
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray,
                                         locations: [0, 0.35, 0.65, 1]) {
                renderer.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            }
        }
        guard let cgImage = image.cgImage else { return nil }
        environment = try? await EnvironmentResource(equirectangular: cgImage)
        return environment
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

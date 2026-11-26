import RealityKit
import UIKit

/// Updates the existing scene in place, including across sunrise, sunset and midnight.
@MainActor final class WindowSceneLighting {
    private let dome: ModelEntity?
    private let sun: Entity?
    private let moon: Entity?
    private let stars: Entity?
    private let key: DirectionalLight
    private let fill: DirectionalLight
    private let birds: [Entity]
    private let cloudModels: [ModelEntity]
    private let weather: Int
    init(sky: WindowSkyModel.Scene, key: DirectionalLight, fill: DirectionalLight, birds: [Entity], weather: Int) {
        self.key = key; self.fill = fill; self.birds = birds; self.weather = weather
        dome = sky.root.findEntity(named: "sky.atmosphere") as? ModelEntity
        sun = sky.root.findEntity(named: "sky.sun")
        moon = sky.root.findEntity(named: "sky.crescent")
        stars = sky.root.findEntity(named: "sky.stars")
        cloudModels = sky.clouds.flatMap { $0.children.compactMap { $0 as? ModelEntity } }
    }
    private func color(_ rgb: SIMD3<Float>) -> UIColor {
        UIColor(red: CGFloat(rgb.x),green: CGFloat(rgb.y),blue: CGFloat(rgb.z),alpha: 1)
    }
    func apply(hour: Double, view: RoomRenderView) {
        let p = WindowDayCycle.at(hour: hour)
        if var model = dome?.model, var material = model.materials.first as? CustomMaterial {
            material.custom.value = [Float(p.hour),Float(weather),0,0]
            model.materials = [material]; dome?.model = model
        }
        let camera = SIMD3<Float>(0,0.68,2.15)
        sun?.position = camera + (p.sunPosition-camera)*2
        sun?.components.set(OpacityComponent(opacity: p.daylight))
        moon?.components.set(OpacityComponent(opacity: p.nightVisibility))
        stars?.components.set(OpacityComponent(opacity: p.nightVisibility))
        for bird in birds { bird.components.set(OpacityComponent(opacity: p.daylight)) }
        key.light.color = color(p.light)
        key.light.intensity = 350 + 1600*p.daylight
        let dayPosition = SIMD3<Float>(p.sunPosition.x*3,max(1.3,p.sunPosition.y*2),1)
        let lightPosition = simd_mix(SIMD3<Float>(-2,3,1),dayPosition,SIMD3(repeating:p.daylight))
        key.look(at: [0,0,-3], from: lightPosition, relativeTo: nil)
        fill.light.color = color(simd_mix(SIMD3<Float>(0.65,0.76,1),[0.90,0.96,1],SIMD3(repeating:p.daylight)))
        fill.light.intensity = 170 + 620*p.daylight
        view.lightingExponent = -2.2 + p.daylight*1.7
        let cloudTint = simd_mix(SIMD3<Float>(0.88,0.93,1),[1,1,1],SIMD3(repeating:p.daylight))
        let tint = simd_mix(cloudTint,[1,0.88,0.79],SIMD3(repeating:p.warmth*0.7))
        for entity in cloudModels {
            guard var model = entity.model, var material = model.materials.first as? PhysicallyBasedMaterial else { continue }
            material.baseColor.tint = color(tint)
            material.emissiveIntensity = 0.025 + (1-p.daylight)*0.04
            model.materials = [material]; entity.model = model
        }
    }
}

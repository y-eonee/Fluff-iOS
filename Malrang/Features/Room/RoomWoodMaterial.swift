import RealityKit
import UIKit

/// One small repeating texture replaces separate plank entities. It is generated
/// once and shared across room rebuilds; no work is scheduled per rendered frame.
@MainActor
enum RoomWoodMaterial {
    private static var cached: PhysicallyBasedMaterial?
    private static var grain: TextureResource?
    static func clearCache() { cached = nil; grain = nil }
    static func timberTexture() async -> TextureResource? {
        if let grain { return grain }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 128, height: 512), format: format).image { renderer in
            let context = renderer.cgContext
            UIColor(white: 0.96, alpha: 1).setFill(); context.fill(CGRect(x: 0, y: 0, width: 128, height: 512))
            for strand in 0..<8 {
                let x = CGFloat(strand) * 128 / 8
                context.setStrokeColor(UIColor(white: strand.isMultiple(of: 4) ? 1 : 0.25, alpha: 0.32).cgColor)
                context.setLineWidth(strand.isMultiple(of: 7) ? 3.2 : 2.0)
                context.move(to: CGPoint(x: x, y: 0))
                context.addCurve(to: CGPoint(x: x, y: 512), control1: CGPoint(x: x + 1.8, y: 160), control2: CGPoint(x: x - 1.8, y: 350))
                context.strokePath()
            }
        }
        guard let cgImage = image.cgImage else { return nil }
        grain = try? await TextureResource(image: cgImage, options: .init(semantic: .color))
        return grain
    }
    static func floor() async -> PhysicallyBasedMaterial {
        if let cached { return cached }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512), format: format).image { renderer in
            let context = renderer.cgContext
            let shades = ["#77543F", "#835E47", "#6F4D39", "#90694E", "#79533B", "#896046", "#704C36", "#835C43"]
            for board in 0..<8 {
                let x = CGFloat(board * 64)
                Palette.uiColor(shades[board]).setFill()
                context.fill(CGRect(x: x, y: 0, width: 64, height: 512))
                context.setStrokeColor(Palette.uiColor("#79563E").withAlphaComponent(0.48).cgColor)
                context.setLineWidth(1)
                context.move(to: CGPoint(x: x, y: 0)); context.addLine(to: CGPoint(x: x, y: 512)); context.strokePath()
                let seam = CGFloat((board * 173 + 93) % 512)
                context.move(to: CGPoint(x: x, y: seam)); context.addLine(to: CGPoint(x: x + 64, y: seam)); context.strokePath()
                for grain in 0..<20 {
                    let start = x + CGFloat(grain * 3 + 2)
                    context.setStrokeColor(UIColor(white: grain.isMultiple(of: 3) ? 1 : 0, alpha: 0.035).cgColor)
                    context.setLineWidth(grain.isMultiple(of: 3) ? 1.1 : 0.6)
                    context.move(to: CGPoint(x: start, y: 0))
                    context.addCurve(to: CGPoint(x: start + CGFloat(grain % 3 - 1), y: 512),
                                     control1: CGPoint(x: start + 3, y: 170), control2: CGPoint(x: start - 3, y: 340))
                    context.strokePath()
                }
            }
        }
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = UIColor(white: 0.90, alpha: 1)
        if let cgImage = image.cgImage, let texture = try? await TextureResource(image: cgImage, options: .init(semantic: .color)) {
            material.baseColor.texture = .init(texture)
        }
        material.textureCoordinateTransform.scale = [4, 4]
        material.roughness = 0.82
        material.metallic = 0.0
        cached = material
        return material
    }
}

import RealityKit
import simd

/// Shared crop math for every furniture surface and both room renderers.
enum FurniturePhotoTransform {
    static func make(_ item: RoomItemState, imageAspect: Float, surfaceAspect: Float? = nil) -> UnlitMaterial.TextureCoordinateTransform {
        let source = imageAspect.isFinite && imageAspect > 0 ? imageAspect : 1
        let proposed = surfaceAspect ?? (item.kind == .rugRound ? 1 : item.kind == .bed ? 0.85 / 0.923 : item.kind.photoAspect)
        let aspect = proposed.isFinite && proposed > 0 ? proposed : 1
        let turns = (item.photoTurns % 4 + 4) % 4
        // Rotate the image aspect BEFORE comparing it with the surface aspect.
        let shown = (turns % 2 == 1 ? 1 / source : source) / aspect
        let fit = item.kind.category != .rug && item.photoFit == 1
        var visible: SIMD2<Float> = shown > 1
            ? [fit ? 1 : 1 / shown, fit ? shown : 1]
            : [fit ? 1 / shown : 1, fit ? 1 : shown]
        visible /= item.photoScale.isFinite ? max(1, item.photoScale) : 1
        let angle = Float(turns) * .pi / 2
        let c = cos(angle), s = sin(angle)
        let half = visible / 2
        let rotated = SIMD2(c * half.x - s * half.y, s * half.x + c * half.y)
        let extent = SIMD2(abs(c) * visible.x + abs(s) * visible.y,
                           abs(s) * visible.x + abs(c) * visible.y)
        // A pan cannot move the photo out of the surface. Fit margins remain centered.
        let limit = simd_max(.zero, (SIMD2<Float>(repeating: 1) - extent) / 2)
        let requested = SIMD2(item.photoOffsetX.isFinite ? item.photoOffsetX : 0,
                              item.photoOffsetY.isFinite ? item.photoOffsetY : 0)
        let offset = simd_clamp(requested, -limit, limit)
        return .init(offset: SIMD2<Float>(repeating: 0.5) + offset - rotated, scale: visible, rotation: angle)
    }
}

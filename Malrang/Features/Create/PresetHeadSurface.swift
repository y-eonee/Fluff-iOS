import simd

/// Shared sewn surface keeps the face, embroidery and pile on the same curved panel.
enum PresetHeadSurface {
    static func point(latitude y: Float, angle: Float, width: Float) -> SIMD3<Float> {
        let r = sqrt(max(0, 1 - y * y))
        let horizontal = width * pow(r, y < 0 ? 0.78 : 1) * (1 - 0.14 * y)
        return [cos(angle) * horizontal, y * (y < 0 ? 0.100 : 0.108), sin(angle) * pow(r, 0.82) * 0.095]
    }

    static func normal(latitude y: Float, angle: Float, width: Float) -> SIMD3<Float> {
        if abs(y) > 0.99999 { return [0, y > 0 ? 1 : -1, 0] }
        let r = sqrt(1 - y * y), e: Float = y < 0 ? 0.78 : 1
        let h = width * pow(r, e) * (1 - 0.14 * y), d = 0.095 * pow(r, 0.82)
        let dh = width * (-e * y * pow(r, e - 2) * (1 - 0.14 * y) - 0.14 * pow(r, e))
        let dd = -0.095 * 0.82 * y * pow(r, -1.18)
        let height: Float = y < 0 ? 0.100 : 0.108
        return simd_normalize([height * cos(angle) * d,
                               -cos(angle) * cos(angle) * dh * d - sin(angle) * sin(angle) * dd * h,
                               height * sin(angle) * h])
    }

    static func front(x: Float, y: Float, width: Float) -> Float {
        let latitude = y / (y < 0 ? 0.100 : 0.108)
        let r = sqrt(max(0, 1 - latitude * latitude))
        let h = width * pow(r, latitude < 0 ? 0.78 : 1) * (1 - 0.14 * latitude)
        return 0.095 * pow(r, 0.82) * sqrt(max(0, 1 - pow(x / max(h, 0.001), 2)))
    }
}

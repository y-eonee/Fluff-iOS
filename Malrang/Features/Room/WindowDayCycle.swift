import Foundation
import simd

/// Continuous periodic lighting, independent of the room's discrete UI phase names.
nonisolated struct WindowDayCycle {
    let hour: Double
    let sky: [SIMD3<Float>]
    let daylight: Float
    let warmth: Float
    let light: SIMD3<Float>
    static func rgb(_ hex: UInt32) -> SIMD3<Float> {
        SIMD3(Float((hex >> 16) & 255), Float((hex >> 8) & 255), Float(hex & 255)) / 255
    }
    static func at(hour: Double) -> Self {
        let h = (hour.truncatingRemainder(dividingBy: 24) + 24).truncatingRemainder(dividingBy: 24)
        let knots: [(Double, [UInt32], Float, Float, SIMD3<Float>)] = [
            (0, [0x132440,0x304365,0x65758F], 0, 0, [0.64,0.75,1]),
            (5, [0x172C4D,0x3A567B,0x8C9DB5], 0, 0, [0.64,0.75,1]),
            (6, [0x6999C7,0xADCDE7,0xE6E9EE], 0.22, 0.12, [0.91,0.94,1]),
            (7.5, [0x4C9DD8,0x97CBEB,0xDCEFFA], 0.8, 0, [0.98,0.99,1]),
            (9, [0x4398D5,0x8BC5E9,0xD8EFF9], 1, 0, [1,0.99,0.96]),
            (13, [0x4A9CD8,0x92C8E8,0xDCEEF3], 1, 0, [1,0.98,0.93]),
            (16, [0x659DD0,0xADCDE3,0xE6E5DF], 0.92, 0.12, [1,0.91,0.78]),
            (18, [0x766AAB,0xD9A9BC,0xFFD6A5], 0.55, 1, [1,0.72,0.51]),
            (19, [0x414872,0x9C829C,0xD6ACA5], 0.18, 0.55, [0.84,0.78,0.94]),
            (20.5, [0x132440,0x304365,0x65758F], 0, 0, [0.64,0.75,1]),
            (24, [0x132440,0x304365,0x65758F], 0, 0, [0.64,0.75,1])
        ]
        let index = (0..<knots.count - 1).first { h <= knots[$0 + 1].0 } ?? 0
        let a = knots[index], b = knots[index + 1]
        let t = Float((h - a.0) / (b.0 - a.0)), s = t * t * (3 - 2 * t)
        return .init(hour: h, sky: zip(a.1,b.1).map { simd_mix(rgb($0.0),rgb($0.1),SIMD3(repeating:s)) },
                     daylight: a.2 + (b.2-a.2)*s, warmth: a.3 + (b.3-a.3)*s,
                     light: simd_mix(a.4,b.4,SIMD3(repeating:s)))
    }
    var sunPosition: SIMD3<Float> {
        let progress = min(1,max(0,Float((hour-5.5)/14.5)))
        return [-0.75 + progress*1.45, 0.56 + sin(progress * .pi)*1.43, -3.5]
    }
    var nightVisibility: Float {
        let t = min(1,max(0,(0.42-daylight)/0.42))
        return t*t*(3-2*t)
    }
}

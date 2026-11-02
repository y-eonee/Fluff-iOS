import Foundation
import simd

/// Local device time drives the room; values describe 3D illumination, not UI colors.
struct RoomDaylight: Equatable {
  enum Phase: Int { case night, morning, day, sunset }
  let phase: Phase
  let strength: Float
  let tint: SIMD3<Float>
  let hour: Double
  var sky: [String] {
    switch phase {
    case .night: ["#1D2949", "#394766", "#65718C"]
    case .morning: ["#A9CCD9", "#EDD9D4", "#FFE8C8"]
    case .day: ["#8DC6DE", "#C5E1EA", "#F4EDD9"]
    case .sunset: ["#9A86B5", "#E6A6AF", "#FFD5A8"]
    }
  }
  static var currentDate: Date {
    #if DEBUG
      if let value = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--room-hour=") }
      )?.split(separator: "=").last,
        let hour = Int(value), (0...23).contains(hour)
      {
        return Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
      }
    #endif
    return .now
  }
  static func at(_ date: Date = .now, calendar: Calendar = .current) -> Self {
    let components = calendar.dateComponents([.hour, .minute], from: date)
    return at(hour: Double(components.hour ?? 12) + Double(components.minute ?? 0) / 60)
  }
  static func at(hour: Double) -> Self {
    let h = max(0, min(24, hour))
    let knots: [(Double, Float, SIMD3<Float>)] = [
      (0, 0.025, [0.54, 0.66, 1]), (5, 0.025, [0.54, 0.66, 1]),
      (7, 0.55, [1, 0.82, 0.64]), (12, 1, [1, 0.94, 0.82]),
      (16, 0.9, [1, 0.88, 0.72]), (18, 0.42, [1, 0.56, 0.36]),
      (20, 0.025, [0.54, 0.66, 1]), (24, 0.025, [0.54, 0.66, 1]),
    ]
    let index = (0..<knots.count - 1).first { h <= knots[$0 + 1].0 } ?? knots.count - 2
    let a = knots[index]
    let b = knots[index + 1]
    let t = Float((h - a.0) / (b.0 - a.0))
    let phase: Phase = h < 6 || h >= 20 ? .night : h < 10 ? .morning : h < 17 ? .day : .sunset
    return .init(
      phase: phase, strength: a.1 + (b.1 - a.1) * t, tint: simd_mix(a.2, b.2, SIMD3(repeating: t)),
      hour: h)
  }
}

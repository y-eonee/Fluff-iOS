import Foundation
import simd

@main struct WindowDayCycleChecks {
    static func main() {
        let morning = WindowDayCycle.at(hour: 9)
        precondition(morning.sky.allSatisfy { $0.z > $0.x && $0.z >= $0.y }, "Morning must stay blue through the horizon")
        precondition(morning.warmth == 0 && morning.daylight == 1)
        precondition(morning.light.min() > 0.94, "Morning lighting must not tint white clouds orange")
        for boundary in [0.0,5,6,7.5,9,10,13,16,17,18,19,20,20.5,24] {
            let before = WindowDayCycle.at(hour: boundary - 1.0/3600)
            let after = WindowDayCycle.at(hour: boundary + 1.0/3600)
            for (a,b) in zip(before.sky,after.sky) { precondition(simd_distance(a,b)<0.001, "Sky jump at \(boundary)") }
            precondition(abs(before.daylight-after.daylight)<0.001)
            precondition(abs(before.nightVisibility-after.nightVisibility)<0.001)
            precondition(simd_distance(before.light,after.light)<0.001)
        }
        for minute in 0..<1440 {
            let p = WindowDayCycle.at(hour:Double(minute)/60)
            precondition((0...1).contains(p.daylight) && (0...1).contains(p.nightVisibility))
            precondition(p.sky.allSatisfy { $0.min()>=0 && $0.max()<=1 })
            precondition(p.sunPosition.x.isFinite && p.sunPosition.y.isFinite)
        }
        precondition(WindowDayCycle.at(hour:23.999).nightVisibility==1)
        precondition(WindowDayCycle.at(hour:0.001).nightVisibility==1)
        print("PASS: blue 09:00; neutral morning light; continuous sky, lights and celestial fades at every boundary and midnight; 1,440 minute samples")
    }
}

// xcrun swiftc -parse-as-library Malrang/Models/FurnitureKind.swift Malrang/Features/Room/FurnitureModelB.swift scripts/check_furniture_b.swift -o /tmp/check-furniture-b
import Foundation

@main struct FurnitureBChecks {
    static func main() {
        var checks = 0
        func check(_ value: Bool, _ message: String) {
            precondition(value, message)
            checks += 1
        }
        for kind in FurnitureKind.allCases {
            let parts = FurnitureModelB.parts(for: kind)
            check(!parts.isEmpty, "Missing B model: \(kind)")
            check(parts.contains(where: \.photo), "Missing photo surface: \(kind)")
            check(FurnitureModelB.photoAspect(for: kind).isFinite && FurnitureModelB.photoAspect(for: kind) > 0, "Invalid B photo ratio")
            for part in parts {
                check((0..<3).allSatisfy { part.size[$0].isFinite && part.size[$0] > 0 && part.position[$0].isFinite }, "Invalid B geometry")
                if kind.isMovable {
                    let lo = part.position - part.size / 2, hi = part.position + part.size / 2
                    check(lo.x >= -kind.size.x / 2 - 0.003 && hi.x <= kind.size.x / 2 + 0.003, "B model escaped x footprint: \(kind)")
                    check(lo.z >= -kind.size.z / 2 - 0.003 && hi.z <= kind.size.z / 2 + 0.003, "B model escaped z footprint: \(kind)")
                    check(lo.y >= -0.003 && hi.y <= kind.size.y + 0.003, "B model escaped height: \(kind)")
                }
            }
            if kind == .floor {
                check(parts.allSatisfy(\.custom), "Floor color must affect every plank and edge")
                let photo = parts.first(where: \.photo)!
                let baseTop = parts[0].position.y + parts[0].size.y / 2
                check(photo.position.y + photo.size.y / 2 > baseTop, "Floor photo hidden below base")
                check(parts.filter(\.pattern).count == 24, "Missing staggered wood planks")
            }
            if kind == .bed {
                let quiltTop = parts.filter(\.pattern).map { $0.position.y + $0.size.y / 2 }.max()!
                check(abs(quiltTop - kind.seatHeight!) < 0.001, "Doll feet must rest on quilt")
            }
        }
        print("Passed \(checks) B model, footprint, photo, floor color, and seating checks")
    }
}

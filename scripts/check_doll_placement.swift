// Run: swiftc Malrang/Models/CozyRoomPalette.swift Malrang/Models/FurnitureKind.swift Malrang/Models/RoomLayout.swift Malrang/DesignSystem/Josa.swift scripts/check_doll_placement.swift -o /tmp/check-doll-placement && /tmp/check-doll-placement
import Foundation
import simd

// Standalone value fixture; placement rules and furniture dimensions come from app sources.
struct RoomItemState: Identifiable, Equatable {
    let id: UUID
    var kind: FurnitureKind
    var x: Float
    var z: Float
    var colorName: String?
    var windowFrameColor: String?
    var photoData: Data?
    var photoScale: Float = 1
    var photoFit = 0
    var photoFlipped = false
    var photoTurns = 0
    var photoOffsetX: Float = 0
    var photoOffsetY: Float = 0
    var yaw: Float = 0
    var isMirrored = false
}

@main struct CheckDollPlacement {
    static func main() {
        precondition("몽글".josa("이", "가") == "몽글이")
        precondition("나나".josa("이", "가") == "나나가")
        precondition("몽글".decomposedStringWithCanonicalMapping.josa("이", "가").hasSuffix("이"))
        for yaw: Float in [0, .pi / 2, .pi, 0.63] {
            let bed = RoomItemState(id: UUID(), kind: .bed, x: -0.2, z: 0.1, yaw: yaw)
            func world(_ x: Float, _ z: Float) -> SIMD2<Float> {
                let offset = simd_quatf(angle: yaw, axis: [0, 1, 0]).act([x, 0, z])
                return [bed.x + offset.x, bed.z + offset.z]
            }
            for x: Float in [-0.30, 0, 0.30] {
                for z: Float in [0.285, 0.335, 0.385] {
                    precondition(RoomLayout.canPlaceDoll(at: world(x, z), in: [bed]))
                }
            }
            let seat = world(0, 0.365)
            precondition(RoomLayout.canPlaceDoll(at: seat, in: [bed]))
            precondition(RoomLayout.seat(at: seat, in: [bed]).height == 0.40)
            precondition(RoomLayout.seat(at: seat, in: [bed], sleepingBeds: [bed.id]).height == 0.53)
            for point in [world(0, -0.18), world(0, 0), world(0, 0.26), world(0.4, 0.365), world(0, 0.44)] {
                precondition(!RoomLayout.canPlaceDoll(at: point, in: [bed]))
                precondition(RoomLayout.blockingDollPlacement(at: point, in: [bed])?.kind == .bed)
            }
        }
        for kind in [FurnitureKind.desk, .plant, .lamp] {
            let item = RoomItemState(id: UUID(), kind: kind, x: 0, z: 0)
            precondition(RoomLayout.blockingDollPlacement(at: .zero, in: [item])?.kind == kind)
        }
        let chair = RoomItemState(id: UUID(), kind: .chair, x: 0, z: 0)
        precondition(RoomLayout.canPlaceDoll(at: .zero, in: [chair]))
        let sofa = RoomItemState(id: UUID(), kind: .sofa, x: 0, z: 0)
        precondition(FurnitureKind.sofa.hasHomeInteraction)
        precondition(!RoomLayout.canPlaceDoll(at: .zero, in: [sofa]))
        precondition(RoomLayout.blockingDollPlacement(at: .zero, in: [sofa])?.id == sofa.id)
        precondition(RoomLayout.seat(at: .zero, in: [sofa]).item == nil)
        precondition(RoomLayout.seat(at: .zero, in: [sofa], includingActivitySeats: true).item?.id == sofa.id)
        precondition(RoomLayout.seat(at: .zero, in: [chair]).height == FurnitureKind.chair.seatHeight)
        // Manual movement rejects every solid piece, including former seats.
        for kind in [FurnitureKind.bed, .chair, .sofa, .desk, .plant, .lamp] {
            for yaw: Float in [0, 0.63, .pi / 2] {
                let item = RoomItemState(id: UUID(), kind: kind, x: 0.173, z: -0.241, yaw: yaw)
                precondition(RoomLayout.blockingFloorDollPlacement(at: [item.x, item.z], in: [item])?.id == item.id)
                let outside = simd_quatf(angle: yaw, axis: [0, 1, 0]).act([kind.size.x / 2 + 0.081, 0, 0])
                precondition(RoomLayout.blockingFloorDollPlacement(at: [item.x + outside.x, item.z + outside.z], in: [item]) == nil)
            }
        }
        for kind in [FurnitureKind.rugRound, .rugSquare, .shelf, .frame] {
            let item = RoomItemState(id: UUID(), kind: kind, x: 0, z: 0)
            precondition(RoomLayout.blockingFloorDollPlacement(at: .zero, in: [item]) == nil)
        }
        let free = SIMD2<Float>(0.173, -0.241)
        precondition(RoomLayout.clampedToFloor(free) == free) // No grid snapping.
        // Sample the actual outline, rather than the round rug's rotated
        // enclosing square, at every room corner and several orientations.
        for kind in [FurnitureKind.rugRound, .rugSquare] {
            let radius: SIMD2<Float> = kind == .rugRound ? [0.759, 0.759] : [0.45, 0.30]
            RoomLayout.registerBounds(for: kind, mirrored: false,
                                      min: [-radius.x, 0, -radius.y], max: [radius.x, 0.03, radius.y])
            for yaw: Float in [0, 0.633, .pi / 4, .pi / 2, .pi, -.pi / 3] {
                for corner: SIMD2<Float> in [[-2, -2], [-2, 2], [2, -2], [2, 2], [0.25, 0.734]] {
                    let rug = RoomItemState(id: UUID(), kind: kind, x: corner.x, z: corner.y, yaw: yaw)
                    let center = RoomLayout.constrained(rug)
                    let outline: [SIMD2<Float>] = kind == .rugRound
                        ? (0..<360).map { angle in
                            let t = Float(angle) * .pi / 180
                            return [radius.x * cos(t), radius.y * sin(t)]
                        } : [[-radius.x, -radius.y], [-radius.x, radius.y], [radius.x, -radius.y], [radius.x, radius.y]]
                    for local in outline {
                        let rotated = simd_quatf(angle: yaw, axis: [0, 1, 0]).act([local.x, 0, local.y])
                        precondition(abs(center.x + rotated.x) <= 0.986)
                        precondition(abs(center.y + rotated.z) <= 0.986)
                    }
                    var inside = rug; inside.x = center.x; inside.z = center.y
                    precondition(simd_distance(RoomLayout.constrained(inside), center) < 0.0001)
                }
            }
        }
        print("PASS: Korean particles, rotated bed seating, sleeping-area exclusion, blocked furniture, chair placement, rotated rug boundaries, free floor placement and all solid furniture rejection")
    }
}

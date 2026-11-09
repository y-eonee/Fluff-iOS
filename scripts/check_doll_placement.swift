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
        print("PASS: Korean particles, rotated bed seating, sleeping-area exclusion, blocked furniture, chair placement")
    }
}

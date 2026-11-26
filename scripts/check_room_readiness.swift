import Foundation

@main
struct CheckRoomReadiness {
    static func main() {
        let readiness = RoomSceneReadiness()
        let departing = UUID(), returning = UUID(), replacement = UUID()
        precondition(!readiness.isReady)
        readiness.begin(departing)
        readiness.presented(departing)
        precondition(readiness.isReady)

        readiness.begin(returning)
        precondition(!readiness.isReady)
        readiness.presented(departing)
        precondition(!readiness.isReady, "An old frame must not dismiss the returning room's loading view")
        readiness.presented(returning)
        precondition(readiness.isReady)
        precondition(!readiness.remove(departing))
        precondition(readiness.isReady, "Late disappearance must not put a rendered room back into loading")
        readiness.begin(returning)
        precondition(readiness.isReady, "Updating the existing scene must not reset readiness")

        readiness.begin(replacement)
        precondition(!readiness.isReady)
        readiness.remove(returning)
        readiness.presented(replacement)
        precondition(readiness.isReady)
        precondition(readiness.remove(replacement))
        precondition(!readiness.isReady)
        readiness.presented(replacement)
        precondition(!readiness.isReady, "A removed renderer cannot report a ready room")
        print("PASS: first frame, late teardown, stale frame, rebuild and removal readiness")
    }
}

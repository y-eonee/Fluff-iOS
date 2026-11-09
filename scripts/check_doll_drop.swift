// swiftc Malrang/Models/DollDropAction.swift scripts/check_doll_drop.swift -o /tmp/check-doll-drop && /tmp/check-doll-drop
import Foundation
import CoreGraphics

@main struct CheckDollDrop {
    static func main() {
        for blocked in [false, true] {
            for overTrash in [false, true] {
                precondition(DollDropAction.resolve(ended: false, overStorage: overTrash, blocked: blocked) == .cancel)
            }
            precondition(DollDropAction.resolve(ended: true, overStorage: true, blocked: blocked) == .store)
        }
        precondition(DollDropAction.resolve(ended: true, overStorage: false, blocked: true) == .cancel)
        precondition(DollDropAction.resolve(ended: true, overStorage: false, blocked: false) == .move)
        precondition(!DollDropAction.isOverStorage(.zero, target: .zero))
        let target = CGRect(x: 150, y: 700, width: 96, height: 96)
        precondition(DollDropAction.isOverStorage(CGPoint(x: 198, y: 748), target: target))
        precondition(DollDropAction.isOverStorage(CGPoint(x: 145, y: 748), target: target))
        precondition(!DollDropAction.isOverStorage(CGPoint(x: 198, y: 680), target: target))
        print("PASS: drag cancellation, invalid furniture, trash priority, empty target, drop target tolerance")
    }
}

import SwiftUI

struct RoomPhotoRemovalDialog: View {
    let itemName: String
    let cancel: () -> Void
    let remove: () -> Void
    var body: some View {
        RepresentativeConfirmDialog(title: "\(itemName)에서 사진을 뺄까요?",
                                    message: "\(itemName)은 원래 색으로 돌아가요.",
                                    verticalOffset: 10.56, leaveTitle: "취소", stayTitle: "빼기", outlinesSecondary: true,
                                    onLeave: cancel, onStay: remove)
            .environment(\.roomFlowDesign, true)
            .accessibilityAction(.escape, cancel)
    }
}

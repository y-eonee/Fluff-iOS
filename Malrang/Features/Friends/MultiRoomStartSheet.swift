import GroupActivities
import SwiftUI

/// 멀티 룸 열기. FaceTime 통화 중이면 바로 SharePlay를 시작하고, 아니면 메시지로 초대를 보낸다.
struct MultiRoomStartSheet: View {
    @Environment(MultiRoom.self) private var multiRoom
    @Environment(\.dismiss) private var dismiss
    @StateObject private var groupState = GroupStateObserver()
    @State private var didFail = false

    private var activity: MultiRoomActivity { MultiRoomActivity(hostToken: multiRoom.deviceToken) }

    var body: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "shareplay")
                .font(.system(size: 56))
                .foregroundStyle(Color.app.ink)
                .accessibilityHidden(true)
            VStack(spacing: Spacing.xs) {
                Text("멀티 룸 열기")
                    .font(.title2.bold())
                Text("친구와 SharePlay로 연결하면 내 방에 함께 들어와\n인형을 같이 옮기고 구경할 수 있어요")
                    .font(.body)
                    .foregroundStyle(Color.app.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            if didFail {
                Text("SharePlay를 시작하지 못했어요. 잠시 뒤 다시 시도해 주세요")
                    .font(.footnote)
                    .foregroundStyle(Color.app.danger)
            }
            if groupState.isEligibleForGroupSession {
                Button("SharePlay 시작") {
                    Task {
                        do {
                            _ = try await activity.activate()
                            dismiss()
                        } catch {
                            didFail = true
                        }
                    }
                }
                .buttonStyle(.primary)
            } else {
                Text("FaceTime 통화 중이면 바로 시작할 수 있어요")
                    .font(.footnote)
                    .foregroundStyle(Color.app.inkSecondary)
                ShareLink(item: activity, preview: SharePreview("말랑 멀티 룸")) {
                    Label("친구에게 초대 보내기", systemImage: "shareplay")
                }
                .buttonStyle(.primary)
            }
        }
        .foregroundStyle(Color.app.ink)
        .padding(Spacing.l)
        .presentationDetents([.medium])
        .presentationBackground(Color.app.background)
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        MultiRoomStartSheet()
            .environment(MultiRoom())
    }
}

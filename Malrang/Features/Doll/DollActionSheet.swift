import SwiftData
import SwiftUI

/// 인형을 탭하면 올라오는 화면. 열자마자 인형을 만질 수 있고, 춤추기·AR은 아래 버튼으로 한다.
struct DollActionSheet: View {
    let doll: Doll
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingAR = false
    @State private var isChoosingDance = false
    @State private var isConfirmingDelete = false
    @State private var isRemoved = false
    @State private var move = DanceMove.bounce

    var body: some View {
        NavigationStack {
            Group {
                if !isRemoved {
                    content
                }
            }
            .background { AppBackground() }
            .navigationTitle(isRemoved ? "" : doll.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기", systemImage: "xmark") { dismiss() }
                }
                if !isRemoved {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        ShareLink(item: Image(uiImage: doll.image), preview: SharePreview(doll.name, image: Image(uiImage: doll.image))) {
                            Label("공유", systemImage: "square.and.arrow.up")
                        }
                        Menu("더보기", systemImage: "ellipsis") {
                            if doll.isPlaced {
                                Button("방에서 빼기", systemImage: "tray.and.arrow.down") { removeFromRoom() }
                            }
                            Button("인형 삭제", systemImage: "trash", role: .destructive) { isConfirmingDelete = true }
                        }
                    }
                }
            }
            .confirmationDialog("이 인형을 삭제할까요?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    isRemoved = true
                    dismiss()
                    modelContext.delete(doll)
                }
            } message: {
                Text("방에서도 사라지고 되돌릴 수 없어요")
            }
        }

    }

    private var content: some View {
        VStack(spacing: 0) {
            Group {
                if isChoosingDance {
                    DancingDoll(image: doll.image, move: move)
                        .accessibilityLabel("\(doll.name), \(move.label) 춤")
                        .padding(Spacing.l)
                } else {
                    SquishyDoll(doll: doll.state)
                }
            }
            .frame(maxHeight: .infinity)
            if isChoosingDance {
                DancePanel(doll: doll, selected: $move) {
                    withAnimation(.spring) { isChoosingDance = false }
                }
                .transition(.move(edge: .bottom))
            } else {
                actions
                    .transition(.move(edge: .bottom))
            }
        }
        .fullScreenCover(isPresented: $isShowingAR) {
            ARCaptureView(doll: doll)
        }
    }

    private var actions: some View {
        VStack(spacing: Spacing.s) {
            HStack(spacing: Spacing.s) {
                Button {
                    move = doll.dance ?? .bounce
                    withAnimation(.spring) { isChoosingDance = true }
                } label: {
                    Label("춤추기", systemImage: "music.note")
                }
                Button {
                    // 방의 3D 화면이 먼저 내려가야 AR 카메라가 그려진다.
                    appState.isShowingAR = true
                    Task {
                        await Task.yield()
                        isShowingAR = true
                    }
                } label: {
                    Label("예절샷 찍기", systemImage: "camera.viewfinder")
                }
            }
            .buttonStyle(.secondary)
            HStack(spacing: Spacing.s) {
                Button(doll.isPlaced ? "위치 옮기기" : "방에 두기") {
                    appState.place(doll)
                    dismiss()
                }
                .buttonStyle(.primary)
                if doll.isPlaced {
                    Button(action: removeFromRoom) {
                        VStack(spacing: Spacing.xxs) {
                            Text("방에서 빼기")
                            Text("인형 목록에 보관").appFont(.caption)
                        }
                    }
                    .buttonStyle(.secondary)
                    .accessibilityLabel("방에서 빼기, 인형 목록에 보관")
                }
            }
        }
        .padding(Spacing.m)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: Radius.large, topTrailingRadius: Radius.large, style: .continuous)
                .fill(Color.app.surface)
                .ignoresSafeArea(edges: .bottom)
        }
        .shadow(color: Color.app.ink.opacity(0.08), radius: 12, y: -4)
    }

    private func removeFromRoom() {
        doll.isPlaced = false
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        DollActionSheet(doll: .sample)
            .environment(AppState())
            .modelContainer(.preview)
    }
}

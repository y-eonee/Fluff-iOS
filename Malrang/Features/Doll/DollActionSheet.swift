import SwiftData
import SwiftUI

/// 인형을 탭하면 올라오는 화면. 열자마자 인형을 만질 수 있고, 춤추기·AR은 아래 버튼으로 한다.
struct DollActionSheet: View {
    let doll: Doll
    var isPushed = false
    var initiallyShowsHistory = false
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingAR = false
    @State private var isChoosingDance = false
    @State private var isConfirmingDelete = false
    @State private var isRemoved = false
    @State private var move = DanceMove.bounce

    var body: some View {
        Group {
            if isPushed { page } else { NavigationStack { page } }
        }
    }

    private var page: some View {
            Group {
                if !isRemoved {
                    content
                }
            }
            .background { AppBackground() }
            .cozyPageTitle("my fluff")
            .toolbar(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isPushed {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("닫기", systemImage: "chevron.left") { dismiss() }
                    }
                }
                if !isRemoved {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Menu("더보기", systemImage: "ellipsis") {
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

    private var content: some View {
        ScrollViewReader { reader in
            ScrollView {
                VStack(spacing: 20) {
                    Group {
                        if isChoosingDance {
                            DancingDoll(image: doll.image, move: move)
                                .accessibilityLabel("\(doll.name), \(move.label) 춤")
                                .padding(24)
                        } else {
                            SquishyDoll(doll: doll.state)
                        }
                    }.frame(height: 340).padding(.horizontal, 52)
                    DollHistoryCard(doll: doll).padding(.horizontal, 18).id("history")
                    if isChoosingDance {
                        DancePanel(doll: doll, selected: $move) {
                            withAnimation(.spring) { isChoosingDance = false }
                        }
                    } else { actions }
                }.padding(.top, 8).padding(.bottom, 24)
            }.scrollIndicators(.hidden)
                .onAppear { if initiallyShowsHistory { reader.scrollTo("history", anchor: .top) } }
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
            if !doll.isPlaced {
                Button("방에 두기") {
                    appState.place(doll)
                    dismiss()
                }.buttonStyle(.primary)
            }
        }
        .padding(Spacing.m)

    }


}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        DollActionSheet(doll: .sample)
            .environment(AppState())
            .modelContainer(.preview)
    }
}

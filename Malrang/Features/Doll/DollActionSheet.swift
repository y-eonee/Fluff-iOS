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
    @State private var move: DanceMove?
    @State private var renaming = false
    @State private var draftName = ""
    @State private var renameFailed = false

    var body: some View {
        Group {
            if isPushed { page } else { NavigationStack { page } }
        }
    }

    private var page: some View {
            Group {
                if !isRemoved {
                    VStack(spacing: 0) {
                        FlowHeader(title: "내 인형") { dismiss() }
                        content
                    }
                }
            }
            .background {
                RepresentativeGradientFill(definition: FlowDesign.profileBackground).ignoresSafeArea()
            }
            .environment(\.updatedFlowDesign, true)
            .toolbar(.hidden, for: .tabBar)
            .preference(key: AppTabBarHiddenPreference.self, value: true)
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden()
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
        SplitStack { wide in
            if wide { dollStage }
        } secondary: { wide in
        ScrollViewReader { reader in
            ScrollView {
                VStack(spacing: 0) {
                    if !wide { dollStage }
                    DollHistoryCard(doll: doll) { draftName = doll.name; renaming = true }.padding(.horizontal, 20).id("history")
                    HStack(spacing: 12) {
                        if !doll.isPlaced {
                            Button("방에 두기", systemImage: "house") { appState.place(doll); dismiss() }
                                .buttonStyle(D1PrimaryStyle())
                        }
                        Button("삭제하기", systemImage: "trash", role: .destructive) { isConfirmingDelete = true }
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }.padding(.horizontal, 20).padding(.top, 18)
                    if isChoosingDance {
                        DancePanel(doll: doll, selected: $move) {
                            withAnimation(.spring) { isChoosingDance = false }
                        }
                    }
                }.padding(.bottom, 24)
            }.scrollIndicators(.hidden)
                .onAppear { if initiallyShowsHistory { reader.scrollTo("history", anchor: .top) } }
        }
        }
        .alert("인형 이름", isPresented: $renaming) {
            TextField("이름", text: $draftName)
            Button("취소", role: .cancel) {}
            Button("저장") {
                let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                let previous = doll.name
                doll.name = name
                do { try modelContext.save() }
                catch { doll.name = previous; renameFailed = true }
            }.disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .alert("이름을 저장하지 못했어요", isPresented: $renameFailed) { Button("확인", role: .cancel) {} }
        .fullScreenCover(isPresented: $isShowingAR) {
            ARCaptureView(doll: doll)
        }
    }

    private var dollStage: some View {
        ZStack(alignment: .top) {
            Image("flow_profile_glow").resizable().scaledToFit()
                .frame(width: 371, height: 259).offset(y: 140)
                .accessibilityHidden(true)
            Group {
                if isChoosingDance, let move {
                    DancingDoll(image: doll.image, move: move, preset: doll.presetConfiguration).padding(24)
                        .accessibilityLabel("\(doll.name), \(move.label) 춤")
                } else {
                    SquishyDoll(doll: doll.state, usesProfileLayout: true)
                }
            }.frame(height: 390).padding(.horizontal, 34).padding(.top, 22)
                .accessibilityAction(named: "춤추기") { startDance() }
                .accessibilityAction(named: "사진 찍기") { startAR() }
        }.frame(height: 420, alignment: .top)
    }

    @ViewBuilder private var profileActions: some View {
        Button("춤추기", systemImage: "music.note", action: startDance)
        Button("사진 찍기", systemImage: "camera.viewfinder", action: startAR)
        if !doll.isPlaced {
            Button("방에 두기", systemImage: "house") { appState.place(doll); dismiss() }
        }
        Button("인형 삭제", systemImage: "trash", role: .destructive) { isConfirmingDelete = true }
    }

    private func startDance() {
        move = doll.dance.flatMap { DanceMove.selectable.contains($0) ? $0 : nil }
        withAnimation(.spring) { isChoosingDance = true }
    }

    private func startAR() {
        appState.isShowingAR = true
        Task { await Task.yield(); isShowingAR = true }
    }



}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        DollActionSheet(doll: .sample)
            .environment(AppState())
            .modelContainer(.preview)
    }
}

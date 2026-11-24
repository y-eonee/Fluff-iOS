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
    @State private var move = DanceMove.morningExercise

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
            .background(FlowDesign.profileCanvas.ignoresSafeArea())
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

    private var firstMetDate: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let parts = calendar.dateComponents([.year, .month, .day], from: doll.createdAt)
        return String(format: "%04d.%02d.%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private var content: some View {
        ScrollViewReader { reader in
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        Image("flow_profile_glow").resizable().scaledToFit()
                            .frame(width: 371, height: 259).offset(y: 163)
                            .accessibilityHidden(true)
                        Group {
                            if isChoosingDance {
                                DancingDoll(image: doll.image, move: move, preset: doll.presetConfiguration).padding(24)
                                    .accessibilityLabel("\(doll.name), \(move.label) 춤")
                            } else {
                                SquishyDoll(doll: doll.state, usesProfileLayout: true)
                            }
                        }.frame(height: 415).padding(.horizontal, 34).padding(.top, 27)
                            .accessibilityAction(named: "춤추기") { startDance() }
                            .accessibilityAction(named: "예절샷 찍기") { startAR() }
                        HStack {
                            Spacer()
                            VStack(spacing: 3) {
                                Text("처음 만난 날").pretendard(.medium, 12)
                                Text(firstMetDate).pretendard(.regular, 14, tracking: -0.7)
                            }.frame(width: 96.21, height: 50.28)
                                .background(.white, in: RoundedRectangle(cornerRadius: 6))
                        }.padding(.trailing, 34).padding(.top, 9)
                        Text(doll.name).pretendard(.semiBold, 15, tracking: -0.75)
                            .padding(.horizontal, 11).padding(.vertical, 3)
                            .background(.white, in: Capsule())
                            .shadow(color: .black.opacity(0.09), radius: 3.45)
                            .offset(y: 422)
                    }.frame(height: 467, alignment: .top)
                    DollHistoryCard(doll: doll).padding(.horizontal, 20).id("history")
                    if isChoosingDance {
                        DancePanel(doll: doll, selected: $move) {
                            withAnimation(.spring) { isChoosingDance = false }
                        }
                    }
                }.padding(.bottom, 24)
            }.scrollIndicators(.hidden)
                .onAppear { if initiallyShowsHistory { reader.scrollTo("history", anchor: .top) } }
        }
        .fullScreenCover(isPresented: $isShowingAR) {
            ARCaptureView(doll: doll)
        }
    }

    @ViewBuilder private var profileActions: some View {
        Button("춤추기", systemImage: "music.note", action: startDance)
        Button("예절샷 찍기", systemImage: "camera.viewfinder", action: startAR)
        if !doll.isPlaced {
            Button("방에 두기", systemImage: "house") { appState.place(doll); dismiss() }
        }
        Button("인형 삭제", systemImage: "trash", role: .destructive) { isConfirmingDelete = true }
    }

    private func startDance() {
        move = DanceMove.selection(for: doll.dance)
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

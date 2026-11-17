import SwiftData
import SwiftUI

struct DollListView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Doll.createdAt, order: .reverse) private var dolls: [Doll]
    @State private var selectedDoll: Doll?
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("my fluff").notCliche(25.397, relativeTo: .title).tracking(-1.778)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .overlay(alignment: .leading) {
                        Button { appState.tab = .home } label: { D1Icon(name: "back").frame(width: 44, height: 44) }
                            .buttonStyle(.plain).padding(.leading, 18).accessibilityLabel("방으로 돌아가기")
                    }.offset(y: 3)
                HStack {
                    Text("내 인형").pretendard(.bold, 18)
                    Spacer()
                    Text("\(dolls.count)개").pretendard(.medium, 12).foregroundStyle(Color.mib.text.secondary)
                }.padding(.horizontal, 22).padding(.top, 34)
                if dolls.isEmpty {
                    VStack(spacing: 16) {
                        D1Icon(name: "cloud").frame(width: 64, height: 64).background(Color.mib.bg.mintSoft, in: RoundedRectangle(cornerRadius: 22))
                        Text("아직 인형이 없어요").pretendard(.bold, 17)
                        D1Bubble(text: "사진 속 최애를 첫 인형으로 만나보세요")
                    }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(.horizontal, 22)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                            ForEach(dolls) { doll in
                                Button { selectedDoll = doll } label: { card(doll) }.buttonStyle(.plain)
                            }
                        }.padding(.horizontal, 22).padding(.bottom, 16)
                    }.scrollIndicators(.hidden).padding(.top, 24)
                }
            }.foregroundStyle(Color.mib.text.primary).background { AppBackground() }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 16) {
                        Button("인형 만들기") { isCreating = true }.buttonStyle(CreationPrimaryButton()).padding(.horizontal, 22)
                    }.padding(.top, 16).padding(.bottom, 106).background(Color.mib.bg.screen)
                }
                .toolbar(.hidden, for: .navigationBar).toolbar(.hidden, for: .tabBar)
                #if DEBUG
                .task {
                    if ProcessInfo.processInfo.arguments.contains("--design-preview=tabs-profile") {
                        selectedDoll = dolls.first { $0.presetConfiguration?.shape == .bear } ?? dolls.first
                    }
                }
                #endif
                .navigationDestination(item: $selectedDoll) { DollActionSheet(doll: $0, isPushed: true) }
                .fullScreenCover(isPresented: $isCreating) { CreateFlowView { doll in appState.place(doll) } }
        }

        .preference(key: AppTabBarHiddenPreference.self, value: selectedDoll != nil)
    }

    private func card(_ doll: Doll) -> some View {
        VStack(spacing: 4) {
            DollThumbnail(data: doll.imageData).frame(height: 80)
            Text(doll.name).pretendard(.regular, 14, tracking: -0.7).lineLimit(1)

        }.padding(8).frame(maxWidth: .infinity).frame(height: 132).background(Color.rep4.c01, in: RoundedRectangle(cornerRadius: 22))
            .overlay(alignment: .topTrailing) {
                ZStack {
                    Image(doll.isPlaced ? "rep4_doll_placed_background" : "rep4_doll_stored_background")
                        .resizable().frame(width: 20.3, height: 21)
                    Image(doll.isPlaced ? "rep4_doll_placed_icon" : "rep4_doll_stored_icon")
                        .resizable().frame(width: 13.295, height: 11.9)
                    if !doll.isPlaced {
                        Image("rep4_doll_stored_slash").resizable().frame(width: 14.845, height: 14.845)
                    }
                }.padding(.top, 13.71).padding(.trailing, 13.14).accessibilityHidden(true)
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore).accessibilityLabel(doll.name)
            .accessibilityValue(doll.isPlaced ? "지금 방에 있어요" : "보관 중")
    }
}

#Preview { DollListView().environment(AppState()).modelContainer(.preview) }

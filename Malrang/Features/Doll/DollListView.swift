import SwiftData
import SwiftUI

struct DollListView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Doll.createdAt, order: .reverse) private var dolls: [Doll]
    @State private var selectedDoll: Doll?
    @State private var isCreating = false
    @State private var sortOrder = DollSort.latest
    private enum DollSort: String, CaseIterable { case latest = "최신순", oldest = "오래된순", name = "이름순" }
    private var sortedDolls: [Doll] {
        switch sortOrder {
        case .latest: dolls
        case .oldest: Array(dolls.reversed())
        case .name: dolls.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                FlowHeader(title: "내 인형")
                HStack {
                    Text("\(dolls.count)개").pretendard(.medium, 12)
                    Spacer()
                    Menu {
                        Picker("정렬", selection: $sortOrder) {
                            ForEach(DollSort.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text(sortOrder.rawValue).pretendard(.medium, 12)
                            Image("fluff_sort").resizable().scaledToFit().frame(width: 12.4764, height: 12.239)
                        }.frame(minHeight: 28)
                    }.accessibilityLabel("인형 정렬").accessibilityValue(sortOrder.rawValue)
                }.foregroundStyle(Color.rep4.c29).padding(.horizontal, 26).padding(.top, 8)
                if dolls.isEmpty {
                    VStack(spacing: 16) {
                        Image("fluff_empty_mongle")
                            .resizable().scaledToFit().frame(width: 180, height: 180)
                            .accessibilityHidden(true)
                        Text("아직 인형이 없어요").pretendard(.bold, 17)
                        Text("사진 속 최애를 첫 인형으로 만나보세요")
                            .pretendard(.medium, 13)
                            .foregroundStyle(Color.mib.text.secondary)
                            .multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(.horizontal, 22)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                            ForEach(sortedDolls) { doll in
                                Button { selectedDoll = doll } label: { card(doll) }.buttonStyle(.plain)
                            }
                        }.padding(.horizontal, 22).padding(.bottom, 16)
                    }.scrollIndicators(.hidden).padding(.top, 7)
                }
            }.foregroundStyle(Color.rep4.c08).background(FlowDesign.canvas.ignoresSafeArea())
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 16) {
                        Button("인형 만들기") { isCreating = true }.buttonStyle(CreationPrimaryButton()).padding(.horizontal, 22)
                    // TabView overlays the outer tab inset; reserve its height plus the reference's 35pt CTA gap.
                    }.padding(.top, 16).padding(.bottom, 112).background(FlowDesign.canvas)
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
        VStack(spacing: 5) {
            DollThumbnail(data: doll.imageData).frame(width: 78, height: 78)
            Text(doll.name).pretendard(.regular, 14, tracking: -0.7).lineLimit(1)

        }.padding(.top, 21.21).frame(maxWidth: .infinity).frame(height: 132, alignment: .top).background(Color.rep4.c01, in: RoundedRectangle(cornerRadius: 22))
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

import SwiftData
import SwiftUI

struct DollListView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Doll.createdAt, order: .reverse) private var dolls: [Doll]
    @State private var selectedDoll: Doll?
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("my fluff").notCliche(28, relativeTo: .title).tracking(-1.12)
                    .frame(maxWidth: .infinity).frame(height: 44)
                HStack {
                    Text("나의 솜뭉치들").pretendard(.bold, 17)
                    Spacer()
                    Text("\(dolls.count)명").pretendard(.medium, 13).foregroundStyle(Color.mib.text.secondary)
                }.padding(.horizontal, 22)
                if dolls.isEmpty {
                    VStack(spacing: 16) {
                        D1Icon(name: "cloud").frame(width: 64, height: 64).background(Color.mib.bg.mintSoft, in: RoundedRectangle(cornerRadius: 22))
                        Text("아직 솜뭉치가 없어요").pretendard(.bold, 17)
                        D1Bubble(text: "사진 속 최애를 첫 솜뭉치로 만나보세요")
                    }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(.horizontal, 22)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(dolls) { doll in
                                Button { selectedDoll = doll } label: { card(doll) }.buttonStyle(.plain)
                            }
                        }.padding(.horizontal, 22).padding(.bottom, 16)
                    }.scrollIndicators(.hidden)
                }
            }.foregroundStyle(Color.mib.text.primary).background(Color.mib.bg.screen)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 16) {
                        Button("인형 만들기") { isCreating = true }.buttonStyle(D1PrimaryStyle()).padding(.horizontal, 22)
                        D1HomeTabs(selection: Binding(get: { appState.tab }, set: { appState.tab = $0 }))
                    }.padding(.top, 16).background(Color.mib.bg.screen)
                }
                .toolbar(.hidden, for: .navigationBar).toolbar(.hidden, for: .tabBar)
                .sheet(item: $selectedDoll) { DollActionSheet(doll: $0) }
                .fullScreenCover(isPresented: $isCreating) { CreateFlowView { doll in appState.place(doll) } }
        }
    }

    private func card(_ doll: Doll) -> some View {
        VStack(spacing: 4) {
            DollThumbnail(data: doll.imageData).frame(height: 80)
            Text(doll.name).pretendard(.regular, 16).lineLimit(1)
        }.padding(8).frame(maxWidth: .infinity).frame(height: 128).d1Surface(radius: 14)
            .overlay(alignment: .topTrailing) {
                if doll.isPlaced {
                    D1Icon(name: "homeTab").padding(4).background(Color.mib.bg.mintSoft, in: RoundedRectangle(cornerRadius: 10)).padding(8)
                }
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore).accessibilityLabel(doll.name)
            .accessibilityValue(doll.isPlaced ? "내 방에 있어요" : "보관 중")
    }
}

#Preview { DollListView().environment(AppState()).modelContainer(.preview) }

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
                    Text("내 인형").pretendard(.bold, 18)
                    Spacer()
                    Text("\(dolls.count)개").pretendard(.medium, 12).foregroundStyle(Color.mib.text.secondary)
                }.padding(.horizontal, 22)
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
                    }.scrollIndicators(.hidden)
                }
            }.foregroundStyle(Color.mib.text.primary).background(Color.mib.bg.screen)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 16) {
                        Button("인형 만들기") { isCreating = true }.buttonStyle(CreationPrimaryButton()).padding(.horizontal, 22)
                    }.padding(.top, 16).padding(.bottom, 24).background(Color.mib.bg.screen)
                }
                .toolbar(.hidden, for: .navigationBar).toolbar(.visible, for: .tabBar)
                #if DEBUG
                .task {
                    if ProcessInfo.processInfo.arguments.contains("--design-preview=tabs-profile") {
                        selectedDoll = dolls.first
                    }
                }
                #endif
                .navigationDestination(item: $selectedDoll) { DollActionSheet(doll: $0, isPushed: true) }
                .fullScreenCover(isPresented: $isCreating) { CreateFlowView { doll in appState.place(doll) } }
        }
    }

    private func card(_ doll: Doll) -> some View {
        VStack(spacing: 4) {
            DollThumbnail(data: doll.imageData).frame(height: 64)
            Text(doll.name).pretendard(.medium, 14).lineLimit(1)
            Label(doll.isPlaced ? "지금 방에 있어요" : "보관 중", systemImage: doll.isPlaced ? "house" : "archivebox")
                .pretendard(.medium, 10).foregroundStyle(Color.mib.text.secondary)
        }.padding(8).frame(maxWidth: .infinity).frame(height: 132).d1Surface(radius: 14)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore).accessibilityLabel(doll.name)
            .accessibilityValue(doll.isPlaced ? "지금 방에 있어요" : "보관 중")
    }
}

#Preview { DollListView().environment(AppState()).modelContainer(.preview) }

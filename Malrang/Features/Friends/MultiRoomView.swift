import SwiftData
import SwiftUI

/// SharePlay로 함께 보는 방. 방 주인의 방이 모두에게 보이고, 누가 인형을 옮기면 모두의 화면에서 같이 움직인다.
struct MultiRoomView: View {
    @Environment(MultiRoom.self) private var multiRoom
    @Query(sort: \RoomItem.createdAt) private var myItems: [RoomItem]
    @Query(sort: \Doll.createdAt) private var myDolls: [Doll]
    @State private var selectedDollID: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if multiRoom.items.isEmpty {
                    ProgressView("방 주인의 방을 불러오는 중")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    RoomSceneView(
                        items: multiRoom.items,
                        dolls: multiRoom.dolls,
                        mode: .home,
                        touch: multiRoom.lastTouch,
                        onTapDoll: { id in selectedDollID = id },
                        onMoveDoll: { id, position in multiRoom.moveDoll(id, to: position) }
                    )
                    .overlay(alignment: .top) {
                        Text("인형을 탭해 만지고, 길게 눌러 옮기면 모두에게 보여요")
                            .font(.footnote)
                            .foregroundStyle(Color.app.inkSecondary)
                            .padding(.top, Spacing.xs)
                    }
                }
            }
            .background(Color.app.background)
            .safeAreaInset(edge: .bottom) {
                Label("\(multiRoom.participantCount)명이 함께 있어요", systemImage: "shareplay")
                    .font(.footnote.bold())
                    .foregroundStyle(Color.app.ink)
                    .padding(.horizontal, Spacing.m)
                    .frame(minHeight: 44)
                    .background(Color.app.pastelMint, in: Capsule())
                    .padding(.bottom, Spacing.m)
            }
            .navigationTitle(multiRoom.isHost ? "내 방 (멀티 룸)" : "친구의 방 (멀티 룸)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(multiRoom.isHost ? "끝내기" : "나가기", role: .destructive) { multiRoom.leave() }
            }
            .sheet(isPresented: Binding(get: { selectedDollID != nil }, set: { if !$0 { selectedDollID = nil } })) {
                if let selectedDollID {
                    SharedDollSheet(dollID: selectedDollID)
                        .presentationDetents([.medium, .large])
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: multiRoom.lastTouch)
            .onAppear {
                if multiRoom.isHost {
                    multiRoom.publish(items: myItems.map(\.state), dolls: myDolls.filter(\.isPlaced).map(\.state))
                }
            }
            .onChange(of: multiRoom.dolls) {
                // 친구가 옮긴 내 인형 위치를 내 방에도 저장한다.
                guard multiRoom.isHost else { return }
                for state in multiRoom.dolls {
                    guard let doll = myDolls.first(where: { $0.id == state.id }) else { continue }
                    doll.position = state.position
                    doll.dance = state.dance
                }
            }
        }
    }
}

/// 멀티 룸에서 인형을 만지거나 춤을 바꾸면 모두의 화면에 같이 보인다.
private struct SharedDollSheet: View {
    let dollID: UUID
    @Environment(MultiRoom.self) private var multiRoom

    var body: some View {
        if let doll = multiRoom.dolls.first(where: { $0.id == dollID }) {
            NavigationStack {
                VStack(spacing: Spacing.s) {
                    SquishyView(doll: doll) { multiRoom.touchDoll(dollID) }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            Chip(title: "춤 멈추기", isSelected: doll.dance == nil) { multiRoom.setDance(nil, for: dollID) }
                            ForEach(DanceMove.allCases, id: \.self) { move in
                                Chip(title: move.label, isSelected: doll.dance == move) { multiRoom.setDance(move, for: dollID) }
                            }
                        }
                        .padding(.horizontal, Spacing.m)
                    }
                    .padding(.bottom, Spacing.m)
                }
                .background(Color.app.background)
            }
        }
    }
}

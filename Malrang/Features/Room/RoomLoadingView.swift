import SwiftUI

/// Only the status UI is an overlay. The room, doll, header and tabs are live views.
struct RoomLoadingView: View {
    let entrance: RoomEntrance
    @Environment(\.scenePhase) private var scenePhase
    private let ink = Color(uiColor: Palette.uiColor("#614A40"))

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: scenePhase != .active)) { _ in
            let time = entrance.time
            GeometryReader { geometry in
                let scale = min(geometry.size.width / 390, geometry.size.height / 844)
                ZStack(alignment: .topLeading) {
                    message("솜뭉치를 깨우고 있어요", node: "6439")
                    message("이불을 폭신하게 펴는 중…", node: "6444")
                    message("포근한 방 완성!", node: "6445")
                    Capsule().fill(.white.opacity(0.75)).frame(width: 140, height: 6)
                        .overlay(alignment: .leading) {
                            Capsule().fill(Color(uiColor: Palette.uiColor("#007499")))
                                .frame(width: entrance.timeline.value("6442", "width", at: time), height: 6)
                        }
                        .modifier(RoomEntranceMotion(entrance: entrance, node: "6440"))
                        .offset(x: 125, y: 520)
                    Text("잠시만 기다려 주세요").pretendard(.medium, 12)
                        .foregroundStyle(ink.opacity(0.55)).frame(width: 390)
                        .modifier(RoomEntranceMotion(entrance: entrance, node: "6443"))
                        .offset(y: 540)
                }
                .frame(width: 390, height: 844, alignment: .topLeading)
                .scaleEffect(scale)
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(time < 0.85 ? "솜뭉치를 깨우고 있어요" : time < 1.65 ? "이불을 폭신하게 펴는 중" : "포근한 방 완성")
            .accessibilityIdentifier("room-loading")
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
    }

    private func message(_ text: String, node: String) -> some View {
        Text(text).pretendard(.semiBold, 16).foregroundStyle(ink)
            .frame(width: 390)
            .modifier(RoomEntranceMotion(entrance: entrance, node: node))
            .offset(y: 478)
    }
}

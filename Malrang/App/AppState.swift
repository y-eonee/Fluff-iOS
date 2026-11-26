import Foundation

enum AppTab {
    case dolls, home, mypage
}

/// 탭 사이를 오가는 흐름(인형 목록에서 "방에 두기" → 홈 배치 모드)에 쓰는 앱 상태
@Observable
final class AppState {
    var tab = AppTab.home
    var dollToPlace: Doll?
    var isShowingAR = false
    var roomToolsOpen = false
    let roomEntrance = RoomEntrance(.home)

    func toggleRoomTools() {
        tab = .home
        roomToolsOpen.toggle()
    }

    var newlyCreatedDollID: UUID?

    func place(_ doll: Doll, newlyCreated: Bool = false) {
        newlyCreatedDollID = newlyCreated ? doll.id : nil
        dollToPlace = doll
        tab = .home
    }
}

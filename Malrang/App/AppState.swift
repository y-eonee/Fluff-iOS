import Foundation

enum AppTab {
    case dolls, home, friends
}

/// 탭 사이를 오가는 흐름(인형 목록에서 "방에 두기" → 홈 배치 모드)에 쓰는 앱 상태
@Observable
final class AppState {
    var tab = AppTab.home
    var dollToPlace: Doll?
    var isShowingAR = false

    func place(_ doll: Doll) {
        dollToPlace = doll
        tab = .home
    }
}

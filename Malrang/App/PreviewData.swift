import SwiftData
import SwiftUI

extension ModelContainer {
    /// 프리뷰용 메모리 저장소: 기본 방 + 침대 위 인형 하나
    static var preview: ModelContainer {
        let container = try! ModelContainer(for: Doll.self, RoomItem.self, DecorPhoto.self,
                                            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        RoomItem.starterRoom.forEach(container.mainContext.insert)
        let doll = Doll.sample
        doll.isPlaced = true
        doll.position = [-0.6, 0.3, -0.45]
        container.mainContext.insert(doll)
        return container
    }
}

extension Doll {
    static var sample: Doll {
        Doll(name: "귀염둥이", shape: .pillow, filling: .jelly, imageData: MockFriendAPI.sampleDollImage(symbol: "cat.fill"))
    }
}

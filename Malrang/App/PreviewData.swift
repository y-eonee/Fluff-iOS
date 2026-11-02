import SwiftData
import SwiftUI

extension ModelContainer {
    /// 프리뷰용 메모리 저장소: 기본 방 + 침대 위 인형 하나
    @MainActor static var preview: ModelContainer {
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
    @MainActor static var sample: Doll {
        let image = ImageRenderer(content: CottonArtwork(shape: .cat).frame(width: 240, height: 253)).uiImage
        let doll = Doll(name: "귀염둥이", shape: .cat, filling: .jelly, imageData: image?.pngData() ?? Data())
        doll.presetConfiguration = PresetConfiguration()
        return doll
    }
}

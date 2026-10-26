import Foundation

@MainActor
enum RenderMemory {
    /// Live scenes keep their own resources. Only rebuildable, unused cache references are released.
    static func clearCaches() {
        PresetDollModel.clearCache()
        PresetArmMesh.clearCache()
        PresetTextile.clearCache()
        PresetBlush.clearCache()
        SceneFactory.clearCache()
        CozyFurniture.clearCache()
        CozyRoomLighting.clearCache()
        DollThumbnail.clearCache()
    }
}

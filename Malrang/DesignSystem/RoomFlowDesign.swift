import SwiftUI

/// Source paints shared by 1727:23399 (radio) and 1727:23773 (room editing).
enum RoomFlowDesign {
    static let selected = RepresentativeGradient(
        stops: [.init(color: Color(.sRGB, red: 0.9974356294, green: 0.9974356294, blue: 0.9974356294), location: 0),
                .init(color: Color(.sRGB, red: 0.5414475799, green: 0.7707237601, blue: 1), location: 0.9697805643)],
        transform: [[0.1670713872, 0.4585354924, 0.1354432404], [-0.4630636573, 0.1051009744, 0.7817240357]], opacity: 1)
    static let action = LinearGradient(colors: [Color(uiColor: Palette.uiColor("#1C1A1A")), Color(uiColor: Palette.uiColor("#303133"))], startPoint: .top, endPoint: .bottom)
}
private struct RoomFlowDesignKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var roomFlowDesign: Bool {
        get { self[RoomFlowDesignKey.self] }
        set { self[RoomFlowDesignKey.self] = newValue }
    }
}

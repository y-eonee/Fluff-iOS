import SwiftUI

/// Pick once per visit, so changing study activity or updating the timer never flashes the background.
enum FocusPreviewTheme: String, CaseIterable {
    case yellow, aqua, rose, sage
    var starburst: String { "focus_starburst_\(rawValue)" }
    var background: Color { Color("focus_preview_\(rawValue)") }
    var border: Color { Color("focus_border_\(rawValue)") }
}

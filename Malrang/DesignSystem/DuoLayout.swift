import SwiftUI

extension EnvironmentValues {
    /// 상태 표시가 옆에 놓여 위쪽 안전 영역이 없는 화면(iPhone Duo, 가로 모드)에서 켜진다.
    @Entry var hasNoTopInset = false
}

extension View {
    /// 펼친 화면에서는 시트를 오른쪽에 띄운다.
    @ViewBuilder func trailingSheetPlacement() -> some View {
        if #available(iOS 27.0, *) { presentationPlacement(.trailing) } else { self }
    }
}

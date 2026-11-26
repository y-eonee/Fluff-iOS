import SwiftUI

/// 펼친 iPhone Duo처럼 가로로 넓으면 접히는 선을 기준으로 좌우 절반, 아니면 위아래로 쌓는다.
/// `wide` 값에 따라 각 화면이 미리보기를 어느 쪽에 둘지 정한다.
struct SplitStack<Primary: View, Secondary: View>: View {
    @ViewBuilder let primary: (_ wide: Bool) -> Primary
    @ViewBuilder let secondary: (_ wide: Bool) -> Secondary

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > max(600, geometry.size.height)
            // 한쪽에만 있는 안전 영역을 반영해 화면의 가운데에서 나눈다.
            let half = (geometry.size.width + geometry.safeAreaInsets.trailing - geometry.safeAreaInsets.leading) / 2
            let layout = wide ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
            layout {
                primary(wide).frame(width: wide ? half : nil).frame(maxHeight: wide ? .infinity : nil)
                secondary(wide).frame(maxWidth: .infinity)
            }.frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
    }
}

#Preview {
    SplitStack { _ in Color.rep4.c11 } secondary: { _ in Color.rep4.c01 }
}

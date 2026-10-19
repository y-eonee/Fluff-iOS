import SwiftUI

/// 원본 일러스트의 입체 면을 렌더링한 목록용 이미지.
struct FurnitureThumbnail: View {
    let kind: FurnitureKind
    @AppStorage("designVariant") private var variant = DesignVariant.a

    var body: some View {
        Image("\(variant == .b ? "b_" : "")furniture_\(kind.rawValue)")
            .resizable()
            .scaledToFit()
            .frame(height: Spacing.xl * 2)
            .background {
                if variant == .b && kind.category == .rug {
                    RoundedRectangle(cornerRadius: Radius.small).fill(Color.b.paper)
                }
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    FurnitureThumbnail(kind: .bed)
}

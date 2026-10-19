import SwiftUI

/// 원본 일러스트의 입체 면을 렌더링한 목록용 이미지.
struct FurnitureThumbnail: View {
    let kind: FurnitureKind

    var body: some View {
        Image("furniture_\(kind.rawValue)")
            .resizable()
            .scaledToFit()
            .frame(height: Spacing.xl * 2)
            .accessibilityHidden(true)
    }
}

#Preview {
    FurnitureThumbnail(kind: .bed)
}

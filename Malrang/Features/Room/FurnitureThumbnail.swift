import SwiftUI

/// 방 안의 CozyFurniture와 같은 모델을 렌더링한 목록용 이미지.
struct FurnitureThumbnail: View {
    let kind: FurnitureKind

    var body: some View {
        Image("furniture_\(kind.rawValue)")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            .accessibilityHidden(true)
    }
}

#Preview {
    FurnitureThumbnail(kind: .bed)
}

import SwiftUI

/// 가구, 벽지, 바닥재에 원하는 색을 칠하는 컬러 피커. 시트 안에 바로 펼쳐지고, 고르면 사진은 빠지고 색이 칠해진다.
/// SwiftUI의 ColorPicker는 작은 동그라미를 눌러야 열려서, 시스템 컬러 피커를 그대로 감싼다.
struct ItemColorPicker: UIViewControllerRepresentable {
    let item: RoomItem
    var rightWall = false
    private var selectedColor: UIColor {
        Palette.uiColor((rightWall ? item.rightWallColorName : item.colorName) ?? (rightWall ? CozyRoomPalette.ivory : CozyFurniture.defaultColor(for: item.kind)))
    }

    func makeCoordinator() -> Coordinator { Coordinator(item: item, rightWall: rightWall) }

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let controller = UIColorPickerViewController()
        controller.supportsAlpha = false
        controller.selectedColor = selectedColor
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: UIColorPickerViewController, context: Context) {
        context.coordinator.item = item
        context.coordinator.rightWall = rightWall
        let color = selectedColor
        if !controller.selectedColor.isEqual(color) {
            controller.selectedColor = color
        }
    }

    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        var item: RoomItem
        var rightWall: Bool

        init(item: RoomItem, rightWall: Bool) { self.item = item; self.rightWall = rightWall }

        func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
            if rightWall { item.rightWallColorName = Palette.hex(Color(uiColor: color)) }
            else { item.colorName = Palette.hex(Color(uiColor: color)); item.photoData = nil }
        }
    }
}

#Preview {
    ItemColorPicker(item: RoomItem(kind: .bed))
}

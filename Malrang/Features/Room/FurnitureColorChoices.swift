import SwiftUI

/// Swatches represent the furniture paint, while all controls use the UI tokens.
struct FurnitureColorChoices: View {
    @Bindable var item: RoomItem
    var onPhoto: (() -> Void)? = nil
    @State private var showingPicker = false
    private let colors: [(String?, String)] = [
        (nil, "원래 색상"), ("#FBF5EE", "아이보리"), ("#8FB8AE", "세이지"), ("#E3EEEA", "민트"),
        ("#FFEFD6", "버터"), ("#F6D5BE", "피치"), ("#C3B7E0", "라벤더")
    ]
    private let swatches = ["original", "ivory", "sage", "mint", "butter", "peach", "lavender"]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 4) {
                ForEach(colors.indices, id: \.self) { index in
                    let (hex, defaultLabel) = colors[index]
                    let isSurface = item.kind == .wall || item.kind == .floor
                    let label = index == 0 && isSurface ? "원래 벽지" : defaultLabel
                    let selected = item.photoData == nil && item.colorName == hex
                    Button {
                        item.colorName = hex; item.photoData = nil
                    } label: {
                        VStack(spacing: 3) {
                            Group {
                                if index == 0 && isSurface {
                                    Image("rep4_swatch_wall_original").resizable()
                                } else if index > 0 || [.desk, .shelf, .frame].contains(item.kind) {
                                    Image("rep4_swatch_" + swatches[index]).resizable()
                                } else {
                                    Circle().fill(Color(uiColor: Palette.uiColor(CozyFurniture.defaultColor(for: item.kind))))
                                }
                            }.frame(width: 30, height: 30)
                            Text(label).pretendard(.regular, 12)
                        }.padding(.top, 6).frame(maxWidth: .infinity).frame(height: 60, alignment: .top)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel(label).accessibilityAddTraits(selected ? .isSelected : [])
                }
                Button { showingPicker = true } label: {
                    VStack(spacing: 3) {
                        Image("rep4_swatch_custom").resizable().frame(width: 28, height: 28).frame(width: 30, height: 30)
                        Text("직접").pretendard(.regular, 12)
                    }.padding(.top, 6).frame(maxWidth: .infinity).frame(height: 60, alignment: .top)
                }.buttonStyle(.plain).accessibilityLabel("직접 색 고르기")
            }
            HStack(spacing: 10) {
                if let onPhoto { Button("사진으로 꾸미기", action: onPhoto).buttonStyle(FocusCompactButton()) }
            }
            if item.kind == .wall {
                ColorPicker("창틀 색상", selection: Binding(
                    get: { Color(uiColor: Palette.uiColor(item.windowFrameColor ?? CozyRoomPalette.wood)) },
                    set: { item.windowFrameColor = Palette.hex($0) }
                ), supportsOpacity: false).pretendard(.bold, 17).frame(minHeight: 44)
                Button("창틀 기본색으로") { item.windowFrameColor = nil }.buttonStyle(FocusCompactButton())
            }
        }.foregroundStyle(Color.mib.text.primary)
            .sheet(isPresented: $showingPicker) {
                ItemColorPicker(item: item).presentationDetents([.medium, .large]).presentationDragIndicator(.visible).presentationCornerRadius(22)
            }
    }
}

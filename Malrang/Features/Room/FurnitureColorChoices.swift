import SwiftUI

/// Swatches represent the furniture paint, while all controls use the UI tokens.
struct FurnitureColorChoices: View {
    @Bindable var item: RoomItem
    var onPhoto: (() -> Void)? = nil
    @State private var showingPicker = false
    private let colors: [(String?, String)] = [
        (nil, "기본색"), (CozyRoomPalette.mint, "민트"), (CozyRoomPalette.softMint, "연한 민트"), (CozyRoomPalette.cream, "크림"),
        (CozyRoomPalette.peach, "살구"), (CozyRoomPalette.blush, "분홍"), (CozyRoomPalette.wood, "우드"), (CozyRoomPalette.lavender, "라벤더")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(item.kind.label) 색상").pretendard(.bold, 17)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(colors.indices, id: \.self) { index in
                    let (hex, label) = colors[index]
                    let selected = item.photoData == nil && item.colorName == hex
                    Button {
                        item.colorName = hex; item.photoData = nil
                    } label: {
                        HStack(spacing: 4) {
                            Circle().fill(Color(uiColor: Palette.uiColor(hex ?? CozyFurniture.defaultColor(for: item.kind)))).frame(width: 24, height: 24)
                            if selected { D1Icon(name: "check") }
                        }.frame(maxWidth: .infinity).frame(height: 44)
                            .background(selected ? Color.mib.bg.mintSoft : Color.mib.bg.surface, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? Color.mib.line.selected : Color.mib.line.default, lineWidth: selected ? 2 : 1))
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel(label).accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            HStack(spacing: 10) {
                Button("직접 색 고르기") { showingPicker = true }.buttonStyle(FocusCompactButton())
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

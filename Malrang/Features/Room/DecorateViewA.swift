import SwiftData
import SwiftUI

extension DecorateView {
    var contentA: some View {
        VStack(spacing: 0) {
            header
            RoomSceneView(
                items: items.map(\.state), dolls: dolls.filter(\.isPlaced).map(\.state), mode: .decorate,
                onHoldDoll: { hold = $0 }, onMoveDoll: { id, position in dolls.first { $0.id == id }?.position = position },
                onMoveItem: move, onDoubleTapItem: { id in editingItem = items.first { $0.id == id } },
                selectedItemID: selectedID, onTapItem: { selectedID = $0 }, onFeel: { feelCount += 1 },
                isTransparent: true, illustrationTargetY: 0.7, isCozyRoom: true, onDollScreen: { dollPoint = $0 }, onFurnitureScreen: { furnitureBounds = $0 }, onWallScreen: { wallPolygon = $0 }
            )
            .renderedOnlyWhileVisible(background: .clear)
            .frame(minHeight: 220).frame(maxHeight: .infinity)
            .overlay { holdTooltip }
            .overlay {
                let target = selectedItem ?? (surfaceKind == .wall ? items.first { $0.kind == .wall } : nil)
                if let target, target.kind == .wall, wallPolygon.count == 4 {
                    WallSelectionOverlay(points: wallPolygon)
                } else if let target, let rect = furnitureBounds[target.id.uuidString] {
                    FurnitureSelectionOverlay(rect: rect, title: target.kind.label)
                }
            }
            .overlay(alignment: .top) {
                if isBlocked || isFull {
                    D1Bubble(text: isBlocked ? "돌릴 자리가 없어요. 주변 가구를 옮겨 주세요" : "더 놓을 자리가 없어요. 가구를 옮겨 주세요")
                        .padding(.horizontal, 22).allowsHitTesting(false)
                } else if selectedID == nil && hold == nil {
                    GeometryReader { geometry in
                        RoomInstructionBubble(text: category == .wallpaper ? "바꿀 벽을\n골라봐!" : category == .flooring ? "바닥을 바꿔봐!" : "한 손가락으로\n끌어서 옮겨봐!")
                            .padding(.leading, geometry.size.width * 108 / 390)
                            .padding(.top, 103.89)
                    }.allowsHitTesting(false)
                }
            }
            .sensoryFeedback(.warning, trigger: rotationFailCount)
            .overlay(alignment: .bottom) { historyRow.padding(.bottom, 6) }
            editorPanel
        }.foregroundStyle(Color.rep4.c03).background { RepresentativeGradientFill(definition: RepresentativeGradients.roomBackground).ignoresSafeArea() }

    }

    private var header: some View {
        Text("edit my room").notCliche(25.397, relativeTo: .title).tracking(-1.778)
            .frame(maxWidth: .infinity).frame(height: 44)
            .overlay(alignment: .leading) {
                Button(action: cancel) { Image("rep4_back").resizable().scaledToFit().frame(width: 32, height: 32).frame(width: 44, height: 44) }
                    .buttonStyle(.plain).offset(y: 2).accessibilityLabel("뒤로")
            }
            .overlay(alignment: .trailing) {
                Button {
                    do { try modelContext.save(); dismiss() } catch { saveFailed = true }
                } label: {
                    Image("rep4_edit_confirm").resizable().frame(width: 40.755, height: 40.755)
                }.buttonStyle(.plain).offset(y: 3.5).accessibilityLabel("꾸미기 완료")
            }.padding(.horizontal, 22).offset(y: 3)
    }

    private var historyRow: some View {
        HStack(alignment: .top, spacing: 3.77) {
            RoomHistoryButton(redo: false, action: undo).disabled(undoStack.isEmpty).opacity(undoStack.isEmpty ? 0.4 : 1)
            RoomHistoryButton(redo: true, action: redo).disabled(redoStack.isEmpty).opacity(redoStack.isEmpty ? 0.4 : 1)
            Spacer()
            Button(action: reset) {
                HStack(spacing: 2) {
                    Image("rep4_room_reset").resizable().scaledToFit().frame(width: 19, height: 12.8)
                    Text("초기화").pretendard(.regular, 14, tracking: -0.42)
                }.frame(width: 74, height: 38).background(Color.rep4.c01, in: Capsule())
                    .frame(height: 44, alignment: .top).contentShape(Rectangle())
            }.buttonStyle(.plain)
                .disabled(!hasChanges).opacity(hasChanges ? 1 : 0.4)
        }.padding(.leading, 23.23).padding(.trailing, 20)
    }

    private var categoryTabs: some View {
        HStack(spacing: 0) {
            ForEach([FurnitureCategory.furniture, .wallpaper, .flooring, .decor], id: \.self) { tab in
                Button { selectCategory(tab) } label: {
                    Text(tab == .decor ? "소품" : tab.label).pretendard(category == tab ? .medium : .regular, 14, tracking: -0.42)
                        .foregroundStyle(Color.rep4.c03.opacity(category == tab ? 1 : 0.62))
                        .frame(maxWidth: .infinity).frame(height: category == .wallpaper ? 41 : 37)
                        .overlay(alignment: .bottom) { Rectangle().fill(category == tab ? Color.rep4.c03 : Color.rep4.c07).frame(height: category == tab ? 1 : 0.5) }
                }.buttonStyle(.plain).accessibilityAddTraits(category == tab ? .isSelected : [])
            }
        }
    }

    private var editorPanel: some View {
        VStack(spacing: category == .wallpaper ? 13 : 17) {
            if let item = selectedItem { selectedPanel(item).padding(.horizontal, 6) }
            else {
                categoryTabs.padding(.horizontal, 6)
                catalogPanel.frame(height: 200, alignment: .top)
            }
        }.padding(.horizontal, 18).padding(.top, selectedItem == nil ? 2 : 0).padding(.bottom, selectedItem == nil ? 10 : 16)
            .frame(maxWidth: .infinity, minHeight: 266, alignment: .top)
            .background { Color.rep4.c01.clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14)).ignoresSafeArea(edges: .bottom) }
    }

    private func selectedPanel(_ item: RoomItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(item.kind.label) 편집").pretendard(.bold, 16).frame(maxWidth: .infinity).frame(height: item.kind.category == .decor ? 52 : 42)
                .overlay(alignment: .leading) {
                    Button { selectedID = nil } label: {
                        HStack(spacing: 2) {
                            Image("rep4_list_back").resizable().frame(width: 20, height: 20)
                            Text("가구 목록").pretendard(.medium, 14)
                        }.frame(minHeight: 44)
                    }.buttonStyle(.plain).offset(x: -4)
                }
            Text("가구를 끌어서 위치를 옮길 수 있어요").pretendard(.regular, 13, tracking: -0.65)
                .foregroundStyle(Color(uiColor: Palette.uiColor("#707070")))
                .frame(height: 18.85).padding(.top, item.kind.category == .decor ? 14 : 19)
            HStack(spacing: 6.1) {
                if item.kind.isMovable {
                    tool("회전", icon: "rotate") { rotate(item) }
                    tool("좌우반전", icon: "flip") { item.isMirrored.toggle() }
                }
                tool("꾸미기", icon: "paint") { editingItem = item }
                if item.kind.isMovable { tool("삭제", icon: "trash", danger: true) { remove(item) } }
            }.padding(.trailing, 3.69)
                .overlay {
                    if item.kind.isMovable {
                        GeometryReader { geometry in
                            Rectangle().fill(Color.rep4.c07).frame(width: 1, height: 48)
                                .position(x: (geometry.size.width - 3.69) * 254.76 / 338.31, y: 37)
                        }.allowsHitTesting(false)
                    }
                }.padding(.top, 13.15)
        }
    }

    private func tool(_ title: String, icon: String, danger: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon == "rotate" ? "arrow.clockwise" : icon == "flip" ? "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right" : icon == "paint" ? "pencil" : "trash")
                    .font(.system(size: 18, weight: .regular)).offset(y: -1)
                    .foregroundStyle(danger ? Color.mib.semantic.error : Color.rep4.c03).frame(width: 44, height: 44)
                    .background(Color.rep4.c11, in: Circle())
                Text(title).pretendard(.medium, 13).foregroundStyle(danger ? Color.mib.semantic.error : Color.mib.text.primary)
            }.frame(maxWidth: .infinity).frame(height: 72).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private var catalogPanel: some View {
        ScrollView {
            if let kind = surfaceKind, let surface = items.first(where: { $0.kind == kind }) {
                FurnitureFinishEditor(item: surface, initialPhotoMode: surfacePhotoMode)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(FurnitureKind.allCases.filter { $0.category == category || (category == .decor && $0.category == .rug) }, id: \.self) { kind in
                        Button { add(kind) } label: {
                            VStack(spacing: 4) {
                                FurnitureThumbnail(kind: kind).frame(height: 51.16)
                                Text(kind.label).pretendard(.medium, 13).lineLimit(1)
                                    .foregroundStyle(Color.rep4.c03.opacity(catalogSelection == kind ? 1 : 0.78))
                            }.padding(6).frame(maxWidth: .infinity).frame(height: 83.16)
                                .modifier(RepresentativeSelectionSurface(selected: catalogSelection == kind, radius: 13.23, neutral: Color.rep4.c05)).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityLabel("\(kind.label) 추가")
                    }
                }.padding(.horizontal, 6).padding(.top, 4)
            }
        }.scrollIndicators(.hidden).id(category)
    }

    private func cancel() {
        if hasChanges { isConfirmingDiscard = true } else { dismiss() }
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(items.map(\.state)); selectedID = nil; apply(previous)
    }
    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(items.map(\.state)); selectedID = nil; apply(next)
    }
    func reset() {
        restoreOriginal(); selectedID = nil; undoStack = []; redoStack = []
    }
}

private struct RoomInstructionBubble: View {
    let text: String
    var body: some View {
        VStack(spacing: -1) {
            Text(text).pretendard(.medium, 13, tracking: -0.39)
                .multilineTextAlignment(.center).lineSpacing(2)
                .frame(height: text.contains("\n") ? 35.1 : 17.55)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
            Image("rep4_room_bubble_tail").resizable().frame(width: 14, height: 9)
                .rotationEffect(.degrees(180))
        }.fixedSize()
    }
}

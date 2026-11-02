import SwiftData
import SwiftUI

extension DecorateView {
    var contentA: some View {
        VStack(spacing: 8) {
            header
            RoomSceneView(
                items: items.map(\.state), dolls: dolls.filter(\.isPlaced).map(\.state), mode: .decorate,
                onHoldDoll: { hold = $0 }, onMoveDoll: { id, position in dolls.first { $0.id == id }?.position = position },
                onMoveItem: move, onDoubleTapItem: { id in editingItem = items.first { $0.id == id } },
                selectedItemID: selectedID, onTapItem: { selectedID = $0 }, onFeel: { feelCount += 1 },
                isTransparent: true, illustrationTargetY: 0.7, isCozyRoom: true, onDollScreen: { dollPoint = $0 }
            )
            .renderedOnlyWhileVisible(background: .clear)
            .frame(minHeight: 180).frame(maxHeight: .infinity)
            .overlay { holdTooltip }
            .overlay(alignment: .top) {
                if isBlocked || isFull {
                    D1Bubble(text: isBlocked ? "돌릴 자리가 없어요. 주변 가구를 옮겨 주세요" : "더 놓을 자리가 없어요. 가구를 옮겨 주세요")
                        .padding(.horizontal, 22).allowsHitTesting(false)
                } else if selectedID == nil && hold == nil {
                    D1Bubble(text: "한 손가락으로 끌어서 옮겨봐!").frame(width: 246).allowsHitTesting(false)
                }
            }
            .sensoryFeedback(.warning, trigger: rotationFailCount)
            historyRow
            categoryTabs
            editorPanel
        }.foregroundStyle(Color.mib.text.primary)
    }

    private var header: some View {
        Text("edit my room").notCliche(28, relativeTo: .title).tracking(-1.12)
            .frame(maxWidth: .infinity).frame(height: 44)
            .overlay(alignment: .leading) {
                Button(action: cancel) { D1Icon(name: "back").frame(width: 44, height: 44).contentShape(Rectangle()) }
                    .buttonStyle(.plain).accessibilityLabel("뒤로")
            }.padding(.horizontal, 20)
    }

    private var historyRow: some View {
        HStack(spacing: 10) {
            D1IconButton(icon: "undo", label: "되돌리기", action: undo).disabled(undoStack.isEmpty).opacity(undoStack.isEmpty ? 0.4 : 1)
            D1IconButton(icon: "redo", label: "다시하기", action: redo).disabled(redoStack.isEmpty).opacity(redoStack.isEmpty ? 0.4 : 1)
            Spacer()
            Button("초기화", action: reset).buttonStyle(FocusCompactButton()).frame(width: 82)
                .disabled(!hasChanges).opacity(hasChanges ? 1 : 0.4)
        }.padding(.horizontal, 22)
    }

    private var categoryTabs: some View {
        HStack(spacing: 6) {
            ForEach([FurnitureCategory.furniture, .wallpaper, .flooring, .decor], id: \.self) { tab in
                D1Choice(title: tab == .decor ? "소품" : tab.label, selected: category == tab, fillsWidth: true) { selectCategory(tab) }
                    .frame(maxWidth: .infinity)
            }
        }.padding(.horizontal, 22)
    }

    private var editorPanel: some View {
        VStack(spacing: 16) {
            Group {
                if let item = selectedItem { selectedPanel(item) }
                else { catalogPanel }
            }.frame(height: 188, alignment: .top)
            HStack(spacing: 10) {
                Button("취소", action: cancel).buttonStyle(D1SecondaryStyle())
                Button("완료") {
                    do { try modelContext.save(); dismiss() } catch { saveFailed = true }
                }.buttonStyle(D1PrimaryStyle())
            }
        }.padding(.horizontal, 22).padding(.top, 16).padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .background(Color.mib.bg.surface, in: UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22))
    }

    private func selectedPanel(_ item: RoomItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("선택한 가구").pretendard(.medium, 13).foregroundStyle(Color.mib.text.secondary)
                    Text(item.kind.label).pretendard(.bold, 21)
                }
                Spacer()
                Button("선택 해제") { selectedID = nil }.buttonStyle(FocusCompactButton()).frame(width: 112)
            }
            HStack(spacing: 8) {
                if item.kind.isMovable {
                    tool("회전", icon: "rotate") { rotate(item) }
                    tool("좌우반전", icon: "flip") { item.isMirrored.toggle() }
                }
                tool("꾸미기", icon: "paint") { editingItem = item }
                if item.kind.isMovable { tool("삭제", icon: "trash", danger: true) { remove(item) } }
            }
            Text("가구를 끌어서 위치를 옮길 수 있어요").pretendard(.medium, 13).foregroundStyle(Color.mib.text.secondary)
        }
    }

    private func tool(_ title: String, icon: String, danger: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                D1Icon(name: icon).frame(width: 44, height: 44).d1Surface(radius: 22)
                    .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.mib.line.selected, lineWidth: 1.4))
                Text(title).pretendard(.medium, 13).foregroundStyle(danger ? Color.mib.semantic.error : Color.mib.text.primary)
            }.frame(maxWidth: .infinity).frame(height: 72).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private var catalogPanel: some View {
        ScrollView {
            if let kind = surfaceKind, let surface = items.first(where: { $0.kind == kind }) {
                FurnitureColorChoices(item: surface, onPhoto: { photoItem = surface })
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(FurnitureKind.allCases.filter { $0.category == category || (category == .decor && $0.category == .rug) }, id: \.self) { kind in
                        Button { add(kind) } label: {
                            VStack(spacing: 4) {
                                FurnitureThumbnail(kind: kind).frame(height: 56)
                                Text(kind.label).pretendard(.medium, 13).lineLimit(1)
                            }.padding(6).frame(maxWidth: .infinity).frame(height: 88).d1Surface(radius: 14).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityLabel("\(kind.label) 추가")
                    }
                }
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

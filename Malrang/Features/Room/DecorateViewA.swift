import SwiftData
import SwiftUI

/// 시안 A(피그마 1안) 방 꾸미기: 방 아래에 되돌리기·초기화 줄과 인덱스 탭이 붙은 편집 시트가 놓인다.
extension DecorateView {
    var contentA: some View {
        VStack(spacing: Spacing.xs) {
            RoomSceneView(
                items: items.map(\.state),
                dolls: dolls.filter(\.isPlaced).map(\.state),
                mode: .decorate,
                onHoldDoll: { hold = $0 },
                onMoveDoll: { id, position in dolls.first { $0.id == id }?.position = position },
                onMoveItem: move,
                onDoubleTapItem: { id in editingItem = items.first { $0.id == id } },
                selectedItemID: selectedID,
                onTapItem: { selectedID = $0 },
                onFeel: { feelCount += 1 },
                isTransparent: true,
                hidesRoom: showsRoomArt,
                illustrationTargetY: 0.7,
                onDollScreen: { dollPoint = $0 }
            )
            .renderedOnlyWhileVisible(background: .clear)
            // 방 바닥 앞쪽 모서리가 장면 아래에서 잘리지 않게 아래로 넓힌다. 아래 줄은 그 위에 놓인다.
            .padding(.bottom, -48)
            .overlay { holdTooltip }
            .overlay { tooltipsA }
            .overlay(alignment: .top) {
                if isBlocked || isFull {
                    Text(isBlocked ? "돌릴 자리가 없어요. 주변 가구를 옮겨 주세요" : "더 놓을 자리가 없어요. 가구를 옮겨 공간을 만들어 주세요")
                        .pretendard(.bold, 13, tracking: -0.39)
                        .foregroundStyle(Color.a.brown)
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, Spacing.xs)
                        .sketchBox(fill: .white, radius: 16, line: 1.1)
                        .padding(.top, Spacing.xs)
                }
            }
            .sensoryFeedback(.warning, trigger: rotationFailCount)
            historyRow
            sheetA
        }
    }

    /// 인형 위에 뜨는 안내 말풍선. 3D 장면 위에서 인형을 따라다닌다.
    var tooltipsA: some View {
        GeometryReader { proxy in
            if !isBlocked && !isFull && selectedID == nil, let point = dollPoint {
                bubbleA {
                    Text("한 손가락으로\n끌어서 옮겨봐!")
                        .pretendard(.bold, 13, tracking: -0.39)
                        .lineSpacing(3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.a.brown)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
                .allowsHitTesting(false)
                .position(x: min(max(point.x, 60), proxy.size.width - 60), y: point.y - 32)
            }
        }
    }

    /// 손그림 말풍선: 흰 상자와 아래를 가리키는 꼬리
    private func bubbleA(@ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: -1.2) {
            content()
                .sketchBox(fill: .white, radius: 16, line: 1.1)
            Image("a_bubble_tail")
                .rotationEffect(.degrees(180))
                .zIndex(1)
        }
        .fixedSize()
    }

    /// 시안 A의 방 일러스트. 피그마 좌표(390x844)를 화면 크기에 맞춰 그대로 둔다.
    var roomArtA: some View {
        GeometryReader { proxy in
            ZStack {
                // 내보낸 그림에 종이 색 배경이 같이 들어 있어서, 모눈이 가려지지 않게 어두운 쪽만 남긴다.
                Image("a_room_edit")
                    .blendMode(.darken)
                    .position(x: 195, y: 422 - 136)
                Image("a_room_edit_group1")
                    .position(x: 43 + 304 / 2, y: 134 + 311.6 / 2)
                Image("a_room_edit_group2")
                    .blendMode(.darken)
                    .position(x: 245.2 + 86.6 / 2, y: 277.5 + 86.2 / 2)
            }
            .frame(width: 390, height: 844)
            .scaleEffect(proxy.size.width / 390, anchor: .topLeading)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    @ToolbarContentBuilder
    var toolbarA: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                if hasChanges { isConfirmingDiscard = true } else { dismiss() }
            } label: {
                Image("a_back").resizable().frame(width: 26, height: 26)
            }
            .accessibilityLabel("뒤로")
        }
        .sharedBackgroundVisibility(.hidden)
        ToolbarItem(placement: .principal) {
            Text("edit my room")
                .notCliche(28, relativeTo: .title)
                .tracking(-1.12)
                .foregroundStyle(Color.a.brown)
        }
    }

    private var historyRow: some View {
        HStack(spacing: Spacing.xs) {
            historyButton("a_undo", label: "되돌리기", isEnabled: !undoStack.isEmpty, action: undo)
            historyButton("a_redo", label: "다시하기", isEnabled: !redoStack.isEmpty, action: redo)
            Spacer()
            Button(action: reset) {
                Text("초기화")
                    .pretendard(.bold, 14, tracking: -0.42)
                    .foregroundStyle(Color.a.brown)
                    .padding(.horizontal, Spacing.m)
                    .frame(minHeight: 44)
                    .sketchBox(fill: Color.a.yellow, radius: 22, line: 1.1)
            }
            .buttonStyle(.plain)
            .disabled(!hasChanges)
            .opacity(hasChanges ? 1 : 0.4)
        }
        .padding(.horizontal, Spacing.l)
    }

    private func historyButton(_ asset: String, label: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(asset)
                .resizable()
                .frame(width: 20, height: 20)
                .frame(width: 44, height: 44)
                .sketchBox(radius: 22, line: 1.1)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }

    private func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(items.map(\.state))
        selectedID = nil
        apply(previous)
    }

    private func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(items.map(\.state))
        selectedID = nil
        apply(next)
    }

    /// 꾸미기를 시작하던 때의 방으로 돌린다.
    private func reset() {
        restoreOriginal()
        selectedID = nil
        undoStack = []
        redoStack = []
    }

    // MARK: 편집 시트

    private var sheetA: some View {
        VStack(spacing: 0) {
            indexTabs
            VStack(alignment: .leading, spacing: Spacing.s) {
                if let item = selectedItem { selectedPanel(item) } else { catalogPanel }
                Spacer(minLength: 0)
                HStack(spacing: Spacing.s) {
                    Button {
                        if hasChanges { isConfirmingDiscard = true } else { dismiss() }
                    } label: {
                        Text("취소")
                            .pretendard(.bold, 17, tracking: -0.51)
                            .foregroundStyle(Color.a.brown)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .sketchBox(radius: 27)
                    }
                    Button {
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        Text("완료")
                            .pretendard(.bold, 17, tracking: -0.51)
                            .foregroundStyle(Color.a.cream)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .sketchBox(fill: Color.a.brown, radius: 27)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.l)
            .frame(maxWidth: .infinity)
            .frame(height: surfaceKind == nil ? 312 : 470)
            .background {
                UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14, style: .continuous)
                    .fill(Color.a.card)
                    .overlay(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14, style: .continuous)
                        .stroke(Color.a.line, lineWidth: 1.1))
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .foregroundStyle(Color.a.brown)
    }

    private var indexTabs: some View {
        HStack(alignment: .bottom, spacing: Spacing.xxs) {
            ForEach(FurnitureCategory.allCases, id: \.self) { tab in
                let isSelected = category == tab
                Button {
                    category = tab
                } label: {
                    Text(tab.label)
                        .pretendard(.semiBold, 12, tracking: -0.36)
                        .foregroundStyle(isSelected ? Color.a.brown : Color.a.soft)
                        .frame(maxWidth: .infinity, minHeight: isSelected ? 30 : 26)
                        .background(tabColor(tab), in: UnevenRoundedRectangle(topLeadingRadius: 9, topTrailingRadius: 9, style: .continuous))
                        .overlay(UnevenRoundedRectangle(topLeadingRadius: 9, topTrailingRadius: 9, style: .continuous)
                            .stroke(Color.a.line, lineWidth: 1))
                        .frame(minHeight: 44, alignment: .bottom)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, -1)
    }

    private func tabColor(_ tab: FurnitureCategory) -> Color {
        switch tab {
        case .furniture: Color.a.card
        case .wallpaper: Color.a.pinkLight
        case .flooring: Color.a.mint
        case .rug: Color.a.blue
        case .decor: Color.a.yellow
        }
    }

    /// 가구를 고르면 보이는 편집 도구: 회전, 꾸미기, 삭제
    private func selectedPanel(_ item: RoomItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("선택한 가구")
                        .pretendard(.regular, 12, tracking: -0.24)
                        .foregroundStyle(Color.a.soft)
                    Text(item.kind.label)
                        .pretendard(.black, 26, tracking: -1.04)
                }
                Spacer()
                Button("선택 해제") { selectedID = nil }
                    .pretendard(.regular, 13, tracking: -0.26)
                    .foregroundStyle(Color.a.soft)
                    .frame(minHeight: 44)
            }
            HStack(spacing: Spacing.s) {
                if item.kind.isMovable && !item.kind.hangsOnWall {
                    toolCard("회전", asset: "a_tool_rotate") { rotate(item) }
                }
                toolCard("꾸미기", asset: "a_tool_paint") { editingItem = item }
                if item.kind.isMovable {
                    toolCard("삭제", asset: "a_tool_delete", isDanger: true) { remove(item) }
                }
            }
        }
    }

    private func toolCard(_ title: String, asset: String, isDanger: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(asset).resizable().frame(width: 24, height: 24)
                Text(title).pretendard(.bold, 13, tracking: -0.39)
            }
            .foregroundStyle(isDanger ? Color.a.danger : Color.a.brown)
            .frame(width: 76, height: 84)
            .background(isDanger ? Color.a.dangerFill : Color.a.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isDanger ? Color.a.dangerLine : Color.a.line, style: StrokeStyle(lineWidth: 1.1, dash: isDanger ? [4, 3] : [])))
        }
        .buttonStyle(.plain)
    }

    /// 더할 가구와 벽지·바닥재 색을 고른다.
    private var catalogPanel: some View {
        ScrollView {
            VStack(spacing: Spacing.s) {
                if let kind = surfaceKind, let surface = items.first(where: { $0.kind == kind }) {
                    ItemColorPicker(item: surface)
                        .frame(height: 300)
                    catalogCell("사진으로 꾸미기", symbol: "photo") { editingItem = surface }
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s), count: 3), spacing: Spacing.s) {
                        ForEach(FurnitureKind.allCases.filter { $0.category == category }, id: \.self) { kind in
                            catalogCell(kind.label, symbol: kind.symbol) { add(kind) }
                        }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func catalogCell(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: symbol).appFont(.title2)
                Text(title).pretendard(.bold, 13, tracking: -0.39)
            }
            .foregroundStyle(Color.a.brown)
            .frame(maxWidth: .infinity, minHeight: 84)
            .sketchBox(radius: 8, line: 1.1)
        }
        .buttonStyle(.plain)
    }
}

import SwiftUI
import SwiftData

extension DecorateView {
    var contentB: some View {
        VStack(spacing: Spacing.xs) {
            RoomSceneView(
                items: items.map(\.state), dolls: dolls.filter(\.isPlaced).map(\.state), mode: .decorate,
                onHoldDoll: { hold = $0 },
                onMoveDoll: { id, point in dolls.first { $0.id == id }?.position = point },
                onMoveItem: move,
                onDoubleTapItem: { id in editingItem = items.first { $0.id == id } },
                onTapBoard: { isShowingGuestbook = true },
                selectedItemID: selectedID, onTapItem: { selectedID = $0 },
                onFeel: { feelCount += 1 }, isTransparent: true, illustrationTargetY: 0.7,
                onDollScreen: { dollPoint = $0 }
            )
            .renderedOnlyWhileVisible(background: .clear)
            .overlay { holdTooltip }
            .overlay(alignment: .top) {
                if isBlocked || isFull {
                    HintCapsule(text: isBlocked ? "주변 가구를 옮겨 주세요" : "더 놓을 자리가 없어요")
                }
            }
            .sensoryFeedback(.warning, trigger: rotationFailCount)
            HStack(spacing: Spacing.xs) {
                bHistory("b_screen2_imgI", label: "되돌리기", enabled: !undoStack.isEmpty, action: undo)
                bHistory("b_screen2_imgI1", label: "다시하기", enabled: !redoStack.isEmpty, action: redo)
                Spacer()
                Button("초기화", action: reset)
                    .pretendard(.bold, 13).padding(.horizontal, Spacing.m).frame(minHeight: 44)
                    .background(.white.opacity(0.5), in: Capsule())
                    .overlay(Capsule().stroke(Color.b.line))
                    .disabled(!hasChanges)
            }.padding(.horizontal, Spacing.m)
            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: Spacing.xxs) {
                    ForEach(FurnitureCategory.allCases, id: \.self) { tab in
                        Button { selectCategory(tab) } label: {
                            Text(tab.label).pretendard(category == tab ? .bold : .medium, 13)
                                .foregroundStyle(category == tab ? Color.b.ink : Color.b.soft)
                                .frame(maxWidth: .infinity, minHeight: 32)
                                .background(category == tab ? .white : Color.b.inactive,
                                            in: UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))
                                .overlay(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12).stroke(Color.b.line))
                                .frame(minHeight: 44, alignment: .bottom)
                        }
                        .accessibilityAddTraits(category == tab ? .isSelected : [])
                    }
                }.padding(.horizontal, Spacing.xs)
                VStack(alignment: .leading, spacing: Spacing.m) {
                    if let selectedItem {
                        bSelected(selectedItem)
                    } else {
                        bCatalog
                    }
                    Spacer(minLength: 0)
                    HStack(spacing: Spacing.xs) {
                        Button {
                            if hasChanges { isConfirmingDiscard = true } else { dismiss() }
                        } label: { bConfirmLabel("취소", primary: false) }
                        Button { try? modelContext.save(); dismiss() } label: { bConfirmLabel("완료", primary: true) }
                    }
                }
                .padding(Spacing.m)
                .frame(height: surfaceKind == nil ? BStyle.sheetHeight : 420)
                .background(.white.opacity(0.94), in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
                .overlay(alignment: .top) {
                    UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28).stroke(Color.b.line).allowsHitTesting(false)
                }
            }
        }
        .buttonStyle(BGlossButtonStyle())
        .foregroundStyle(Color.b.ink)
    }

    @ToolbarContentBuilder var toolbarB: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { if hasChanges { isConfirmingDiscard = true } else { dismiss() } } label: {
                Image("b_screen2_imgI2").resizable().scaledToFit().frame(width: 22, height: 22)
                    .frame(width: 44, height: 44).background(.white.opacity(0.8), in: Circle())
                    .overlay(Circle().stroke(Color.b.line))
            }.buttonStyle(BGlossButtonStyle(radius: 22)).accessibilityLabel("뒤로")
        }.sharedBackgroundVisibility(.hidden)
        ToolbarItem(placement: .principal) {
            Text("edit my room").origin(BStyle.title, relativeTo: .title).foregroundStyle(Color.b.brown)
        }
    }

    private func bHistory(_ asset: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(asset).resizable().scaledToFit().frame(width: 18, height: 18)
                .frame(width: 44, height: 44).background(.white, in: Circle())
                .overlay(Circle().stroke(Color.b.line))
        }.disabled(!enabled).opacity(enabled ? 1 : 0.4).accessibilityLabel(label)
    }

    private func bConfirmLabel(_ title: String, primary: Bool) -> some View {
        Text(title).pretendard(.bold, 16).foregroundStyle(Color.b.brown)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(BButtonSurface(primary: primary))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(primary ? Color.clear : Color.b.line))
    }

    private func bSelected(_ item: RoomItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("선택한 가구").pretendard(.regular, 12).foregroundStyle(Color.b.soft)
                    Text(item.kind.bLabel).appFont(.title2, .bold)
                }
                Spacer()
                Button("선택 해제") { selectedID = nil }.pretendard(.regular, 13).foregroundStyle(Color.b.soft).frame(minHeight: 44)
            }
            HStack(spacing: Spacing.xs) {
                if item.kind.isMovable {
                    bTool("회전", asset: "b_screen2_imgVector1") { rotate(item) }
                    bTool("좌우반전", asset: "b_screen2_imgVector2") { item.isMirrored.toggle() }
                }
                bTool("꾸미기", asset: "b_screen2_imgVector3") { editingItem = item }
                if item.kind.isMovable {
                    bTool("삭제", asset: "b_screen2_imgVector4", danger: true) { remove(item) }
                }
            }
        }
    }

    private func bTool(_ title: String, asset: String, danger: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.s) {
                Image(asset).resizable().scaledToFit().frame(width: 22, height: 22)
                Text(title).pretendard(.bold, 13)
            }
            .foregroundStyle(danger ? Color.b.danger : Color.b.ink)
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.b.line, style: StrokeStyle(lineWidth: 1, dash: danger ? [3, 3] : [])))
        }
    }

    private var bCatalog: some View {
        ScrollView {
            if let kind = surfaceKind, let surface = items.first(where: { $0.kind == kind }) {
                ItemColorPicker(item: surface).frame(height: 260)
                Button("사진으로 꾸미기", systemImage: "photo") { editingItem = surface }
                    .pretendard(.bold, 13).frame(minHeight: 44)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s), count: 3), spacing: Spacing.s) {
                    ForEach(FurnitureKind.allCases.filter { $0.category == category }, id: \.self) { kind in
                        Button { add(kind) } label: {
                            VStack(spacing: Spacing.xxs) {
                                FurnitureThumbnail(kind: kind)
                                Text(kind.bLabel).pretendard(.bold, 12)
                            }
                            .frame(maxWidth: .infinity, minHeight: 96)
                            .background(.white, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.b.line))
                        }
                    }
                }
            }
        }.scrollIndicators(.hidden).id(category)
    }
}

extension FurnitureKind {
    var bLabel: String {
        switch self {
        case .bed: "원목 침대"
        case .desk: "원목 책상"
        case .shelf: "벽 선반"
        case .chair: "원형 스툴"
        case .sofa: "쿠션 소파"
        default: label
        }
    }
}

#Preview {
    NavigationStack { DecorateView().environment(MultiRoom()) }.modelContainer(.preview)
}

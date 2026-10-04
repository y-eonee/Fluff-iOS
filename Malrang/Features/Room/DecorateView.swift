import SwiftData
import SwiftUI

/// 마이 홈: 가구를 더하고 옮기고, 두 번 탭해 색이나 사진으로 꾸민다. 적용하기 전에는 되돌릴 수 있다.
struct DecorateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RoomItem.createdAt) private var items: [RoomItem]
    @Query(sort: \Doll.createdAt) private var dolls: [Doll]
    @State private var category = FurnitureCategory.furniture
    @State private var original: [RoomItemState]?
    @State private var editingItem: RoomItem?
    @State private var isConfirmingDiscard = false
    @State private var isFull = false

    private var hasChanges: Bool { original != nil && original != items.map(\.state) }

    var body: some View {
        VStack(spacing: 0) {
            RoomSceneView(
                items: items.map(\.state),
                dolls: dolls.filter(\.isPlaced).map(\.state),
                mode: .decorate,
                onMoveItem: move,
                onDoubleTapItem: { id in editingItem = items.first { $0.id == id } }
            )
            .overlay(alignment: .top) {
                Text(isFull ? "더 놓을 자리가 없어요. 가구를 옮겨 공간을 만들어 주세요" : "길게 눌러 옮기고, 두 번 탭해 꾸며요")
                    .font(.footnote)
                    .foregroundStyle(Color.app.inkSecondary)
                    .padding(.top, Spacing.xs)
            }
            panel
        }
        .background(Color.app.background)
        .navigationTitle("마이 홈")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("뒤로", systemImage: "chevron.left") {
                    if hasChanges { isConfirmingDiscard = true } else { dismiss() }
                }
            }
        }
        .confirmationDialog("꾸민 내용을 버릴까요?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
            Button("버리고 나가기", role: .destructive) {
                restoreOriginal()
                dismiss()
            }
        }
        .navigationDestination(item: $editingItem) { item in
            FurnitureCustomView(item: item)
        }
        .onAppear {
            if original == nil { original = items.map(\.state) }
        }
        .task(id: isFull) {
            try? await Task.sleep(for: .seconds(3))
            isFull = false
        }
    }

    private var panel: some View {
        VStack(spacing: Spacing.m) {
            HStack {
                ForEach(FurnitureCategory.allCases, id: \.self) { tab in
                    Button {
                        category = tab
                    } label: {
                        Text(tab.label)
                            .font(.body.weight(category == tab ? .bold : .regular))
                            .foregroundStyle(category == tab ? Color.app.ink : Color.app.inkSecondary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .overlay(alignment: .bottom) {
                                Capsule()
                                    .fill(category == tab ? Color.app.ink : .clear)
                                    .frame(height: 3)
                            }
                    }
                    .accessibilityAddTraits(category == tab ? .isSelected : [])
                }
            }
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s), count: 3), spacing: Spacing.s) {
                    switch category {
                    case .wallpaper, .flooring:
                        surfaceCells(for: category == .wallpaper ? .wall : .floor)
                    default:
                        ForEach(FurnitureKind.allCases.filter { $0.category == category }, id: \.self) { kind in
                            cell(kind.label) {
                                Image(systemName: kind.symbol).font(.title)
                            } action: {
                                add(kind)
                            }
                        }
                    }
                }
            }
            .frame(height: 220)
            Button("적용하기") {
                try? modelContext.save()
                dismiss()
            }
            .buttonStyle(.primary)
        }
        .padding(Spacing.m)
        .background(Color.app.surface, in: UnevenRoundedRectangle(topLeadingRadius: Radius.large, topTrailingRadius: Radius.large, style: .continuous))
        .shadow(color: Color.app.ink.opacity(0.08), radius: 12, y: -4)
    }

    /// 벽지·바닥재: 색을 바로 칠하거나, 사진으로 꾸미기 화면으로 간다.
    @ViewBuilder
    private func surfaceCells(for kind: FurnitureKind) -> some View {
        if let surface = items.first(where: { $0.kind == kind }) {
            ForEach(Palette.names, id: \.self) { name in
                let isSelected = surface.photoData == nil && (surface.colorName ?? kind.defaultColorName) == name
                cell(isSelected ? "선택됨" : "색") {
                    Circle()
                        .fill(Color(name))
                        .stroke(Color.app.ink.opacity(isSelected ? 1 : 0.15), lineWidth: isSelected ? 3 : 1)
                        .frame(width: 44, height: 44)
                } action: {
                    surface.colorName = name
                    surface.photoData = nil
                }
            }
            cell("사진으로 꾸미기") {
                Image(systemName: "photo").font(.title)
            } action: {
                editingItem = surface
            }
        }
    }

    private func cell(_ title: String, @ViewBuilder icon: () -> some View, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                icon()
                Text(title)
                    .font(.footnote)
            }
            .foregroundStyle(Color.app.ink)
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(Color.app.background, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func add(_ kind: FurnitureKind) {
        guard let spot = RoomLayout.freeSpot(for: kind, among: items.map(\.state)) else {
            isFull = true
            return
        }
        modelContext.insert(RoomItem(kind: kind, x: Double(spot.x), z: Double(spot.y)))
    }

    /// 가구를 옮기면 그 위에 있던 인형도 함께 옮긴다.
    private func move(_ id: UUID, to point: SIMD2<Float>) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        let states = items.map(\.state)
        let delta = point - SIMD2(Float(item.x), Float(item.z))
        for doll in dolls where doll.isPlaced && RoomLayout.seat(at: [doll.position.x, doll.position.z], in: states).item?.id == id {
            doll.position += [delta.x, 0, delta.y]
        }
        item.x = Double(point.x)
        item.z = Double(point.y)
    }

    private func restoreOriginal() {
        guard let original else { return }
        for item in items where !original.contains(where: { $0.id == item.id }) {
            modelContext.delete(item)
        }
        for state in original {
            if let item = items.first(where: { $0.id == state.id }) {
                item.restore(state)
            } else {
                let item = RoomItem(kind: state.kind)
                item.id = state.id
                item.restore(state)
                modelContext.insert(item)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DecorateView()
    }
    .modelContainer(.preview)
}

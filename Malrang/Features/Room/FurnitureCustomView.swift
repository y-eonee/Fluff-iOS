import PhotosUI
import SwiftData
import SwiftUI

/// 가구 하나를 기본 / 컬러 / 사진으로 꾸민다. 사진은 프레임에 맞추기·채우기, 확대, 자르기(위치), 좌우 반전, 회전을 조절할 수 있다.
struct FurnitureCustomView: View {
    @Bindable var item: RoomItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DecorPhoto.createdAt, order: .reverse) private var photos: [DecorPhoto]
    @Query private var dolls: [Doll]
    @State private var style: Style
    @State private var pickerItem: PhotosPickerItem?
    @State private var photoScale: Double
    private let original: RoomItemState
    @State private var undoStack: [PhotoEdit] = []
    @State private var lastRemembered = Date.distantPast

    /// 사진 탭에서 되돌릴 수 있는 한 단계
    private struct PhotoEdit {
        var data: Data?
        var scale: Double
        var fit: Int
        var isFlipped: Bool
        var turns: Int
        var offsetX: Double
        var offsetY: Double
    }

    enum Style: String, CaseIterable {
        case basic = "기본"
        case color = "컬러"
        case photo = "사진"
    }

    private var isEditingPhoto: Bool { style == .photo && item.photoData != nil }

    init(item: RoomItem) {
        self.item = item
        _style = State(initialValue: item.photoData != nil ? .photo : (item.colorName != nil ? .color : .basic))
        _photoScale = State(initialValue: item.photoScale)
        original = item.state
    }

    var body: some View {
        VStack(spacing: 0) {
            RoomSceneView(items: [item.state], focusItem: item.state, isPhotoEditing: isEditingPhoto, onPinch: pinch, onPan: pan)
                .renderedOnlyWhileVisible()
                .overlay(alignment: .top) {
                    HintCapsule(text: isEditingPhoto ? "두 손가락으로 확대하고, 움직여서 자를 곳을 맞춰요" : "드래그해서 이리저리 돌려 보세요")
                        .padding(.top, Spacing.xs)
                }
                .overlay(alignment: .topTrailing) {
                    if style == .photo {
                        Button(action: undo) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(Color.app.surface, in: Circle())
                        }
                        .foregroundStyle(Color.app.ink)
                        .disabled(undoStack.isEmpty)
                        .accessibilityLabel("되돌리기")
                        .padding(Spacing.s)
                    }
                }
            VStack(spacing: Spacing.m) {
                Picker("꾸미기 방식", selection: $style) {
                    ForEach(Style.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                Group {
                    switch style {
                    case .basic:
                        Text("기본 모습으로 보여요")
                            .font(.body)
                            .foregroundStyle(Color.app.inkSecondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .color:
                        ItemColorPicker(item: item)
                    case .photo:
                        if item.photoData != nil { photoEditor } else { photoGrid }
                    }
                }
                .frame(height: style == .color ? 340 : 220)
                CancelConfirmButtons(
                    onCancel: {
                        item.restore(original)
                        dismiss()
                    },
                    onConfirm: { dismiss() }
                )
            }
            .padding(Spacing.m)
            .background(Color.app.surface, in: UnevenRoundedRectangle(topLeadingRadius: Radius.large, topTrailingRadius: Radius.large, style: .continuous))
        }
        .background(Color.app.background)
        .navigationTitle("\(item.kind.label) 꾸미기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if item.kind.isMovable {
                Button("삭제", systemImage: "trash", role: .destructive, action: delete)
            }
        }
        .onChange(of: style) {
            if style == .basic {
                item.colorName = nil
                item.photoData = nil
            }
        }
        .task(id: pickerItem) {
            guard let pickerItem,
                  let data = try? await pickerItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let jpeg = CutoutService.normalized(image, maxSide: 1024).jpegData(compressionQuality: 0.85)
            else { return }
            modelContext.insert(DecorPhoto(data: jpeg))
            apply(jpeg)
            self.pickerItem = nil
        }
    }

    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s), count: 3), spacing: Spacing.s) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundStyle(Color.app.ink)
                        .frame(maxWidth: .infinity, minHeight: 96)
                        .background(Color.app.background, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                }
                .accessibilityLabel("갤러리에서 사진 추가")
                ForEach(photos) { photo in
                    Button {
                        apply(photo.data)
                    } label: {
                        thumbnail(photo.data)
                    }
                    .overlay(alignment: .topTrailing) {
                        Button("사진 지우기", systemImage: "xmark.circle.fill") { modelContext.delete(photo) }
                            .labelStyle(.iconOnly)
                            .font(.title3)
                            .foregroundStyle(Color.app.ink, Color.app.surface)
                            .frame(width: 44, height: 44)
                    }
                }
            }
        }
    }

    private var photoEditor: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            thumbnail(item.photoData ?? Data())
                .frame(width: 120)
                .overlay(alignment: .topTrailing) {
                    Button("사진 빼기", systemImage: "xmark.circle.fill") {
                        remember()
                        item.photoData = nil
                    }
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(Color.app.ink, Color.app.surface)
                        .frame(width: 44, height: 44)
                }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Chip(title: "채우기", isSelected: item.photoFit == 0, isCompact: true) { setFit(0) }
                        Chip(title: "맞추기", isSelected: item.photoFit == 1, isCompact: true) { setFit(1) }
                    }
                    Text("확대")
                        .font(.headline)
                    Slider(value: $photoScale, in: 1...3) { isEditing in
                        if isEditing { remember() } else { item.photoScale = photoScale }
                    }
                }
                HStack(spacing: Spacing.s) {
                    Button {
                        remember()
                        item.photoFlipped.toggle()
                    } label: {
                        Label("좌우 반전", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                    }
                    Button {
                        remember()
                        item.photoTurns = (item.photoTurns + 1) % 4
                    } label: {
                        Label("회전", systemImage: "rotate.right")
                    }
                }
                .buttonStyle(.secondary)
                .labelStyle(.titleAndIcon)
                .font(.footnote)
            }
        }
        .foregroundStyle(Color.app.ink)
    }

    private func thumbnail(_ data: Data) -> some View {
        Image(uiImage: UIImage(data: data) ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 96)
            .clipShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
    }

    /// 되돌리기용으로 지금 사진 상태를 저장한다.
    private func remember() {
        undoStack.append(PhotoEdit(data: item.photoData, scale: item.photoScale, fit: item.photoFit, isFlipped: item.photoFlipped,
                                   turns: item.photoTurns, offsetX: item.photoOffsetX, offsetY: item.photoOffsetY))
        lastRemembered = .now
    }

    /// 두 손가락으로 계속 움직이는 동안에는 시작할 때 한 번만 저장한다.
    private func rememberGesture() {
        if Date.now.timeIntervalSince(lastRemembered) > 0.8 { remember() }
        lastRemembered = .now
    }

    private func undo() {
        guard let last = undoStack.popLast() else { return }
        item.photoData = last.data
        item.photoScale = last.scale
        item.photoFit = last.fit
        item.photoFlipped = last.isFlipped
        item.photoTurns = last.turns
        item.photoOffsetX = last.offsetX
        item.photoOffsetY = last.offsetY
        photoScale = last.scale
    }

    /// 프레임에 맞추는 방식을 바꾸면 확대와 자른 위치를 처음으로 돌린다.
    private func setFit(_ fit: Int) {
        guard item.photoFit != fit else { return }
        remember()
        item.photoFit = fit
        item.photoScale = 1
        item.photoOffsetX = 0
        item.photoOffsetY = 0
        photoScale = 1
    }

    private func pan(_ move: CGSize) {
        rememberGesture()
        let factor = 0.5 / photoScale
        item.photoOffsetX -= Double(move.width) * factor * (item.photoFlipped ? -1 : 1)
        item.photoOffsetY -= Double(move.height) * factor
    }

    private func pinch(_ scale: CGFloat) {
        rememberGesture()
        photoScale = min(3, max(1, photoScale * scale))
        item.photoScale = photoScale
    }

    private func apply(_ data: Data) {
        remember()
        item.photoData = data
        item.photoScale = 1
        item.photoFit = 0
        item.photoFlipped = false
        item.photoTurns = 0
        item.photoOffsetX = 0
        item.photoOffsetY = 0
        photoScale = 1
    }

    /// 지운 가구 위에 있던 인형은 바닥으로 내린다.
    private func delete() {
        let box = RoomLayout.footprint(item.state)
        for doll in dolls where doll.isPlaced {
            let p = doll.position
            if p.x >= box.min.x && p.x <= box.max.x && p.z >= box.min.y && p.z <= box.max.y { doll.y = 0 }
        }
        modelContext.delete(item)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        FurnitureCustomView(item: RoomItem(kind: .bed))
    }
    .modelContainer(.preview)
}

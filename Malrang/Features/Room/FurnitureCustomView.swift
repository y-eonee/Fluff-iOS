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
    @State private var original: RoomItemState
    @State private var choosingPhoto = false
    @State private var saveFailed = false
    private let initialStyle: Style?
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

    init(item: RoomItem, initialStyle: Style? = nil) {
        self.item = item
        self.initialStyle = initialStyle
        _style = State(initialValue: initialStyle ?? (item.photoData != nil ? .photo : (item.colorName != nil ? .color : .basic)))
        _photoScale = State(initialValue: item.photoScale)
        _original = State(initialValue: item.state)
    }

    var body: some View {
        VStack(spacing: 0) {
            RoomSceneView(items: [item.state], focusItem: item.state, isPhotoEditing: isEditingPhoto, onPinch: pinch, onPan: pan, isCozyRoom: true)
                .renderedOnlyWhileVisible()
                .overlay(alignment: .top) {
                    D1Bubble(text: isEditingPhoto ? "두 손가락으로 확대하고, 움직여서 자를 곳을 맞춰요" : "드래그해서 이리저리 돌려 보세요")
                        .padding(.horizontal, 22).padding(.top, 8)
                }
                .overlay(alignment: .topTrailing) {
                    if style == .photo {
                        D1IconButton(icon: "undo", label: "되돌리기", action: undo)
                            .disabled(undoStack.isEmpty).opacity(undoStack.isEmpty ? 0.4 : 1).padding(8)
                    }
                }
            VStack(spacing: Spacing.m) {
                HStack(spacing: 8) {
                    ForEach(Style.allCases, id: \.self) { option in
                        D1Choice(title: option.rawValue, selected: style == option, fillsWidth: true) { style = option }.frame(maxWidth: .infinity)
                    }
                }
                Group {
                    switch style {
                    case .basic:
                        Text("기본 모습으로 보여요")
                            .appFont(.body)
                            .foregroundStyle(Color.app.inkSecondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .color:
                        ScrollView { FurnitureColorChoices(item: item).padding(.vertical, 8) }
                    case .photo:
                        if item.photoData != nil && !choosingPhoto { photoEditor } else { photoGrid }
                    }
                }
                .frame(height: 220)
                HStack(spacing: 10) {
                    Button("취소") { item.restore(original); saveAndDismiss() }.buttonStyle(D1SecondaryStyle())
                    Button("완료", action: saveAndDismiss).buttonStyle(D1PrimaryStyle())
                }
            }
            .padding(.horizontal, 22).padding(.vertical, 16)
            .background(Color.mib.bg.surface, in: UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22))
        }
        .background(Color.mib.bg.screen)
        .toolbar(.visible, for: .navigationBar)
        .tint(Color.mib.action.primary)
        .foregroundStyle(Color.mib.text.primary)
        .navigationTitle("\(item.kind.label) 꾸미기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if item.kind.isMovable {
                Button("삭제", systemImage: "trash", role: .destructive, action: delete)
            }
        }
        .alert("사진 변경을 저장하지 못했어요", isPresented: $saveFailed) { Button("확인", role: .cancel) {} }
        .task(id: initialStyle) {
            if let initialStyle { style = initialStyle }
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
            if item.photoData != nil {
                Button("사진 변경 취소") { choosingPhoto = false }.buttonStyle(FocusCompactButton()).padding(.bottom, 8)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s), count: 3), spacing: Spacing.s) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    D1Icon(name: "plus")
                        .foregroundStyle(Color.app.ink)
                        .frame(maxWidth: .infinity, minHeight: 96)
                        .background(Color.app.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                            .appFont(.title3)
                            .foregroundStyle(Color.app.ink, Color.app.surface)
                            .frame(width: 44, height: 44)
                    }
                }
            }
        }
    }

    private var photoEditor: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            VStack(spacing: 8) {
                thumbnail(item.photoData ?? Data())
                Button("사진 바꾸기") { choosingPhoto = true }.buttonStyle(FocusCompactButton())
                Button("사진 빼기") {
                    remember(); item.photoData = nil; choosingPhoto = false
                }.pretendard(.medium, 13).foregroundStyle(Color.mib.semantic.error).frame(minHeight: 44)
            }.frame(width: 120)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        D1Choice(title: "채우기", selected: item.photoFit == 0, fillsWidth: true) { setFit(0) }
                        D1Choice(title: "맞추기", selected: item.photoFit == 1, fillsWidth: true) { setFit(1) }
                    }
                    Text("확대")
                        .appFont(.headline)
                    Slider(value: Binding(get: { photoScale }, set: { photoScale = $0; item.photoScale = $0 }), in: 1...3) { isEditing in
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
                .buttonStyle(FocusCompactButton())
                .labelStyle(.titleAndIcon)
                .pretendard(.medium, 13)
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
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
        choosingPhoto = false
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
        choosingPhoto = false
        item.photoData = data
        item.photoScale = 1
        item.photoFit = 0
        item.photoFlipped = false
        item.photoTurns = 0
        item.photoOffsetX = 0
        item.photoOffsetY = 0
        photoScale = 1
    }

    private func saveAndDismiss() {
        do { try modelContext.save(); dismiss() }
        catch { saveFailed = true }
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

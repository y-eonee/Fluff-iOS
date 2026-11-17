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
    @Query(sort: \RoomItem.createdAt) private var roomItems: [RoomItem]
    @State private var style: Style
    @State private var pickerItem: PhotosPickerItem?
    @State private var furnitureBounds: [String: CGRect] = [:]
    @State private var photoScale: Double
    @State private var original: RoomItemState
    @State private var choosingPhoto = false
    @State private var saveFailed = false
    private let initialStyle: Style?
    @State private var undoStack: [PhotoEdit] = []
    @State private var redoStack: [PhotoEdit] = []
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
        _style = State(initialValue: initialStyle ?? (item.photoData != nil ? .photo : .color))
        _photoScale = State(initialValue: item.photoScale)
        _original = State(initialValue: item.state)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { item.restore(original); saveAndDismiss() } label: { Image("rep4_edit_back").resizable().frame(width: 31.854, height: 31.854).frame(width: 44, height: 44) }.accessibilityLabel("가구 목록")
                Spacer()
                Text("\(item.kind.label) 꾸미기").pretendard(.bold, 17, tracking: -0.85).offset(y: -4)
                Spacer()
                Button(action: saveAndDismiss) { Image("rep4_edit_confirm").resizable().frame(width: 40.755, height: 40.755) }.accessibilityLabel("꾸미기 완료")
            }.buttonStyle(.plain).padding(.horizontal, 22).offset(y: 6)
            RoomSceneView(items: roomItems.map(\.state), dolls: dolls.filter(\.isPlaced).map(\.state), mode: .decorate,
                          isPhotoEditing: isEditingPhoto, onPinch: pinch, onPan: pan,
                          selectedItemID: item.id, isTransparent: true, illustrationTargetY: 0.7, isCozyRoom: true, onFurnitureScreen: { furnitureBounds = $0 })
                .renderedOnlyWhileVisible(background: .clear)
                .overlay {
                    if let rect = furnitureBounds[item.id.uuidString] { FurnitureSelectionOverlay(rect: rect, title: item.kind.label) }
                }
                .overlay(alignment: .bottom) {
            HStack(spacing: 3.77) {
                RoomHistoryButton(redo: false, action: undo).disabled(undoStack.isEmpty).opacity(undoStack.isEmpty ? 0.4 : 1)
                RoomHistoryButton(redo: true, action: redo).disabled(redoStack.isEmpty).opacity(redoStack.isEmpty ? 0.4 : 1)
                Spacer()
            }.padding(.horizontal, 23.23).padding(.bottom, 6)
                }
                .accessibilityHint(isEditingPhoto ? "두 손가락으로 확대하고 움직여서 자를 곳을 맞춰요" : "드래그해서 이리저리 돌려 보세요")
            VStack(spacing: 0) {
                Text("\(item.kind.label) 편집").pretendard(.bold, 16).frame(maxWidth: .infinity).frame(height: 52)
                    .overlay(alignment: .leading) { Button { item.restore(original); saveAndDismiss() } label: { HStack(spacing: 2) { Image("rep4_list_back").resizable().frame(width: 20, height: 20); Text("가구 목록").pretendard(.medium, 14) }.frame(minHeight: 44) }.buttonStyle(.plain) }
                HStack(spacing: 8) {
                    ForEach([Style.color, .photo], id: \.self) { option in
                        D1Choice(title: option.rawValue, selected: style == option, fillsWidth: true, height: 37, fontSize: 14) { style = option }.frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 10).padding(.bottom, style == .color ? 14 : (item.photoData != nil && !choosingPhoto ? 8 : 20))
                Group {
                    switch style {
                    case .basic:
                        Text("기본 모습으로 보여요")
                            .appFont(.body)
                            .foregroundStyle(Color.app.inkSecondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .color:
                        ScrollView { FurnitureColorChoices(item: item) }
                    case .photo:
                        if item.photoData != nil && !choosingPhoto { photoEditor } else { photoGrid }
                    }
                }
                .frame(height: style == .photo && item.photoData != nil && !choosingPhoto ? 142.2 : 136, alignment: .top)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24).frame(height: 266)
            .background { Color.rep4.c01.clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14)).ignoresSafeArea(edges: .bottom) }
        }
        .background { RepresentativeGradientFill(definition: RepresentativeGradients.roomBackground).ignoresSafeArea() }
        .toolbar(.hidden, for: .navigationBar)
        .tint(Color.mib.action.primary)
        .foregroundStyle(Color.mib.text.primary)
        .cozyPageTitle("\(item.kind.label) 꾸미기")
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
                item.windowFrameColor = nil
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
        PhotosPicker(selection: $pickerItem, matching: .images) {
            VStack(spacing: 6) {
                Image("rep4_photo_add").resizable().frame(width: 22, height: 22)
                    .frame(width: 44, height: 44)
                    .background { RepresentativeGradientFill(definition: RepresentativeGradients.cta).clipShape(Circle()) }
                Text("사진 추가하기").pretendard(.bold, 15)
                Text(item.kind == .desk ? "책상 윗면에 사진을 붙일 수 있어요" : "\(item.kind.label)에 사진을 붙일 수 있어요").pretendard(.medium, 13).foregroundStyle(Color.rep4.c29)
            }.frame(maxWidth: .infinity).frame(height: 136)
                .background(Color.rep4.c11, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.rep4.c29, style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])))
        }.buttonStyle(.plain).contextMenu { photoAdjustmentActions }.frame(maxHeight: .infinity, alignment: .top)
    }

    private var photoEditor: some View {
        VStack(spacing: 18.2) {
            HStack(spacing: 12) {
                thumbnail(item.photoData ?? Data()).frame(width: 48, height: 48).clipped()
                Text("적용된 사진").pretendard(.bold, 14)
                Spacer()
            }.padding(.horizontal, 10).padding(.vertical, 8).background(Color.rep4.c01, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.rep4.c07))
                .contextMenu { photoAdjustmentActions }
            HStack(spacing: 12) {
                Button { remember(); item.photoData = nil; choosingPhoto = false } label: {
                    Text("사진 빼기").pretendard(.medium, 16).foregroundStyle(Color(uiColor: Palette.uiColor("#AD4141")))
                        .frame(maxWidth: .infinity).frame(height: 60)
                        .background(Color.rep4.c11, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color(uiColor: Palette.uiColor("#AD4141"))))
                        .contentShape(Capsule())
                }.buttonStyle(.plain)
                PhotosPicker(selection: $pickerItem, matching: .images) { Text("사진 바꾸기") }.buttonStyle(D1PrimaryStyle())
            }.padding(.horizontal, -6)
        }.frame(maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder private var photoAdjustmentActions: some View {
        Button("채우기") { setFit(0) }; Button("맞추기") { setFit(1) }
        Button("좌우 반전") { remember(); item.photoFlipped.toggle() }
        Button("90도 회전") { remember(); item.photoTurns = (item.photoTurns + 1) % 4 }
        ForEach(photos) { photo in
            Button { apply(photo.data) } label: {
                Label {
                    Text(photo.createdAt.formatted(date: .numeric, time: .shortened))
                } icon: { Image(uiImage: UIImage(data: photo.data) ?? UIImage()) }
            }
        }
    }

    private func thumbnail(_ data: Data) -> some View {
        Image(uiImage: UIImage(data: data) ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    /// 되돌리기용으로 지금 사진 상태를 저장한다.
    private var currentPhotoEdit: PhotoEdit {
        PhotoEdit(data: item.photoData, scale: item.photoScale, fit: item.photoFit, isFlipped: item.photoFlipped,
                  turns: item.photoTurns, offsetX: item.photoOffsetX, offsetY: item.photoOffsetY)
    }
    private func remember() {
        undoStack.append(currentPhotoEdit); redoStack.removeAll()
        lastRemembered = .now
    }

    /// 두 손가락으로 계속 움직이는 동안에는 시작할 때 한 번만 저장한다.
    private func rememberGesture() {
        if Date.now.timeIntervalSince(lastRemembered) > 0.8 { remember() }
        lastRemembered = .now
    }

    private func undo() {
        guard let last = undoStack.popLast() else { return }
        redoStack.append(currentPhotoEdit)
        restorePhotoEdit(last)
    }

    private func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(currentPhotoEdit)
        restorePhotoEdit(next)
    }

    private func restorePhotoEdit(_ last: PhotoEdit) {
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

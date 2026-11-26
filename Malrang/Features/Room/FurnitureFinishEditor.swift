import PhotosUI
import SwiftUI

/// The same color/photo panel is shared by walls, floors and editable furniture.
struct FurnitureFinishEditor: View {
    @Bindable var item: RoomItem
    let initialPhotoMode: Bool?
    var rightWall = false
    private var photoData: Data? { rightWall ? item.rightWallPhotoData : item.photoData }
    private var surfaceName: String { rightWall ? "오른쪽 벽" : item.kind.label }
    var requestPhotoRemoval: (() -> Void)? = nil
    @State private var photoMode: Bool
    init(item: RoomItem, rightWall: Bool = false, initialPhotoMode: Bool? = nil, requestPhotoRemoval: (() -> Void)? = nil) {
        self.item = item; self.rightWall = rightWall; self.initialPhotoMode = initialPhotoMode
        self.requestPhotoRemoval = requestPhotoRemoval
        _photoMode = State(initialValue: initialPhotoMode ?? ((rightWall ? item.rightWallPhotoData : item.photoData) != nil))
    }
    @State private var selection: PhotosPickerItem?
    @State private var confirmsPhotoRemoval = false
    var body: some View {
        VStack(spacing: photoMode ? (photoData == nil ? 20 : 8) : 12) {
            HStack(spacing: 8) {
                D1Choice(title: "컬러", selected: !photoMode, fillsWidth: true, height: 37, fontSize: 14) { photoMode = false }
                D1Choice(title: "사진", selected: photoMode, fillsWidth: true, height: 37, fontSize: 14) { photoMode = true }
            }.padding(.leading, 5.34).padding(.trailing, 10.35)
            if photoMode {
                if let data = photoData {
                    HStack(spacing: 12) {
                        DollThumbnail(data: data, fillsFrame: true).frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 10))
                        Text("적용된 사진").pretendard(.bold, 14)
                        Spacer()
                        Button { if let requestPhotoRemoval { requestPhotoRemoval() } else { confirmsPhotoRemoval = true } } label: {
                            Image(systemName: "trash").font(.system(size: 20)).foregroundStyle(Color.mib.semantic.error).frame(width: 44, height: 44)
                        }.buttonStyle(.plain).accessibilityLabel("사진 빼기")
                    }.padding(.horizontal, 10).padding(.vertical, 8)
                        .background(Color.rep4.c01, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.rep4.c07))
                        .padding(.leading, 5.34).padding(.trailing, 10.35)
                    PhotosPicker(selection: $selection, matching: .images) { Text("사진 바꾸기") }.buttonStyle(D1PrimaryStyle()).padding(.top, 8)
                } else {
                    PhotosPicker(selection: $selection, matching: .images) {
                        VStack(spacing: 6) {
                            Image("rep4_photo_add").resizable().frame(width: 22, height: 22)
                                .frame(width: 44, height: 44)
                                .background { FlowDesign.action.clipShape(Circle()) }
                            Text("사진 추가하기").pretendard(.bold, 15)
                            Text("\(surfaceName)에 사진을 붙일 수 있어요").pretendard(.medium, 13).foregroundStyle(Color.rep4.c29)
                        }.frame(maxWidth: .infinity).frame(height: 136)
                            .background(Color.rep4.c11, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.rep4.c29, style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])))
                    }.buttonStyle(.plain).accessibilityLabel("사진 추가하기").padding(.leading, 5.34).padding(.trailing, 10.35)
                }
            } else { FurnitureColorChoices(item: item, rightWall: rightWall).padding(.leading, 5.34).padding(.trailing, 10.35) }
        }.padding(.top, photoMode ? 6.83 : 0)
            .fullScreenCover(isPresented: $confirmsPhotoRemoval) {
                RoomPhotoRemovalDialog(itemName: surfaceName, cancel: { confirmsPhotoRemoval = false }) {
                    setPhoto(nil); confirmsPhotoRemoval = false
                }.presentationBackground(.clear)
            }
            .onAppear { photoMode = initialPhotoMode ?? ((rightWall ? item.rightWallPhotoData : item.photoData) != nil) }
            .task(id: selection) {
                guard let selection, let data = try? await selection.loadTransferable(type: Data.self),
                      let image = await ImageDownsampling.load(data, maxPixel: 1024),
                      let normalized = image.jpegData(compressionQuality: 0.85), !Task.isCancelled else { return }
                setPhoto(normalized)
                self.selection = nil
            }
    }
    private func setPhoto(_ data: Data?) {
        if rightWall { item.rightWallPhotoData = data }
        else { item.photoData = data; item.photoScale = 1; item.photoOffsetX = 0; item.photoOffsetY = 0 }
    }
}
#Preview { FurnitureFinishEditor(item: RoomItem(kind: .wall)).padding() }

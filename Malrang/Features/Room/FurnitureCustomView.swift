import PhotosUI
import SwiftData
import SwiftUI

/// 가구 하나를 기본 / 컬러 / 사진으로 꾸민다. 사진은 크기, 좌우 반전, 회전을 조절할 수 있다.
struct FurnitureCustomView: View {
    @Bindable var item: RoomItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DecorPhoto.createdAt, order: .reverse) private var photos: [DecorPhoto]
    @Query private var dolls: [Doll]
    @State private var style: Style
    @State private var pickerItem: PhotosPickerItem?
    @State private var photoScale: Double

    enum Style: String, CaseIterable {
        case basic = "기본"
        case color = "컬러"
        case photo = "사진"
    }

    init(item: RoomItem) {
        self.item = item
        _style = State(initialValue: item.photoData != nil ? .photo : (item.colorName != nil ? .color : .basic))
        _photoScale = State(initialValue: item.photoScale)
    }

    var body: some View {
        VStack(spacing: 0) {
            RoomSceneView(items: [item.state], focusItem: item.state)
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
                        colors
                    case .photo:
                        if item.photoData != nil { photoEditor } else { photoGrid }
                    }
                }
                .frame(height: 220)
                Button("적용하기") { dismiss() }
                    .buttonStyle(.primary)
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

    private var colors: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Spacing.s) {
            ForEach(Palette.names, id: \.self) { name in
                let isSelected = item.photoData == nil && item.colorName == name
                Button {
                    item.colorName = name
                    item.photoData = nil
                } label: {
                    Circle()
                        .fill(Color(name))
                        .stroke(Color.app.ink.opacity(isSelected ? 1 : 0.15), lineWidth: isSelected ? 3 : 1)
                        .frame(width: 56, height: 56)
                        .overlay {
                            if isSelected { Image(systemName: "checkmark").font(.headline).foregroundStyle(Color.app.ink) }
                        }
                }
                .accessibilityLabel(isSelected ? "선택된 색" : "색")
            }
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
                    Button("사진 빼기", systemImage: "xmark.circle.fill") { item.photoData = nil }
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(Color.app.ink, Color.app.surface)
                        .frame(width: 44, height: 44)
                }
            VStack(alignment: .leading, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("크기 조절")
                        .font(.headline)
                    Slider(value: $photoScale, in: 0.5...3) { isEditing in
                        if !isEditing { item.photoScale = photoScale }
                    }
                }
                HStack(spacing: Spacing.s) {
                    Button {
                        item.photoFlipped.toggle()
                    } label: {
                        Label("좌우 반전", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                    }
                    Button {
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

    private func apply(_ data: Data) {
        item.photoData = data
        item.photoScale = 1
        item.photoFlipped = false
        item.photoTurns = 0
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

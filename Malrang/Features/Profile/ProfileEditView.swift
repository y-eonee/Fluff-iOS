import PhotosUI
import SwiftUI

/// 프로필 만들기(첫 가입)와 프로필 편집. 만들 때는 "시작하기", 편집할 때는 취소/완료.
struct ProfileEditView: View {
    var isCreating = false
    @AppStorage("nickname") private var nickname = ""
    @AppStorage("avatarData") private var avatarData = Data()
    @Environment(\.dismiss) private var dismiss
    @State private var draftName = ""
    @State private var draftAvatar = Data()
    @State private var pickerItem: PhotosPickerItem?
    private let maxLength = 10

    private var trimmed: String { draftName.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        VStack(spacing: Spacing.l) {
            if isCreating {
                Text("친구들에게 보여질 모습을 정해주세요")
                    .font(.footnote)
                    .foregroundStyle(Color.app.inkSecondary)
            }
            avatar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("닉네임")
                    .font(.headline)
                HStack {
                    TextField("", text: $draftName, prompt: Text("닉네임을 입력해주세요").foregroundStyle(Color.app.inkSecondary.opacity(0.5)))
                        .onChange(of: draftName) {
                            if draftName.count > maxLength { draftName = String(draftName.prefix(maxLength)) }
                        }
                    Text("\(draftName.count)/\(maxLength)")
                        .font(.footnote)
                        .foregroundStyle(Color.app.inkSecondary)
                }
                .padding(.horizontal, Spacing.m)
                .frame(minHeight: 52)
                .background(Color.app.surface, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).stroke(Color.app.ink.opacity(0.15)))
                Text("친구에게 보이는 이름이에요 · 최대 \(maxLength)자")
                    .font(.footnote)
                    .foregroundStyle(Color.app.inkSecondary)
            }
            Spacer()
            if isCreating {
                Button("시작하기", action: save)
                    .buttonStyle(.primary)
                    .disabled(trimmed.isEmpty)
            } else {
                CancelConfirmButtons(onCancel: { dismiss() }, onConfirm: save)
                    .disabled(trimmed.isEmpty)
            }
        }
        .foregroundStyle(Color.app.ink)
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.app.background)
        .navigationTitle(isCreating ? "프로필 만들기" : "프로필 편집")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!isCreating)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            draftName = nickname
            draftAvatar = avatarData
        }
        .task(id: pickerItem) {
            guard let pickerItem,
                  let data = try? await pickerItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let jpeg = CutoutService.normalized(image, maxSide: 256).jpegData(compressionQuality: 0.8)
            else { return }
            draftAvatar = jpeg
            self.pickerItem = nil
        }
    }

    private var avatar: some View {
        VStack(spacing: Spacing.xs) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ProfileAvatar(data: draftAvatar, size: 150)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera.fill")
                            .font(.body)
                            .frame(width: 44, height: 44)
                            .background(Color.app.surface, in: Circle())
                            .overlay(Circle().stroke(Color.app.ink.opacity(0.15)))
                    }
            }
            .accessibilityLabel("프로필 사진 바꾸기")
            Text("사진을 눌러 변경할 수 있어요")
                .font(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
        }
    }

    private func save() {
        nickname = trimmed
        avatarData = draftAvatar
        if !isCreating { dismiss() }
    }
}

/// 프로필 사진. 사진이 없으면 기본 아바타를 보여준다.
struct ProfileAvatar: View {
    let data: Data
    let size: CGFloat

    var body: some View {
        Group {
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.app.inkSecondary)
            }
        }
        .frame(width: size, height: size)
        .background(Color.app.pastelSky)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

#Preview("만들기") {
    NavigationStack { ProfileEditView(isCreating: true) }
}

#Preview("편집") {
    NavigationStack { ProfileEditView() }
}

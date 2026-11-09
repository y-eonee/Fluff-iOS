import PhotosUI
import SwiftData
import SwiftUI

/// 프로필 만들기와 편집. 편집은 뒤로가기와 단일 완료 버튼을 제공한다.
struct ProfileEditView: View {
    var isCreating = false
    @AppStorage("nickname") private var nickname = ""
    @AppStorage("avatarData") private var avatarData = Data()
    @AppStorage("isSignedIn") private var isSignedIn = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isConfirmingDelete = false
    @State private var isConfirmingLogout = false
    @State private var draftName = ""
    @State private var draftAvatar = Data()
    @State private var pickerItem: PhotosPickerItem?
    @State private var accountError: String?
    private let maxLength = 10

    private var trimmed: String { draftName.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(spacing: Spacing.l) {
            ZStack {
                Text(isCreating ? "프로필 만들기" : "프로필 편집")
                    .pretendard(.bold, 18)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("profile-page-title")
                if !isCreating {
                    HStack {
                        Button { dismiss() } label: {
                            D1Icon(name: "back").frame(width: 44, height: 44).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityLabel("뒤로가기")
                        Spacer()
                    }
                }
            }.frame(height: 44)
            if isCreating {
                Text("내 방에서 사용할 프로필을 정해주세요")
                    .appFont(.footnote)
                    .foregroundStyle(Color.app.inkSecondary)
            }
            avatar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("닉네임")
                    .appFont(.headline)
                HStack {
                    TextField("", text: $draftName, prompt: Text("닉네임을 입력해주세요").foregroundStyle(Color.app.inkSecondary.opacity(0.5)))
                        .submitLabel(isCreating ? .go : .done)
                        .onSubmit { if !trimmed.isEmpty { save() } }
                        .onChange(of: draftName) {
                            if draftName.count > maxLength { draftName = String(draftName.prefix(maxLength)) }
                        }
                    Text("\(draftName.count)/\(maxLength)")
                        .appFont(.footnote)
                        .foregroundStyle(Color.app.inkSecondary)
                }
                .padding(.horizontal, Spacing.m)
                .frame(minHeight: 52)
                .background(Color.app.surface, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).stroke(Color.app.ink.opacity(0.15)))
                Text("내 방에서 사용할 이름이에요 · 최대 \(maxLength)자")
                    .appFont(.footnote)
                    .foregroundStyle(Color.app.inkSecondary)
            }
            Spacer()
            if isCreating {
                Button("시작하기", action: save)
                    .buttonStyle(.primary)
                    .disabled(trimmed.isEmpty)
            } else {
                HStack(spacing: 24) {
                    Button { isConfirmingLogout = true } label: {
                        Text("로그아웃").frame(minHeight: 44).contentShape(Rectangle())
                    }
                    Button { isConfirmingDelete = true } label: {
                        Text("회원탈퇴").frame(minHeight: 44).contentShape(Rectangle())
                    }
                }
                .buttonStyle(.plain)
                .pretendard(.regular, 13)
                .foregroundStyle(Color.app.inkSecondary)
                .frame(minHeight: 44)
                Button("완료", action: save)
                    .buttonStyle(CreationPrimaryButton())
                    .disabled(trimmed.isEmpty)
            }
        }
        .foregroundStyle(Color.app.ink)
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { AppBackground() }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            draftName = nickname
            draftAvatar = avatarData
        }
        .confirmationDialog("정말 탈퇴할까요?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("탈퇴하기", role: .destructive, action: deleteAccount)
        } message: {
            Text("이 기기의 인형, 방, 프로필이 모두 지워지고 되돌릴 수 없어요. Apple 계정 연결은 Apple 계정 설정에서 별도로 해제할 수 있어요.")
        }
        .confirmationDialog("로그아웃할까요?", isPresented: $isConfirmingLogout, titleVisibility: .visible) {
            Button("로그아웃", role: .destructive) { AppleAccount.signOut(); isSignedIn = false }
        } message: {
            Text("인형과 방은 그대로 남아 있어요")
        }
        .alert("계정 정보를 삭제하지 못했어요", isPresented: Binding(get: { accountError != nil }, set: { if !$0 { accountError = nil } })) {
            Button("확인", role: .cancel) { accountError = nil }
        } message: { Text(accountError ?? "다시 시도해 주세요.") }
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
                            .appFont(.body)
                            .frame(width: 44, height: 44)
                            .background(Color.app.surface, in: Circle())
                            .overlay(Circle().stroke(Color.app.ink.opacity(0.15)))
                    }
            }
            .accessibilityLabel("프로필 사진 바꾸기")
            Text("사진을 눌러 변경할 수 있어요")
                .appFont(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
        }
    }

    private func deleteAccount() {
        do {
            try modelContext.delete(model: Doll.self)
            try modelContext.delete(model: RoomItem.self)
            try modelContext.delete(model: DecorPhoto.self)
            try modelContext.save()
            try AppleAccount.removeLocalIdentity()
            nickname = ""
            avatarData = Data()
            isSignedIn = false
            RenderMemory.clearCaches()
        } catch {
            modelContext.rollback()
            accountError = "저장 상태를 확인한 뒤 다시 시도해 주세요."
        }
    }

    private func save() {
        guard !trimmed.isEmpty else { return }
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
                    .appFont(.largeTitle)
                    .foregroundStyle(Color.app.inkSecondary)
            }
        }
        .frame(width: size, height: size)
        .background(Color.mib.bg.mintSoft)
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

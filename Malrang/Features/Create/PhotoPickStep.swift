import PhotosUI
import SwiftUI

/// 앱 안에 끼워 넣은 사진 선택기. 사용자가 고른 사진만 받으므로 앨범 권한을 묻지 않는다.
struct PhotoPickStep: View {
    let draft: DollDraft
    let onNext: () -> Void
    @State private var selection: PhotosPickerItem?
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("얼굴이나 캐릭터가 잘 보이는 사진이 좋아요")
                .font(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
                .padding(.horizontal, Spacing.m)
            PhotosPicker("사진 선택", selection: $selection, matching: .images, photoLibrary: .shared())
                .photosPickerStyle(.inline)
                .photosPickerDisabledCapabilities(.selectionActions)
                .photosPickerAccessoryVisibility(.hidden, edges: .all)
            VStack(spacing: Spacing.xs) {
                Text(draft.photo == nil ? "사진 1장을 골라 주세요" : "1장 선택됨")
                    .font(.footnote)
                    .foregroundStyle(Color.app.inkSecondary)
                Button {
                    onNext()
                } label: {
                    if isLoading { ProgressView() } else { Text("이 사진으로 만들기") }
                }
                .buttonStyle(.primary)
                .disabled(draft.photo == nil || isLoading)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.m)
        }
        .background(Color.app.background)
        .navigationTitle("사진 선택")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: selection) {
            guard let selection else { return }
            isLoading = true
            defer { isLoading = false }
            if let data = try? await selection.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                draft.photo = CutoutService.normalized(image)
                draft.cutout = nil
                draft.editedCutout = nil
            }
        }
    }
}

#Preview {
    NavigationStack {
        PhotoPickStep(draft: DollDraft()) {}
    }
}

import SwiftUI

struct CutoutReadyStep: View {
    let draft: DollDraft
    let onEdit: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("좋아요!\n이제 인형 모양을 골라요")
                .pretendard(.bold, 20)
            Text("투명하게 만든 사진이 인형 원단에 들어가요")
                .pretendard(.regular, 13)
                .foregroundStyle(Color.app.inkSecondary)
            Image(uiImage: draft.finalCutout ?? UIImage())
                .resizable()
                .scaledToFit()
                .padding(Spacing.l)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cardStyle()
                .overlay(alignment: .topLeading) {
                    Label("투명화 완료", systemImage: "checkmark")
                        .appFont(.footnote, .bold)
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, Spacing.xxs)
                        .background(CreationStyle.yellow, in: Capsule())
                        .padding(Spacing.s)
                }
            HStack(spacing: Spacing.s) {
                Button("다시 편집", action: onEdit)
                    .buttonStyle(CreationSecondaryButton())
                Button("모양 선택하기", action: onNext)
                    .buttonStyle(CreationPrimaryButton())
            }
        }
        .foregroundStyle(Color.app.ink)
        .padding(Spacing.m)
        .cozyPageTitle("making fluff")
    }
}

#Preview {
    let draft = DollDraft()
    draft.cutout = UIImage(systemName: "cat.fill")
    return NavigationStack {
        CutoutReadyStep(draft: draft, onEdit: {}, onNext: {})
    }
}

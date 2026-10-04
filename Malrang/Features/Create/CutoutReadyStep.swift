import SwiftUI

struct CutoutReadyStep: View {
    let draft: DollDraft
    let onEdit: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("좋아요!\n이제 인형을 만들러 가요")
                .font(.title2.bold())
            Text("누끼를 딴 사진이 인형 원단에 들어가요")
                .font(.body)
                .foregroundStyle(Color.app.inkSecondary)
            Image(uiImage: draft.finalCutout ?? UIImage())
                .resizable()
                .scaledToFit()
                .padding(Spacing.l)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cardStyle()
                .overlay(alignment: .topLeading) {
                    Label("누끼 완료", systemImage: "checkmark")
                        .font(.footnote.bold())
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.app.pastelMint, in: Capsule())
                        .padding(Spacing.s)
                }
            HStack(spacing: Spacing.s) {
                Button("다시 편집", action: onEdit)
                    .buttonStyle(.secondary)
                Button("인형 만들러 가기", action: onNext)
                    .buttonStyle(.primary)
            }
        }
        .foregroundStyle(Color.app.ink)
        .padding(Spacing.m)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let draft = DollDraft()
    draft.cutout = UIImage(systemName: "cat.fill")
    return NavigationStack {
        CutoutReadyStep(draft: draft, onEdit: {}, onNext: {})
    }
}

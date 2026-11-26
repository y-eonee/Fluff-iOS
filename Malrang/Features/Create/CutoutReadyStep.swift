import SwiftUI

struct CutoutReadyStep: View {
    let draft: DollDraft
    let onEdit: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("좋아요!\n이제 만들기 모양을 골라요")
                .pretendard(.bold, 17, tracking: -0.85)
                .lineSpacing(6).frame(height: 52, alignment: .topLeading)
            Text("투명하게 만든 사진이 인형 원단에 들어가요")
                .pretendard(.regular, 14, tracking: -0.7)
                .foregroundStyle(Color.rep4.c29)
                .frame(height: 20.3).padding(.top, 19)
            GeometryReader { proxy in
                let width = proxy.size.width.isFinite ? max(0, proxy.size.width - 90) : 0
                let height = proxy.size.height.isFinite ? max(0, min(269, proxy.size.height - 100)) : 0
                Image(uiImage: draft.finalCutout ?? UIImage())
                    .resizable().scaledToFit()
                    .frame(width: width, height: height)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 224.5 / 426)
            }
            .background(Color.rep4.c01, in: RoundedRectangle(cornerRadius: 18))
            .overlay(alignment: .topLeading) {
                Text("✓ 투명화 완료").pretendard(.medium, 12)
                    .frame(width: 116, height: 28).padding(.top, 12)
            }
            .padding(.top, 15.7)
        }
        .foregroundStyle(Color.rep4.c08)
        .padding(.horizontal, 18).padding(.top, 22)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 12) {
                Button("다시 편집", action: onEdit).buttonStyle(CreationSecondaryButton())
                Button("모양 선택하기", action: onNext).buttonStyle(CreationPrimaryButton())
            }.padding(.horizontal, 18).padding(.top, 25).padding(.bottom, 16)
        }
        .background(FlowDesign.makingCanvas.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) { CreationProgress(step: 1) }
        .flowPageTitle("인형 만들기")
    }
}

#Preview {
    let draft = DollDraft()
    draft.cutout = UIImage(systemName: "cat.fill")
    return NavigationStack {
        CutoutReadyStep(draft: draft, onEdit: {}, onNext: {})
    }
}

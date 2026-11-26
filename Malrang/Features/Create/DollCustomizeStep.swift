import SwiftUI

/// 인형 모양(프리셋)과 속재료, 이름을 고른다.
struct DollCustomizeStep: View {
    @Bindable var draft: DollDraft
    var onPrevious: (() -> Void)? = nil
    let onNext: () -> Void

    var body: some View {
        DollCustomizeStepA(draft: draft, onPrevious: onPrevious, onNext: onNext)
    }
}

#Preview {
    let draft = DollDraft()
    draft.cutout = UIImage(systemName: "cat.fill")
    return NavigationStack {
        DollCustomizeStep(draft: draft) {}
    }
}

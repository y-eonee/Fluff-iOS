import SwiftUI

/// 인형 모양(프리셋)과 속재료, 이름을 고른다.
struct DollCustomizeStep: View {
    @Bindable var draft: DollDraft
    let onNext: () -> Void
    @AppStorage("designVariant") private var variant = DesignVariant.a

    var body: some View {
        if variant == .a {
            DollCustomizeStepA(draft: draft, onNext: onNext)
        } else {
            DollCustomizeStepB(draft: draft, onNext: onNext)
        }
    }

}

struct FaceSizeControl: View {
    @Binding var scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("인형 크기").appFont(.footnote, .bold)
            Slider(value: $scale, in: 0.6...2) {
                Text("인형 크기")
            } minimumValueLabel: {
                Text("작게").appFont(.caption)
            } maximumValueLabel: {
                Text("크게").appFont(.caption)
            }
            .accessibilityValue("\(Int(scale * 100))퍼센트")
        }
        .foregroundStyle(Color.app.ink)
    }
}

#Preview {
    let draft = DollDraft()
    draft.cutout = UIImage(systemName: "cat.fill")
    return NavigationStack {
        DollCustomizeStep(draft: draft) {}
    }
}

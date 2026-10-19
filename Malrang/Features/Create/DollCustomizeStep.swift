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
            HStack {
                Text("얼굴 크기").appFont(.footnote, .bold)
                Spacer()
                Button("원래 크기") { scale = 1 }.appFont(.caption).frame(minHeight: 44)
            }
            Slider(value: $scale, in: 0.6...2) {
                Text("얼굴 크기")
            } minimumValueLabel: {
                Image(systemName: "minus.magnifyingglass")
            } maximumValueLabel: {
                Image(systemName: "plus.magnifyingglass")
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

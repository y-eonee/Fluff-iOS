import SwiftUI

struct CreationProgress: View {
    let step: Int
    private let titles = ["사진", "투명화", "방식", "꾸미기", "완성"]

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(titles.indices, id: \.self) { index in
                VStack(spacing: Spacing.xs) {
                    Capsule().fill(index <= step ? Color.a.brown : Color.a.brown.opacity(0.12))
                        .frame(height: 6)
                    Text(titles[index]).appFont(.caption2, index == step ? .bold : .regular)
                        .foregroundStyle(index == step ? Color.a.brown : Color.a.soft)
                }.frame(maxWidth: .infinity)
            }
        }.padding(.horizontal, Spacing.l).padding(.vertical, Spacing.s)
            .background(Color.a.paper)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("5단계 중 \(step + 1)단계, \(titles[step])")
    }
}

#Preview { CreationProgress(step: 1) }

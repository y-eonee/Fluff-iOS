import SwiftUI

struct CreationProgress: View {
    let step: Int
    private let titles = ["사진", "투명화", "인형 모양", "꾸미기", "완성"]

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(titles.indices, id: \.self) { index in
                VStack(spacing: 6) {
                    Capsule().fill(index <= step ? Color.mib.action.primary : Color.mib.bg.sunken)
                        .frame(height: 5)
                    Text(titles[index]).pretendard(.regular, 10)
                        .foregroundStyle(index == step ? Color.mib.text.primary : Color.mib.text.secondary)
                }.frame(maxWidth: .infinity)
            }
        }.padding(.horizontal, Spacing.l).padding(.vertical, 16)
            .background(Color.a.paper)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("5단계 중 \(step + 1)단계, \(titles[step])")
    }
}

#Preview { CreationProgress(step: 1) }

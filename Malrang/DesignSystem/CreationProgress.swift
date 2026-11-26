import SwiftUI

struct CreationProgress: View {
    let step: Int
    var partEditor = false
    var skipsShape = false
    private var titles: [String] { skipsShape ? ["사진", "투명화", "꾸미기", "완성"] : ["사진", "투명화", "모양", "꾸미기", "완성"] }
    private var currentStep: Int { min(max(skipsShape && step >= 2 ? step - 1 : step, 0), titles.count - 1) }
    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 357
            let filledWidths: [CGFloat] = skipsShape ? [60, 165, 260, 357] : [49.59, 138.746, 208.924, 282.207, 357]
            ZStack(alignment: .topLeading) {
                Capsule().fill(Color.rep4.c24).frame(width: proxy.size.width, height: 7.936)
                    .offset(y: 3.4)
                Capsule().fill(FlowDesign.blue).frame(width: filledWidths[currentStep] * scale, height: 7.936)
                    .offset(y: 3.4)
                HStack(spacing: 6.05 * scale) {
                    ForEach(titles.indices, id: \.self) { index in
                        Text("\(index < currentStep ? "✓" : index == currentStep ? "●" : "○") \(titles[index])")
                            .pretendard(.medium, 13)
                            .foregroundStyle(index <= currentStep ? Color.rep4.c08 : Color.rep4.c29)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: proxy.size.width, height: 17.46).offset(y: 17.68)
            }
        }.frame(height: 35)
            .padding(.horizontal, 16)
            .padding(.top, 19.32)
            .padding(.bottom, step == 0 ? 8 : step == 1 ? 7.1 : 23.66)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(titles.count)단계 중 \(currentStep + 1)단계, \(titles[currentStep])")
    }
}
#Preview { CreationProgress(step: 2) }

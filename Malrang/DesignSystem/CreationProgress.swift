import SwiftUI

struct CreationProgress: View {
    let step: Int
    var partEditor = false
    private let titles = ["사진", "투명화", "모양", "꾸미기", "완성"]
    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 342
            let fraction = step == 3 && partEditor ? 241.574 / 322.222 : CGFloat(min(max(step + 1, 0), 5)) / 5
            // Source tracks have different leading edges. Step labels span a
            // wider row than either track; equal fifths of the track compress them.
            ZStack(alignment: .topLeading) {
                Capsule().fill(Color.rep4.c24).frame(width: 322.222 * scale, height: 7.936)
                    .offset(x: 10.92 * scale, y: 3.4)
                Capsule().fill(Color.rep4.c21).frame(width: 322.222 * scale * fraction, height: 7.936)
                    .offset(x: 6.16 * scale, y: 3.4)
                HStack(spacing: 6.05 * scale) {
                    ForEach(titles.indices, id: \.self) { index in
                        Text("\(index < step ? "✓" : index == step ? "●" : "○") \(titles[index])")
                            .pretendard(.medium, 12)
                            .foregroundStyle(index <= step ? Color.rep4.c08 : Color.rep4.c29)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: proxy.size.width, height: 17.46).offset(y: 17.68)
            }
        }.frame(height: 35)
            .padding(.leading, 23.81).padding(.trailing, 24.19)
            .padding(.top, step <= 1 ? 10.93 : 18.49)
            .padding(.bottom, step == 0 ? 15.4 : step == 1 ? 7.1 : 23.84)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("5단계 중 \(min(max(step + 1, 1), 5))단계, \(titles[min(max(step, 0), 4)])")
    }
}
#Preview { CreationProgress(step: 2) }

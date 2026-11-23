import SwiftUI

struct DollHistoryCard: View {
    let doll: Doll

    var body: some View {
        let history = doll.history
        VStack(spacing: 10) {
            stat("📖 지능", score: history.intelligence, source: "책상")
            stat("🌙 감수성", score: history.sensitivity, source: "창문 · 소파")
            stat("⚡ 체력", score: history.stamina, source: "침대")
        }.padding(.horizontal, 19).padding(.vertical, 15)
            .frame(height: 140)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
            .foregroundStyle(Color.rep4.c03)
    }

    private func stat(_ title: String, score: Int, source: String) -> some View {
        VStack(spacing: 5) {
            HStack {
                Text(title).pretendard(.medium, 12)
                Spacer()
                Text("\(score) / 100").pretendard(.regular, 12, tracking: -0.36)
            }.frame(height: 17)
            GeometryReader { geometry in
                Capsule().fill(Color.rep4.c24)
                Capsule().fill(FlowDesign.blue)
                    .frame(width: geometry.size.width * CGFloat(min(100, max(0, score))) / 100)
            }.frame(height: 8)
        }.accessibilityElement(children: .combine)
            .accessibilityHint("\(source) 활동 1회마다 1점, 최대 100점")
    }
}

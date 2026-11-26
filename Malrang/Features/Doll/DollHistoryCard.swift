import SwiftUI

/// Figma 2019:9651: one spacious card, with the original vector stat icons.
struct DollHistoryCard: View {
    let doll: Doll
    var onRename: (() -> Void)? = nil
    private var birthday: String {
        let date = Calendar.current.dateComponents([.year, .month, .day], from: doll.createdAt)
        return String(format: "%04d.%02d.%02d", date.year ?? 0, date.month ?? 0, date.day ?? 0)
    }
    var body: some View {
        let history = doll.history
        VStack(alignment: .leading, spacing: 18) {
            Button { onRename?() } label: {
                HStack(spacing: 6) {
                    Text(doll.name).pretendard(.semiBold, 18, tracking: -0.9).lineLimit(2)
                    Image("profile_pencil").resizable().scaledToFit().frame(width: 14, height: 14)
                }.frame(minHeight: 30)
            }.buttonStyle(.plain).disabled(onRename == nil).accessibilityLabel("인형 이름 수정")
            HStack(spacing: 42) {
                detail("생일", value: birthday)
                detail("만진 횟수", value: "\(history[.touch])회")
                Spacer(minLength: 0)
            }
            stat("지능", icon: "profile_intelligence", score: history.intelligence, source: "책상")
            stat("감수성", icon: "profile_sensitivity", score: history.sensitivity, source: "창문 · 소파")
            stat("체력", icon: "profile_stamina", score: history.stamina, source: "침대")
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
            .foregroundStyle(Color.rep4.c03)
    }
    private func detail(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).pretendard(.regular, 14, tracking: -0.7).foregroundStyle(Color.rep4.c29)
            Text(value).pretendard(.semiBold, 14)
        }
    }
    private func stat(_ title: String, icon: String, score: Int, source: String) -> some View {
        VStack(spacing: 7) {
            HStack(spacing: 6) {
                Image(icon).resizable().scaledToFit().frame(width: 17, height: 17).accessibilityHidden(true)
                Text(title).pretendard(.medium, 14)
                Spacer()
                Text("\(score) / 100").pretendard(.regular, 14, tracking: -0.36)
            }
            GeometryReader { geometry in
                Capsule().fill(Color.rep4.c24)
                Capsule().fill(FlowDesign.blue)
                    .frame(width: geometry.size.width * CGFloat(min(100, max(0, score))) / 100)
            }.frame(height: 10.343)
        }.accessibilityElement(children: .combine)
            .accessibilityHint("\(source) 활동 1회마다 1점, 최대 100점")
    }
}

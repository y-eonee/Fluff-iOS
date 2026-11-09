import SwiftUI

struct DollHistoryCard: View {
    let doll: Doll

    private var firstMet: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: doll.createdAt)
    }

    var body: some View {
        let history = doll.history
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                information("처음 만난 날", value: firstMet)
                information("누른 횟수", value: "\(history[.touch])회")
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("\(doll.name.josa("과", "와")) 함께한 시간").pretendard(.bold, 15)
                HStack(spacing: 12) {
                    activity("책상", icon: "book", count: history[.desk])
                    activity("창문", icon: "window", count: history[.window])
                    activity("소파", icon: "sofa", count: history[.sofa])
                    activity("침대", icon: "bed", count: history[.bed])
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("\(doll.name) 상태").pretendard(.bold, 15)
                HStack(spacing: 8) {
                    stat("지능", icon: "book", score: history.intelligence, source: "책상")
                    stat("감수성", icon: "heart", score: history.sensitivity, source: "창문 · 소파")
                    stat("체력", icon: "strength", score: history.stamina, source: "침대")
                }
            }
        }.padding(.horizontal, 16).padding(.vertical, 18)
            .foregroundStyle(Color.mib.text.primary)
            .background(Color.mib.bg.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    private func information(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).pretendard(.medium, 11).foregroundStyle(Color.mib.text.secondary)
            Text(value).pretendard(.semiBold, 15)
        }.frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
    }

    private func activity(_ title: String, icon: String, count: Int) -> some View {
        VStack(spacing: 3) {
            Image("history_\(icon)").resizable().scaledToFit().frame(width: 27, height: 27).accessibilityHidden(true)
            Text(title).pretendard(.semiBold, 13)
            Text("\(count)회").pretendard(.medium, 13).foregroundStyle(Color.mib.text.secondary)
        }.frame(maxWidth: .infinity).frame(minHeight: 92)
            .background(Color.mib.bg.screen, in: RoundedRectangle(cornerRadius: 18))
            .accessibilityElement(children: .combine)
    }

    private func stat(_ title: String, icon: String, score: Int, source: String) -> some View {
        VStack(spacing: 3) {
            Image("history_\(icon)").resizable().scaledToFit().frame(width: 20, height: 20).accessibilityHidden(true)
            Text(title).pretendard(.semiBold, 12)
            Text("\(score) / 100").pretendard(.semiBold, 13)
            Text(source).pretendard(.regular, 10).foregroundStyle(Color.mib.text.secondary)
        }.frame(maxWidth: .infinity).frame(minHeight: 99)
            .background(Color.mib.bg.mintSoft, in: RoundedRectangle(cornerRadius: 15))
            .accessibilityElement(children: .combine)
            .accessibilityHint("\(source) 활동 1회마다 1점, 최대 100점")
    }
}

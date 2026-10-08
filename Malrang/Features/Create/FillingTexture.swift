import SwiftUI

/// 속재료가 천 아래에서 비쳐 보이는 무늬. 천 모양으로 잘라서 겹쳐 쓴다.
/// 폭신 솜은 몽실한 덩어리, 몽글 비즈는 알알이 볼록한 점, 쫀득 젤리는 매끈한 결, 말랑 폼은 작은 숨구멍이다.
struct FillingTexture: View {
    let filling: Filling

    var body: some View {
        Canvas { context, size in
            let unit = min(size.width, size.height)
            switch filling {
            case .fluffy:
                for index in 0..<26 {
                    let center = point(index, in: size)
                    let radius = unit * (0.07 + 0.05 * random(index, 3))
                    context.fill(Path(ellipseIn: rect(center, radius)), with: .color(.white.opacity(0.15)))
                    context.fill(Path(ellipseIn: rect(CGPoint(x: center.x + radius * 0.35, y: center.y + radius * 0.4), radius * 0.9)),
                                 with: .color(Color.app.ink.opacity(0.04)))
                }
            case .beads:
                let step = unit * 0.075
                for row in 0..<Int(size.height / step) + 1 {
                    for column in 0..<Int(size.width / step) + 1 {
                        let center = CGPoint(x: (CGFloat(column) + (row.isMultiple(of: 2) ? 0.25 : 0.75)) * step, y: (CGFloat(row) + 0.5) * step)
                        context.fill(Path(ellipseIn: rect(center, step * 0.42)), with: .color(Color.app.ink.opacity(0.07)))
                        context.fill(Path(ellipseIn: rect(CGPoint(x: center.x - step * 0.1, y: center.y - step * 0.12), step * 0.2)),
                                     with: .color(.white.opacity(0.4)))
                    }
                }
            case .jelly:
                for index in 0..<5 {
                    let center = point(index + 40, in: size)
                    let radius = unit * (0.18 + 0.1 * random(index, 5))
                    context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius * 0.5, width: radius * 2, height: radius)),
                                 with: .color(.white.opacity(0.22)))
                }
            case .foam:
                for index in 0..<90 {
                    let center = point(index + 80, in: size)
                    context.fill(Path(ellipseIn: rect(center, unit * (0.006 + 0.01 * random(index, 7)))),
                                 with: .color(Color.app.ink.opacity(0.14)))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func rect(_ center: CGPoint, _ radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }

    private func point(_ index: Int, in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * random(index, 1), y: size.height * random(index, 2))
    }

    /// 매번 같은 무늬가 나오도록 번호로 정해지는 0...1 값
    private func random(_ index: Int, _ salt: Int) -> CGFloat {
        let value = sin(Double(index * 127 + salt * 311)) * 43758.5453
        return CGFloat(value - value.rounded(.down))
    }
}

#Preview {
    HStack {
        ForEach(Filling.allCases, id: \.self) { filling in
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.app.accent)
                .overlay { FillingTexture(filling: filling) }
                .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                .frame(width: 80, height: 120)
        }
    }
    .padding()
}

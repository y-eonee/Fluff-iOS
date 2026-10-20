import SwiftUI

/// 피그마의 손그림 테두리를 보존한 원본 이미지. 가장자리는 늘이지 않고 반복해 질감 크기를 유지한다.
struct ASketchOutline: View {
    var radius: CGFloat = 8
    var line: CGFloat = 1.2
    var dashed = false
    var color = Color.a.line

    private var asset: String {
        if dashed { return "a_outline_dashed" }
        if radius <= 10 { return "a_outline_small" }
        if radius <= 18 { return "a_outline_medium" }
        if radius <= 24 { return "a_outline_large" }
        return "a_outline_pill"
    }

    private var cap: CGFloat {
        if dashed || radius <= 10 { return 10 }
        if radius <= 18 { return 18 }
        if radius <= 24 { return 24 }
        return 28
    }

    var body: some View {
        Image(asset)
            .resizable(capInsets: EdgeInsets(top: cap, leading: cap, bottom: cap, trailing: cap), resizingMode: .tile)
            .renderingMode(.template)
            .foregroundStyle(color)
            .opacity(min(1, line / 1.2))
            .padding(-1.2)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct ASketchSurface: View {
    var fill = Color.a.card
    var radius: CGFloat = 8
    var line: CGFloat = 1.2
    var dashed = false

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(fill)
            .overlay { ASketchOutline(radius: radius, line: line, dashed: dashed) }
            .allowsHitTesting(false)
    }
}

struct ASketchIndexSurface: View {
    let fill: Color

    var body: some View {
        UnevenRoundedRectangle(topLeadingRadius: 9, topTrailingRadius: 9, style: .continuous)
            .fill(fill)
            .overlay {
                Image("a_index_outline")
                    .resizable(capInsets: EdgeInsets(top: 11, leading: 11, bottom: 3, trailing: 11), resizingMode: .tile)
                    .renderingMode(.template)
                    .foregroundStyle(Color.a.line)
                    .padding(-1.2)
            }
            .allowsHitTesting(false)
    }
}

#Preview {
    VStack(spacing: Spacing.l) {
        Text("손그림 버튼").padding().sketchBox()
        Text("완료").padding().sketchBox(fill: Color.a.brown, radius: 27)
            .foregroundStyle(Color.a.creamText)
        Text("가구").padding().background { ASketchIndexSurface(fill: Color.a.pinkLight) }
    }
    .padding()
    .background(Color.a.paper)
}

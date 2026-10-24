import SwiftUI

/// 임시 봉제인형 프리셋. 프리셋 디자인과 3D 모델이 나오면 교체한다.
struct DollArtwork: View {
    let shape: DollShape
    let cutout: Image
    var faceScale: CGFloat = 1

    var body: some View {
        switch shape {
        case .bear: bear
        case .cat: cat
        case .star: star
        case .pillow: pillow
        }
    }

    private var fabric: Color { Color.app.accent }

    private var bear: some View {
        GeometryReader { proxy in
            // 귀 끝(-0.57w)부터 몸통 끝(+0.77w)까지 높이가 약 1.35w다.
            let w = min(proxy.size.width, proxy.size.height / 1.35)
            ZStack {
                bearFabric(w, color: fabric)
                cutout
                    .resizable()
                    .scaledToFill()
                    .frame(width: w * 0.6, height: w * 0.6)
                    .scaleEffect(faceScale)
                    .clipShape(Circle())
                    .offset(y: -w * 0.1)
            }
            .offset(y: -w * 0.1)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(0.74, contentMode: .fit)
    }

    private func bearFabric(_ w: CGFloat, color: Color) -> some View {
        ZStack {
            Circle().fill(color).frame(width: w * 0.3).offset(x: -w * 0.28, y: -w * 0.42)
            Circle().fill(color).frame(width: w * 0.3).offset(x: w * 0.28, y: -w * 0.42)
            RoundedRectangle(cornerRadius: w * 0.3, style: .continuous)
                .fill(color)
                .frame(width: w * 0.8, height: w * 0.7)
                .offset(y: w * 0.42)
            Circle().fill(color).frame(width: w * 0.86).offset(y: -w * 0.12)
        }
        // 무늬가 귀부터 몸통 끝까지 덮도록 천 전체를 담는 크기로 잡는다.
        .frame(width: w, height: w * 1.6)
    }

    /// 곰과 같은 몸에 뾰족한 귀를 단 고양이
    private var cat: some View {
        GeometryReader { proxy in
            let w = min(proxy.size.width, proxy.size.height / 1.35)
            ZStack {
                catFabric(w, color: fabric)
                cutout
                    .resizable()
                    .scaledToFill()
                    .frame(width: w * 0.6, height: w * 0.6)
                    .scaleEffect(faceScale)
                    .clipShape(Circle())
                    .offset(y: -w * 0.1)
            }
            .offset(y: -w * 0.1)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(0.74, contentMode: .fit)
    }

    private func catFabric(_ w: CGFloat, color: Color) -> some View {
        ZStack {
            EarShape().fill(color).frame(width: w * 0.34, height: w * 0.4).rotationEffect(.degrees(-14)).offset(x: -w * 0.3, y: -w * 0.46)
            EarShape().fill(color).frame(width: w * 0.34, height: w * 0.4).rotationEffect(.degrees(14)).offset(x: w * 0.3, y: -w * 0.46)
            RoundedRectangle(cornerRadius: w * 0.3, style: .continuous)
                .fill(color)
                .frame(width: w * 0.8, height: w * 0.7)
                .offset(y: w * 0.42)
            Circle().fill(color).frame(width: w * 0.86).offset(y: -w * 0.12)
        }
        .frame(width: w, height: w * 1.6)
    }

    private var star: some View {
        ZStack {
            StarShape().fill(Color.app.pastelYellow)
            StarShape().stroke(Color.white, style: StrokeStyle(lineWidth: 6, dash: [8, 6]))
                .padding(10)
            cutout
                .resizable()
                .scaledToFit()
                .padding(56)
                .scaleEffect(faceScale)
                .clipShape(StarShape())
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// 누끼 실루엣을 따라 흰 테두리(시접)를 두른 쿠션 인형
    private var pillow: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                let angle = Double(index) / 12 * 2 * .pi
                cutout
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .offset(x: cos(angle) * 10, y: sin(angle) * 10)
            }
            .shadow(color: Color.app.ink.opacity(0.15), radius: 6, y: 3)
            cutout
                .resizable()
                .scaledToFit()
        }
        .padding(16)
        .aspectRatio(0.8, contentMode: .fit)
        .scaleEffect(faceScale)
    }
}

/// 고양이 귀: 끝이 둥글게 뭉툭한 삼각형
private struct EarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX * 0.85, y: rect.midY * 0.8))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.maxX * 0.15, y: rect.midY * 0.8))
        path.closeSubpath()
        return path
    }
}

private struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.55
        var path = Path()
        for index in 0..<10 {
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = Double(index) * .pi / 5 - .pi / 2
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    let sample = Image(systemName: "cat.fill")
    HStack {
        ForEach(DollShape.allCases, id: \.self) { shape in
            DollArtwork(shape: shape, cutout: sample).frame(width: 110)
        }
    }
    .padding()
    .background { AppBackground() }
}

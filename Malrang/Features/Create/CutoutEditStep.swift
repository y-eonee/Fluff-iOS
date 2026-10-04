import SwiftUI

/// 자동 누끼 결과를 보여주고, 손가락으로 문질러 지우거나 복원한다.
struct CutoutEditStep: View {
    let draft: DollDraft
    let onReselect: () -> Void
    let onNext: () -> Void
    @State private var phase = Phase.working
    @State private var isErasing = true
    @State private var brushSize = 30.0
    @State private var strokes: [Stroke] = []
    @State private var current: Stroke?

    enum Phase {
        case working, failed, ready
    }

    struct Stroke {
        var points: [CGPoint]
        var width: CGFloat
        var isErasing: Bool
    }

    var body: some View {
        VStack(spacing: Spacing.m) {
            switch phase {
            case .working:
                ProgressView("피사체를 찾는 중이에요")
                    .frame(maxHeight: .infinity)
            case .failed:
                Spacer()
                NoticeCard(symbol: "person.crop.circle.badge.questionmark", title: "피사체를 찾지 못했어요",
                           message: "배경이 단순한 사진으로 다시 골라볼까요?", actionTitle: "다시 선택", action: onReselect)
                Button("사진 그대로 쓰기") {
                    draft.cutout = draft.photo
                    phase = .ready
                }
                .buttonStyle(.secondary)
                .padding(.horizontal, Spacing.l)
                Spacer()
            case .ready:
                editor
            }
        }
        .padding(Spacing.m)
        .navigationTitle("누끼 편집")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if draft.cutout != nil {
                phase = .ready
                return
            }
            guard let image = draft.photo?.cgImage else { return }
            do {
                draft.cutout = UIImage(cgImage: try await CutoutService.cutout(image))
                phase = .ready
            } catch {
                phase = .failed
            }
        }
    }

    private var editor: some View {
        VStack(spacing: Spacing.m) {
            canvas
                .overlay(alignment: .top) {
                    Text(strokes.isEmpty ? "자동으로 영역을 찾았어요" : "영역을 다듬는 중")
                        .font(.footnote.bold())
                        .foregroundStyle(Color.app.surface)
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.app.ink, in: Capsule())
                        .padding(Spacing.s)
                }
            Text("손가락으로 문질러 테두리를 다듬을 수 있어요")
                .font(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
            HStack(spacing: Spacing.xs) {
                Chip(title: "자동 누끼", isSelected: false) {
                    strokes = []
                    draft.editedCutout = nil
                }
                Chip(title: "지우기", isSelected: isErasing) { isErasing = true }
                Chip(title: "복원", isSelected: !isErasing) { isErasing = false }
            }
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("브러시 크기")
                    .font(.headline)
                Slider(value: $brushSize, in: 10...80)
            }
            HStack(spacing: Spacing.s) {
                Button("다시 선택", action: onReselect)
                    .buttonStyle(.secondary)
                Button("다음", action: onNext)
                    .buttonStyle(.primary)
            }
        }
    }

    private var canvas: some View {
        GeometryReader { proxy in
            let imageSize = draft.photo?.size ?? CGSize(width: 1, height: 1)
            let scale = min(proxy.size.width / imageSize.width, proxy.size.height / imageSize.height)
            let origin = CGPoint(x: (proxy.size.width - imageSize.width * scale) / 2,
                                 y: (proxy.size.height - imageSize.height * scale) / 2)
            ZStack {
                Image(uiImage: draft.finalCutout ?? UIImage())
                    .resizable()
                    .scaledToFit()
                if let current {
                    Path { path in
                        path.addLines(current.points.map { CGPoint(x: origin.x + $0.x * scale, y: origin.y + $0.y * scale) })
                    }
                    .stroke(current.isErasing ? Color.app.danger.opacity(0.5) : Color.app.pastelMint.opacity(0.8),
                            style: StrokeStyle(lineWidth: current.width * scale, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let point = CGPoint(x: (value.location.x - origin.x) / scale, y: (value.location.y - origin.y) / scale)
                        if current == nil {
                            current = Stroke(points: [point], width: brushSize / scale, isErasing: isErasing)
                        }
                        current?.points.append(point)
                    }
                    .onEnded { _ in
                        if let current { strokes.append(current) }
                        current = nil
                        render()
                    }
            )
        }
        .padding(Spacing.s)
        .background(Color.app.pastelSky.opacity(0.4), in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    /// 자동 누끼 위에 지우기(투명하게)와 복원(원본 그리기)을 순서대로 덮어 그린다.
    private func render() {
        guard let photo = draft.photo, let cutout = draft.cutout else { return }
        let rect = CGRect(origin: .zero, size: photo.size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        draft.editedCutout = UIGraphicsImageRenderer(size: photo.size, format: format).image { context in
            cutout.draw(in: rect)
            for stroke in strokes {
                let path = CGMutablePath()
                path.addLines(between: stroke.points + [stroke.points[stroke.points.count - 1]])
                let area = path.copy(strokingWithWidth: stroke.width, lineCap: .round, lineJoin: .round, miterLimit: 1)
                context.cgContext.saveGState()
                context.cgContext.addPath(area)
                context.cgContext.clip()
                if stroke.isErasing {
                    context.cgContext.clear(rect)
                } else {
                    photo.draw(in: rect)
                }
                context.cgContext.restoreGState()
            }
        }
    }
}

#Preview("자동 누끼 완료") {
    let draft = DollDraft()
    draft.photo = UIImage(systemName: "cat.fill")
    draft.cutout = UIImage(systemName: "cat.fill")
    return NavigationStack {
        CutoutEditStep(draft: draft, onReselect: {}, onNext: {})
    }
}

#Preview("누끼 실패") {
    let draft = DollDraft()
    draft.photo = UIImage(systemName: "square.fill")
    return NavigationStack {
        CutoutEditStep(draft: draft, onReselect: {}, onNext: {})
    }
}

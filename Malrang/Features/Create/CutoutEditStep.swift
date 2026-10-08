import SwiftUI

/// 자동 투명화 결과를 보여주고, 손가락으로 문질러 지우거나 복원한다.
struct CutoutEditStep: View {
    let draft: DollDraft
    let onReselect: () -> Void
    let onNext: () -> Void
    @State private var phase = Phase.working
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tool = Tool.auto
    @State private var brushSize = 30.0
    @State private var strokes: [Stroke] = []
    @State private var current: Stroke?
    @State private var zoom = 1.0
    @State private var zoomBase = 1.0
    @State private var zoomAnchor = UnitPoint.center
    @State private var isZooming = false
    @State private var shine: CGFloat = -0.4
    @State private var canvasSize = CGSize.zero

    enum Phase {
        case working, failed, ready
    }

    enum Tool {
        case auto, erase, restore
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
        .navigationTitle("이미지 편집")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            draft.cropRect = nil
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
            HStack(spacing: Spacing.xs) {
                Button(action: undo) {
                    Image(systemName: "arrow.uturn.backward")
                        .frame(width: 44, height: 44)
                        .background(Color.app.surface, in: Circle())
                }
                .accessibilityLabel("되돌리기")
                .disabled(strokes.isEmpty)
                Button(action: clearAll) {
                    Image(systemName: "trash")
                        .frame(width: 44, height: 44)
                        .background(Color.app.surface, in: Circle())
                }
                .accessibilityLabel("모두 지우기")
                .disabled(strokes.isEmpty && zoom == 1)
                Spacer()
            }
            .font(.title3)
            .foregroundStyle(Color.app.ink)
            Text("손가락으로 문질러 테두리를 다듬을 수 있어요")
                .font(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
            HStack(spacing: Spacing.xs) {
                Chip(title: "자동 투명화", isSelected: tool == .auto) {
                    tool = .auto
                    strokes = []
                    draft.editedCutout = nil
                    Task { await playShine() }
                }
                Chip(title: "지우기", isSelected: tool == .erase) { tool = .erase }
                Chip(title: "복원", isSelected: tool == .restore) { tool = .restore }
            }
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("브러시 크기")
                    .font(.headline)
                Slider(value: $brushSize, in: 10...80)
            }
            .disabled(tool == .auto)
            .opacity(tool == .auto ? 0.4 : 1)
            HStack(spacing: Spacing.s) {
                Button("다시 선택", action: onReselect)
                    .buttonStyle(.secondary)
                Button("다음") {
                    commitZoom()
                    onNext()
                }
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
            let anchorPoint = CGPoint(x: zoomAnchor.x * proxy.size.width, y: zoomAnchor.y * proxy.size.height)
            ZStack {
                ZStack {
                    cutoutImage
                    if let current {
                        Path { path in
                            path.addLines(current.points.map { CGPoint(x: origin.x + $0.x * scale, y: origin.y + $0.y * scale) })
                        }
                        .stroke(current.isErasing ? Color.app.danger.opacity(0.5) : Color.app.pastelMint.opacity(0.8),
                                style: StrokeStyle(lineWidth: current.width * scale, lineCap: .round, lineJoin: .round))
                    }
                }
                .scaleEffect(zoom, anchor: zoomAnchor)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .contentShape(Rectangle())
            .gesture(tool == .auto ? nil : DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let view = CGPoint(x: anchorPoint.x + (value.location.x - anchorPoint.x) / zoom,
                                       y: anchorPoint.y + (value.location.y - anchorPoint.y) / zoom)
                    let point = CGPoint(x: (view.x - origin.x) / scale, y: (view.y - origin.y) / scale)
                    if current == nil {
                        current = Stroke(points: [point], width: brushSize / (scale * zoom), isErasing: tool == .erase)
                    }
                    current?.points.append(point)
                }
                .onEnded { _ in
                    if let current { strokes.append(current) }
                    current = nil
                    render()
                }
            )
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        if !isZooming {
                            isZooming = true
                            zoomBase = zoom
                            if zoom == 1 { zoomAnchor = value.startAnchor }
                        }
                        zoom = min(4, max(1, zoomBase * value.magnification))
                    }
                    .onEnded { _ in isZooming = false }
            )
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { canvasSize = $0 }
        .padding(Spacing.s)
        .background { Checkerboard() }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .accessibilityLabel("투명화한 사진. 두 손가락으로 확대하고 손가락으로 문질러 다듬어요")
    }

    /// 투명화가 끝났다는 걸 알리려고 반사판처럼 빛이 한 번 지나간다.
    private var cutoutImage: some View {
        let image = Image(uiImage: draft.editable ?? UIImage()).resizable().scaledToFit()
        return image
            .overlay {
                GeometryReader { proxy in
                    Rectangle()
                        .fill(.white)
                        .frame(width: proxy.size.width * 0.18)
                        .blur(radius: 14)
                        .rotationEffect(.degrees(20))
                        .offset(x: shine * proxy.size.width)
                        .frame(maxHeight: .infinity)
                        .blendMode(.plusLighter)
                }
                .mask(image)
                .allowsHitTesting(false)
            }
            .task { await playShine() }
    }

    private func playShine() async {
        guard !reduceMotion else { return }
        shine = -0.4
        try? await Task.sleep(for: .milliseconds(300))
        withAnimation(.smooth(duration: 1.1)) { shine = 1.2 }
    }

    private func undo() {
        strokes.removeLast()
        if strokes.isEmpty { draft.editedCutout = nil } else { render() }
    }

    private func clearAll() {
        strokes = []
        draft.editedCutout = nil
        withAnimation(.spring) { zoom = 1 }
    }

    /// 확대해서 보이는 부분만 인형에 넣는다. 확대하지 않았으면 전체를 쓴다.
    private func commitZoom() {
        guard zoom > 1, let photo = draft.photo, canvasSize.width > 0 else {
            draft.cropRect = nil
            return
        }
        let size = canvasSize
        let scale = min(size.width / photo.size.width, size.height / photo.size.height)
        let origin = CGPoint(x: (size.width - photo.size.width * scale) / 2, y: (size.height - photo.size.height * scale) / 2)
        let anchor = CGPoint(x: zoomAnchor.x * size.width, y: zoomAnchor.y * size.height)
        let visible = CGRect(x: ((anchor.x - anchor.x / zoom) - origin.x) / scale,
                             y: ((anchor.y - anchor.y / zoom) - origin.y) / scale,
                             width: size.width / zoom / scale, height: size.height / zoom / scale)
            .intersection(CGRect(origin: .zero, size: photo.size))
        draft.cropRect = visible.isNull || visible.isEmpty ? nil
            : CGRect(x: visible.minX / photo.size.width, y: visible.minY / photo.size.height,
                     width: visible.width / photo.size.width, height: visible.height / photo.size.height)
    }

    /// 자동 투명화 위에 지우기(투명하게)와 복원(원본 그리기)을 순서대로 덮어 그린다.
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

/// 투명한 부분이 보이도록 까는 체크무늬
private struct Checkerboard: View {
    private let cell: CGFloat = 12

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color.app.surface))
            for row in 0..<Int(size.height / cell) + 1 {
                for column in 0..<Int(size.width / cell) + 1 where (row + column).isMultiple(of: 2) {
                    let rect = CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell, width: cell, height: cell)
                    context.fill(Path(rect), with: .color(Color.app.ink.opacity(0.08)))
                }
            }
        }
    }
}

#Preview("자동 투명화 완료") {
    let draft = DollDraft()
    draft.photo = UIImage(systemName: "cat.fill")
    draft.cutout = UIImage(systemName: "cat.fill")
    return NavigationStack {
        CutoutEditStep(draft: draft, onReselect: {}, onNext: {})
    }
}

#Preview("투명화 실패") {
    let draft = DollDraft()
    draft.photo = UIImage(systemName: "square.fill")
    return NavigationStack {
        CutoutEditStep(draft: draft, onReselect: {}, onNext: {})
    }
}

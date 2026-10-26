import SwiftData
import SwiftUI

/// 인형 만들기 흐름에서 단계끼리 주고받는 값
@Observable
final class DollDraft {
    var photo: UIImage?
    /// 자동 투명화 결과
    var cutout: UIImage?
    /// 지우기·복원으로 다듬은 결과
    var editedCutout: UIImage?
    var shape = DollShape.cat
    var preset = PresetConfiguration()
    var usesPresetPhoto = false
    var snapshot: UIImage?
    var filling = Filling.fluffy
    /// 비워 두면 플레이스홀더인 "솜뭉치"가 이름이 된다.
    var name = ""
    var customScale: CGFloat = 1
    var customOffset = CGSize.zero
    var faceScale: CGFloat = 1
    var faceOffsetX: Float = 0
    var faceOffsetY: Float = 0
    /// 확대해서 보여준 부분(사진 크기를 1로 본 비율). 인형에는 이 부분만 크게 들어간다.
    var cropRect: CGRect?

    /// 편집 화면에서 다듬는 이미지
    var editable: UIImage? { editedCutout ?? cutout }

    var finalCutout: UIImage? {
        guard let image = editable else { return nil }
        guard let cropRect, let cgImage = image.cgImage else { return image }
        let width = CGFloat(cgImage.width), height = CGFloat(cgImage.height)
        let rect = CGRect(x: cropRect.minX * width, y: cropRect.minY * height,
                          width: cropRect.width * width, height: cropRect.height * height).integral
        return cgImage.cropping(to: rect).map { UIImage(cgImage: $0) } ?? image
    }
    @ObservationIgnored private var cachedPhoto: UIImage?
    @ObservationIgnored private var cachedCrop: CGRect?
    @ObservationIgnored private var cachedPhotoData: Data?

    var presetPhotoData: Data? {
        let source = editable ?? photo
        guard let source else { return nil }
        if cachedPhoto !== source || cachedCrop != cropRect {
            cachedPhoto = source
            cachedCrop = cropRect
            cachedPhotoData = (finalCutout ?? source).pngData()
        }
        return cachedPhotoData
    }

    var displayName: String { name.isEmpty ? "솜뭉치" : name }
}

enum CreateStep: Hashable {
    case method, cutout, ready, customize, making
    case done(Doll)
}

/// 갤러리 → 이미지 투명화 → 만들기 방식 → 꾸미기 → 완성
struct CreateFlowView: View {
    let onPlace: (Doll) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft = DollDraft()
    @State private var path: [CreateStep] = []

    init(onPlace: @escaping (Doll) -> Void) { self.onPlace = onPlace }

#if DEBUG
    init(previewDraft: DollDraft, startAtMaking: Bool = false, onPlace: @escaping (Doll) -> Void) {
        self.onPlace = onPlace
        _draft = State(initialValue: previewDraft)
        _path = State(initialValue: [startAtMaking ? .making : .method])
    }
#endif

    var body: some View {
        NavigationStack(path: $path) {
            PhotoPickStep(draft: draft) { path.append(.cutout) }
                .safeAreaInset(edge: .top, spacing: 0) { CreationProgress(step: 0) }
                .toolbar {
                    Button("닫기", systemImage: "xmark") { dismiss() }
                }
                .navigationDestination(for: CreateStep.self) { step in
                    destination(step)
                        .background { AppBackground() }
                        .safeAreaInset(edge: .top, spacing: 0) {
                            if step == .cutout || step == .ready || step == .method {
                                CreationProgress(step: step == .method ? 2 : 1)
                            }
                        }
                }
        }
    }

    @ViewBuilder
    private func destination(_ step: CreateStep) -> some View {
        switch step {
        case .method:
            CreateMethodStep(draft: draft, onPreset: {
                if draft.shape == .pillow { draft.shape = .cat }
                draft.usesPresetPhoto = true
                draft.snapshot = nil
                path.append(.customize)
            }, onCutout: {
                draft.shape = .pillow
                draft.usesPresetPhoto = false
                draft.snapshot = nil
                path.append(.customize)
            })
        case .cutout:
            CutoutEditStep(draft: draft, onReselect: { path = [] }, onNext: { path.append(.ready) })
        case .ready:
            CutoutReadyStep(draft: draft, onEdit: { path.removeLast() }, onNext: { path.append(.method) })
        case .customize:
            DollCustomizeStep(draft: draft) { path.append(.making) }
        case .making:
            MakingStep(draft: draft, onLeave: { path.removeLast() }) { doll in
                path = [.done(doll)]
            }
        case .done(let doll):
            DoneStep(doll: doll, onRestart: restart) {
                onPlace(doll)
                dismiss()
            }
        }
    }

    private func restart() {
        draft = DollDraft()
        path = []
    }
}

#Preview {
    CreateFlowView { _ in }
        .modelContainer(.preview)
}

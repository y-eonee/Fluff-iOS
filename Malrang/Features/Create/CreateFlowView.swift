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
    var shape = DollShape.pillow
    var preset = PresetConfiguration()
    var usesPresetPhoto = false
    var snapshot: UIImage?
    var filling = Filling.fluffy
    /// 이름 짓기 단계에서 공백이 아닌 이름을 입력한 뒤 완성한다.
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
    @ObservationIgnored private weak var cachedPhoto: UIImage?
    @ObservationIgnored private var cachedCrop: CGRect?
    @ObservationIgnored private var cachedPhotoData: Data?

    func clearPhotoCache() {
        cachedPhoto = nil; cachedCrop = nil; cachedPhotoData = nil
    }

    func releaseImages() {
        photo = nil; cutout = nil; editedCutout = nil; snapshot = nil; preset.face = nil
        clearPhotoCache()
    }

    var presetPhotoData: Data? {
        let source = editable ?? photo
        guard let source else { return nil }
        if cachedPhoto !== source || cachedCrop != cropRect {
            cachedPhoto = source
            cachedCrop = cropRect
            cachedPhotoData = CutoutService.normalized(finalCutout ?? source, maxSide: 1024).pngData()
        }
        return cachedPhotoData
    }

    var displayName: String { name.isEmpty ? "인형" : name }
}

enum CreateStep: Hashable {
    case method, cutout, ready, customize, making
    case done(Doll)
}

/// 갤러리 → 이미지 투명화 → 만들기 방식 → 꾸미기 → 완성
struct CreateFlowView: View {
    let onPlace: (Doll) -> Void
    var onExit: () -> Void = {}
    @Environment(\.returnToDollList) private var returnToDollList
    @State private var confirmingExit = false
    @Environment(\.dismiss) private var dismiss
    @State private var draft = DollDraft()
    @State private var path: [CreateStep] = []

    init(onExit: @escaping () -> Void = {}, onPlace: @escaping (Doll) -> Void) { self.onExit = onExit; self.onPlace = onPlace }

#if DEBUG
    init(previewDraft: DollDraft, startAtMaking: Bool = false, onPlace: @escaping (Doll) -> Void) {
        self.onPlace = onPlace
        _draft = State(initialValue: previewDraft)
        _path = State(initialValue: [startAtMaking ? .making : .method])
        _confirmingExit = State(initialValue: ProcessInfo.processInfo.arguments.contains("--creation-exit-preview"))
    }
#endif

    var body: some View {
        NavigationStack(path: $path) {
            PhotoPickStep(draft: draft) { path.append(.cutout) }
                .safeAreaInset(edge: .top, spacing: 0) { CreationProgress(step: 0) }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { exitButton }
                }
                .navigationDestination(for: CreateStep.self) { step in
                    destination(step)
                        .background { AppBackground() }
                        .navigationBarBackButtonHidden()
                        .toolbar {
                            if !isDone(step) { ToolbarItem(placement: .topBarLeading) { exitButton } }
                        }
                        .safeAreaInset(edge: .top, spacing: 0) {
                            if step == .cutout || step == .ready || step == .method {
                                CreationProgress(step: step == .method ? 2 : 1)
                            }
                        }
                }
        }
        .interactiveDismissDisabled()
        .accessibilityHidden(confirmingExit)
        .overlay { if confirmingExit { exitDialog } }
    }

    private func isDone(_ step: CreateStep) -> Bool {
        if case .done = step { return true }; return false
    }

    private var exitButton: some View {
        Button { confirmingExit = true } label: { D1Icon(name: "back").frame(width: 44, height: 44) }
            .accessibilityLabel("인형 만들기 나가기")
    }

    private var exitDialog: some View {
        ZStack {
            Color.mib.text.primary.opacity(0.28).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 19) {
                Text("인형 만들기를 그만할까요?").pretendard(.bold, 20).foregroundStyle(Color.mib.text.primary)
                Text("지금까지 만든 내용은 저장되지 않아요.").pretendard(.regular, 14).foregroundStyle(Color.mib.text.secondary)
                Spacer(minLength: 24)
                HStack(spacing: 12) {
                    Button("머무르기") { confirmingExit = false }.buttonStyle(FocusCompactButton())
                    Button("나가기") {
                        draft.releaseImages(); confirmingExit = false
                        returnToDollList(); dismiss(); onExit()
                    }.buttonStyle(FocusCompactButton(primary: true))
                }.frame(height: 52)
            }.padding(.horizontal, 24).padding(.vertical, 30).frame(height: 248)
                .background(Color.mib.bg.surface, in: RoundedRectangle(cornerRadius: 28))
                .padding(.horizontal, 24).accessibilityAddTraits(.isModal)
        }.accessibilityAction(.escape) { confirmingExit = false }
    }

    @ViewBuilder
    private func destination(_ step: CreateStep) -> some View {
        switch step {
        case .method:
            CreateMethodStep(draft: draft, onPrevious: { path.removeLast() }, onPreset: {
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
            DollCustomizeStep(draft: draft, onPrevious: { path.removeLast() }) { path.append(.making) }
        case .making:
            MakingStep(draft: draft, onLeave: { confirmingExit = true }) { doll in
                path = [.done(doll)]
                draft.releaseImages()
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

private struct ReturnToDollListKey: EnvironmentKey {
    static var defaultValue: () -> Void { {} }
}
extension EnvironmentValues {
    var returnToDollList: () -> Void {
        get { self[ReturnToDollListKey.self] }
        set { self[ReturnToDollListKey.self] = newValue }
    }
}

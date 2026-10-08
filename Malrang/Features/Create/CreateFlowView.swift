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
    var shape = DollShape.bear
    var filling = Filling.fluffy
    /// 비워 두면 플레이스홀더인 "귀염둥이"가 이름이 된다.
    var name = ""
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
    var displayName: String { name.isEmpty ? "귀염둥이" : name }
}

enum CreateStep: Hashable {
    case cutout, ready, customize, making, done
}

/// 사진 선택 → 이미지 편집 → 확인 → 모양·속재료 → 꿰매기 → 완성
struct CreateFlowView: View {
    let onPlace: (Doll) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft = DollDraft()
    @State private var path: [CreateStep] = []
    @State private var createdDoll: Doll?

    var body: some View {
        NavigationStack(path: $path) {
            PhotoPickStep(draft: draft) { path.append(.cutout) }
                .toolbar {
                    Button("닫기", systemImage: "xmark") { dismiss() }
                }
                .navigationDestination(for: CreateStep.self) { step in
                    destination(step)
                        .background(Color.app.background)
                }
        }
    }

    @ViewBuilder
    private func destination(_ step: CreateStep) -> some View {
        switch step {
        case .cutout:
            CutoutEditStep(draft: draft, onReselect: { path.removeLast() }, onNext: { path.append(.ready) })
        case .ready:
            CutoutReadyStep(draft: draft, onEdit: { path.removeLast() }, onNext: { path.append(.customize) })
        case .customize:
            DollCustomizeStep(draft: draft) { path.append(.making) }
        case .making:
            MakingStep(draft: draft, onLeave: { path.removeLast() }) { doll in
                createdDoll = doll
                path = [.done]
            }
        case .done:
            if let createdDoll {
                DoneStep(doll: createdDoll, onRestart: restart) {
                    onPlace(createdDoll)
                    dismiss()
                }
            }
        }
    }

    private func restart() {
        draft = DollDraft()
        createdDoll = nil
        path = []
    }
}

#Preview {
    CreateFlowView { _ in }
        .modelContainer(.preview)
}

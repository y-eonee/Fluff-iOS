import SwiftData
import SwiftUI

/// 인형을 꿰매는 동안 보여주는 화면. 나가려 하면 확인을 받는다.
/// 프리셋은 최종 설정으로 렌더링한 뒤 저장한다.
struct MakingStep: View {
    let draft: DollDraft
    let onLeave: () -> Void
    let onDone: (Doll) -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var progress = 0.0
    @State private var isAskingToLeave = false
    @State private var saveFailed = false
    @State private var saved = false
    @State private var finalSnapshot: UIImage?

    @ViewBuilder private var artwork: some View {
        if draft.shape != .pillow {
            PresetDollView(configuration: draft.preset, cameraDistance: 0.90, cameraTarget: 0.19,
                           onSnapshot: { image in
                               guard finalSnapshot == nil else { return }
                               finalSnapshot = image
                               Task { await make() }
                           }).renderedOnlyWhileVisible(background: .clear)
        } else { CustomPhotoPreview(draft: draft) }
    }

    var body: some View {
        VStack(spacing: Spacing.l) {
            artwork
                .frame(maxHeight: 300)
                .padding(Spacing.l)
                .frame(maxWidth: .infinity)
                .cardStyle()
            ProgressView(value: progress)
                .tint(Color.app.accent)
            Text("\(draft.displayName) 꿰매는 중...")
                .appFont(.body)
                .foregroundStyle(Color.app.inkSecondary)
        }
        .padding(Spacing.m)
        .frame(maxHeight: .infinity)
        .navigationTitle("인형 만드는 중")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("뒤로", systemImage: "chevron.left") { isAskingToLeave = true }
            }
        }
        .overlay {
            if isAskingToLeave { leaveConfirmation }
        }
        .task { if draft.shape == .pillow { await make() } }
        .alert("인형을 저장하지 못했어요", isPresented: $saveFailed) {
            Button("다시 저장") { Task { await make() } }
            Button("돌아가기", role: .cancel, action: onLeave)
        }
    }

    private var leaveConfirmation: some View {
        ZStack {
            Color.app.ink.opacity(0.3).ignoresSafeArea()
            VStack(spacing: Spacing.m) {
                Group {
                    if let image = finalSnapshot ?? draft.snapshot { Image(uiImage: image).resizable().scaledToFit() }
                    else { Image(systemName: "teddybear").font(.largeTitle) }
                }
                    .frame(height: 100)
                    .saturation(0)
                    .opacity(0.6)
                Text("지금 나가면 \(draft.displayName.josa("은", "는"))\n완성되지 않아요!")
                    .appFont(.headline)
                    .multilineTextAlignment(.center)
                HStack(spacing: Spacing.s) {
                    Button("나가기", action: onLeave)
                        .buttonStyle(.secondary)
                    Button("계속 만들기") { isAskingToLeave = false }
                        .buttonStyle(.primary)
                }
            }
            .foregroundStyle(Color.app.ink)
            .padding(Spacing.l)
            .cardStyle()
            .padding(Spacing.l)
        }
    }

    private func make() async {
        guard !saved else { return }
        let data: Data?
        if draft.shape != .pillow {
            guard let finalSnapshot else { return }
            data = finalSnapshot.pngData()
        } else {
            let renderer = ImageRenderer(content: CustomPhotoPreview(draft: draft).frame(width: 400, height: 500))
            renderer.scale = 2
            data = renderer.uiImage?.pngData()
        }
        guard let data else { saveFailed = true; return }
        guard !Task.isCancelled else { return }
        progress = 0.8
        let doll = Doll(name: draft.displayName, shape: draft.shape, filling: draft.filling, imageData: data)
        if draft.shape != .pillow { doll.presetConfiguration = draft.preset }
        modelContext.insert(doll)
        do { try modelContext.save(); progress = 1; saved = true; onDone(doll) }
        catch { modelContext.delete(doll); saveFailed = true }
    }
}

#Preview {
    let draft = DollDraft()
    draft.cutout = UIImage(systemName: "cat.fill")
    return NavigationStack {
        MakingStep(draft: draft, onLeave: {}, onDone: { _ in })
    }
    .modelContainer(.preview)
}

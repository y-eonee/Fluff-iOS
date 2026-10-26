import SwiftData
import SwiftUI

/// 인형을 꿰매는 동안 보여주는 화면. 나가려 하면 확인을 받는다.
/// 지금은 합성 이미지만 만들고, 3D 인형 메시 생성이 붙으면 그 진행률을 보여준다.
struct MakingStep: View {
    let draft: DollDraft
    let onLeave: () -> Void
    let onDone: (Doll) -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var progress = 0.0
    @State private var isAskingToLeave = false
    @State private var saveFailed = false
    @State private var saved = false

    @ViewBuilder private var artwork: some View {
        if draft.shape != .pillow {
            if let image = draft.snapshot { Image(uiImage: image).resizable().scaledToFit() }
            else { CottonArtwork(shape: draft.shape) }
        } else { DollArtwork(shape: draft.shape, cutout: Image(uiImage: draft.finalCutout ?? UIImage()), faceScale: draft.faceScale) }
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
        .task { await make() }
        .alert("인형을 저장하지 못했어요", isPresented: $saveFailed) {
            Button("다시 저장") { Task { await make() } }
            Button("돌아가기", role: .cancel, action: onLeave)
        }
    }

    private var leaveConfirmation: some View {
        ZStack {
            Color.app.ink.opacity(0.3).ignoresSafeArea()
            VStack(spacing: Spacing.m) {
                artwork
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
        let renderer = ImageRenderer(content: artwork.frame(width: 400, height: 500))
        renderer.scale = 2
        guard let data = renderer.uiImage?.pngData() else { saveFailed = true; return }
        while progress < 1 {
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }
            if !isAskingToLeave { progress = min(1, progress + 0.025) }
        }
        let doll = Doll(name: draft.displayName, shape: draft.shape, filling: draft.filling, imageData: data)
        if draft.shape != .pillow { doll.presetConfiguration = draft.preset }
        modelContext.insert(doll)
        do { try modelContext.save(); saved = true; onDone(doll) }
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

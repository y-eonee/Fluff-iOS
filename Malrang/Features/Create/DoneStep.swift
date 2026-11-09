import SwiftUI

struct DoneStep: View {
    let doll: Doll
    let onRestart: () -> Void
    let onPlace: () -> Void
    @State private var isDone = false

    var body: some View {
        VStack(spacing: Spacing.l) {
            Text("\(doll.name.josa("이", "가")) 태어났어요!")
                .pretendard(.bold, 20)
                .multilineTextAlignment(.center)
            Group {
                if let configuration = doll.presetConfiguration {
                    PresetDollView(configuration: configuration, cameraDistance: 0.90, cameraTarget: 0.19, fitsModel: true)
                        .renderedOnlyWhileVisible(background: .clear)
                } else {
                    Image(uiImage: doll.image).resizable().scaledToFit()
                }
            }.frame(maxHeight: .infinity).accessibilityLabel(doll.name)
            HStack(spacing: Spacing.s) {
                Button("다시 만들기", action: onRestart)
                    .buttonStyle(CreationSecondaryButton())
                Button("방에 배치하기", action: onPlace)
                    .buttonStyle(CreationPrimaryButton())
            }
        }
        .foregroundStyle(Color.app.ink)
        .padding(Spacing.m)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .background { Celebration() }
        .sensoryFeedback(.success, trigger: isDone)
        .onAppear { isDone = true }
    }
}

#Preview {
    NavigationStack {
        DoneStep(doll: .sample, onRestart: {}, onPlace: {})
    }
}

import SwiftUI

struct DoneStep: View {
    let doll: Doll
    let onRestart: () -> Void
    let onPlace: () -> Void
    @State private var isDone = false

    var body: some View {
        VStack(spacing: Spacing.l) {
            Text("\(doll.name.josa("이", "가")) 태어났어요!")
                .pretendard(.bold, 17, tracking: -0.85)
                .multilineTextAlignment(.center)
            Group {
                if let configuration = doll.presetConfiguration {
                    PresetDollView(configuration: configuration, cameraDistance: 0.90, cameraTarget: 0.19, fitsModel: true, fitMargin: 1.10)
                        .renderedOnlyWhileVisible(background: .clear)
                        .offset(y: -4)
                } else {
                    Image(uiImage: doll.image).resizable().scaledToFit()
                }
            }.frame(maxHeight: .infinity).accessibilityLabel(doll.name)
                .background {
                    Image("rep4_making_glow").resizable().scaledToFit()
                        .frame(height: 300).blur(radius: 21.674)
                }
            HStack(spacing: Spacing.s) {
                Button("다시 만들기", action: onRestart)
                    .buttonStyle(CreationSecondaryButton())
                Button("방에 배치하기", action: onPlace)
                    .buttonStyle(CreationPrimaryButton())
            }
        }
        .foregroundStyle(Color.app.ink)
        .padding(.horizontal, 18).padding(.top, 23).padding(.bottom, 16)
        .cozyPageTitle("making fluff")
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CreationBackButton(label: "다시 만들기", action: onRestart)
            }.sharedBackgroundVisibility(.hidden)
        }
        .background { AppBackground() }
        .sensoryFeedback(.success, trigger: isDone)
        .onAppear { isDone = true }
    }
}

#Preview {
    NavigationStack {
        DoneStep(doll: .sample, onRestart: {}, onPlace: {})
    }
}

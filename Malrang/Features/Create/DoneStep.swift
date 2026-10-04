import SwiftUI

struct DoneStep: View {
    let doll: Doll
    let onRestart: () -> Void
    let onPlace: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false

    var body: some View {
        VStack(spacing: Spacing.l) {
            Text("\(doll.name.josa("이", "가")) 태어났어요!")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Image(uiImage: doll.image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: .infinity)
                .overlay(alignment: .topLeading) { balloon(Color.app.accent) }
                .overlay(alignment: .topTrailing) { balloon(Color.app.pastelSky) }
                .accessibilityLabel(doll.name)
            HStack(spacing: Spacing.s) {
                Button("다시 만들기", action: onRestart)
                    .buttonStyle(.secondary)
                Button("방에 배치하기", action: onPlace)
                    .buttonStyle(.primary)
            }
        }
        .foregroundStyle(Color.app.ink)
        .padding(Spacing.m)
        .navigationTitle("완성!")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .sensoryFeedback(.success, trigger: isFloating)
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever()) { isFloating = true }
        }
    }

    private func balloon(_ color: Color) -> some View {
        Image(systemName: "balloon.fill")
            .font(.system(.largeTitle))
            .imageScale(.large)
            .foregroundStyle(color)
            .offset(y: isFloating ? -12 : 0)
            .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        DoneStep(doll: .sample, onRestart: {}, onPlace: {})
    }
}

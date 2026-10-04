import SwiftUI

/// 인형을 탭하면 아래에서 올라오는 화면: 만지기, 춤추기, AR, 공유
struct DollActionSheet: View {
    let doll: Doll
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingAR = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.l) {
                Image(uiImage: doll.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
                    .accessibilityLabel(doll.name)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.s), GridItem(.flexible())], spacing: Spacing.s) {
                    NavigationLink {
                        SquishyView(doll: doll.state)
                    } label: {
                        tile("만지기", symbol: "hand.point.up.left")
                    }
                    NavigationLink {
                        DanceView(doll: doll)
                    } label: {
                        tile("춤추기", symbol: "music.note")
                    }
                    Button {
                        isShowingAR = true
                    } label: {
                        tile("AR로 함께하기", symbol: "camera.viewfinder")
                    }
                    ShareLink(item: Image(uiImage: doll.image), preview: SharePreview(doll.name, image: Image(uiImage: doll.image))) {
                        tile("공유", symbol: "square.and.arrow.up")
                    }
                }
                .buttonStyle(.plain)
                if !doll.isPlaced {
                    Button("방에 두기") {
                        appState.place(doll)
                        dismiss()
                    }
                    .buttonStyle(.primary)
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.m)
            .background(Color.app.background)
            .navigationTitle(doll.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("닫기", systemImage: "xmark") { dismiss() }
            }
            .fullScreenCover(isPresented: $isShowingAR) {
                ARCaptureView(dollImage: doll.image)
            }
        }
    }

    private func tile(_ title: String, symbol: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: symbol)
                .font(.title2)
            Text(title)
                .font(.headline)
        }
        .foregroundStyle(Color.app.ink)
        .frame(maxWidth: .infinity, minHeight: 96)
        .cardStyle()
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        DollActionSheet(doll: .sample)
            .environment(AppState())
    }
}
